# Helm chart for Aerospike (CE) on Kubernetes

Implements a dynamically scalable Aerospike cluster using Kubernetes StatefulSets.


## Pre Requisites

- Kubernetes 1.8+

## Usage:

### Add Aerospike repository

```sh
helm repo add aerospike https://aerospike.github.io/aerospike-kubernetes
```

### Install the chart

```sh
helm install aerospike-release aerospike/aerospike
```

User can set any configuration values defined in `values.yaml` using `--set` option or provide a `values.yaml` file using `-f` option with `helm install`.

For example,

```sh
helm install aerospike-release aerospike/aerospike --set dbReplicas=5
```

#### For Helm v2,

```sh
helm install --name aerospike-release aerospike/aerospike --set dbReplicas=5
```

### Use a custom aerospike.conf file or template

- To override the default `aerospike.template.conf`, set `confFilePath` to point to the custom `aerospike.conf` file or template.

	> `confFilePath` should be a file path on helm "client" machine (where the user is running the command `helm install`).

- The custom `aerospike.conf` file or template must contain `# mesh-seed-placeholder` in `heartbeat` configuration to populate mesh configuration during peer discovery. For example,

	```sh
	....
		heartbeat {

			address any
			mode mesh
			port 3002

			# mesh-seed-placeholder

			interval 150
			timeout 10
		}
	.....
	```

- Use `confFilePath` on `helm install` with `--set-file` option.
	```sh
	helm install aerospike-release aerospike/aerospike --set-file confFilePath=/tmp/aerospike_templates/aerospike.template.conf
	```

### Storage configuration

User can configure multiple volume mounts (filesystem type) or device mounts (raw block device) or both in `values.yaml`. Check below [configuration section](#configuration) and [`values.yaml`](values.yaml) file in [this repository](https://github.com/aerospike/aerospike-kubernetes/tree/master/helm) for more details.


### Test Output:

```sh
NAME:   aerospike-release
LAST DEPLOYED: Fri Mar  6 15:50:33 2020
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                                            DATA   AGE
aerospike-release-conf                          2      51m

==> v1/Pod(related)
NAME                                           READY   STATUS    RESTARTS   AGE
pod/aerospike-release-aerospike-0              1/1     Running   0          49m
pod/aerospike-release-aerospike-1              1/1     Running   0          49m
pod/aerospike-release-aerospike-2              1/1     Running   0          48m

==> v1/Service
NAME                                             TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/aerospike-release-aerospike              ClusterIP   None         <none>        3000/TCP   49m

==> v1/StatefulSet
NAME                                                      READY   AGE
statefulset.apps/aerospike-release-aerospike              3/3     49m
```

```sh
$ helm list
NAME             	REVISION	UPDATED                 	STATUS  	CHART                     	APP VERSION	NAMESPACE
aerospike-release	1       	Fri Mar  6 15:50:33 2020	DEPLOYED	aerospike-4.8.0             4.8.0.5   	default
```

### Expose Aerospike Cluster

Aerospike Cluster can be exposed to client applications or to XDR clients outside the K8s network by enabling,
- Host Networking
- NodePort Services Per Pod
- LoadBalancer Services Per Pod
- ClusterIP Services with External IPs

### **Host Networking**

With host networking enabled, pods will be able to access the node's network. Pod IP will be same as node IP.

> With host networking enabled, the deployment will be limited to one pod per node. If the new pod is scheduled onto the same node, it will fail due to no free ports.

Use `platform` and `hostNetworking` options to expose the Aerospike cluster pods to external client applications. Setting `platform` will fetch external IP of the instances (if any) and add it to [`alternate-access-address`](https://www.aerospike.com/docs/reference/configuration/index.html#alternate-access-address) in `aerospike.conf`.

For example,

```sh
helm install aerospike-release aerospike/aerospike \
	 --set dbReplicas=4 \
	 --set hostNetworking=true \
	 --set platform=gke
```

For Helm v2,

```sh
helm install --name aerospike-release aerospike/aerospike \
	 --set dbReplicas=4 \
	 --set hostNetworking=true \
	 --set platform=gke
```

Client applications can connect to the Aerospike cluster using instance's external IP (if available) or else by simply using host IP.

```sh
asadm -h <ExternalIP> -p 3000 --services-alternate
```

### **NodePort Services Per Pod**

NodePort type exposes the Service on each K8s Node’s IP at a static port (the `NodePort`). Applications will be able to connect to the NodePort Service from outside the K8s cluster by using `<NodeIP>:<NodePort>`.

> With NodePort type services, it allows multiple pods per K8s host as well as expose each aerospike pod.

To enable `NodePort` services per pod, `enableNodePortServices` option must be set to `true`.
Aerospike helm chart will automatically create a `NodePort` type service for each aerospike pod at the time of deployment. Applications can connect to the Aerospike cluster using any one of `<NodeIP>:<NodePort>` as seed IP and Port.

Setting `platform` will fetch external IP of the instances (if any) and add it to [`alternate-access-address`](https://www.aerospike.com/docs/reference/configuration/index.html#alternate-access-address) in `aerospike.conf`.

> It is recommended to use `helm upgrade` command to perform scale-up/scale-down when NodePort services are enabled.

User must specify a service account with appropriate permissions to query the API server and read the `Service` type resources. An existing service account can be specified using `rbac.serviceAccountName`. User can also set `rbac.create` to `true` for which Aerospike helm chart will automatically create a new serviceAccount with appropriate permissions and use it for the statefulset deployment.

Example,

```sh
helm install aerospike-release aerospike/aerospike \
		 	 --set dbReplicas=5 \
			 --set rbac.create=true \
			 --set enableNodePortServices=true
```

For Helm v2,

```sh
helm install --name aerospike-release aerospike/aerospike \
			 --set dbReplicas=5 \
			 --set rbac.create=true \
			 --set enableNodePortServices=true
```

### **LoadBalancer Services Per Pod**

LoadBalancer type exposes the service externally using the cloud provider’s load balancer. A new external network load balancer is provisioned.

> With LoadBalancer type services, it allows multiple pods per K8s host as well as expose each pod.

To enable `LoadBalancer` services per pod, `enableLoadBalancerServices` option must be set to `true`.
Aerospike helm chart will automatically create a `LoadBalancer` type service for each aerospike pod at the time of deployment.

Applications can connect to the Aerospike cluster using `<LoadBalancerIngressIP>:<LoadBalancerPort>`.

```sh
asadm -h <LoadBalancerIngressIP> -p <LoadBalancerPort> --services-alternate
```

> It is recommended to use `helm upgrade` command to perform scale-up/scale-down when LoadBalancer type services are enabled.

User must specify a service account with appropriate permissions to query the API server and read the `Service` type resources. An existing service account can be specified using `rbac.serviceAccountName`. User can also set `rbac.create` to `true` for which Aerospike helm chart will automatically create a new serviceAccount with appropriate permissions and use it for the statefulset deployment.

Example,

```sh
helm install aerospike-release aerospike/aerospike \
		 	 --set dbReplicas=5 \
			 --set rbac.create=true \
			 --set enableLoadBalancerServices=true
```

For Helm v2,

```sh
helm install --name aerospike-release aerospike/aerospike \
			 --set dbReplicas=5 \
			 --set rbac.create=true \
			 --set enableLoadBalancerServices=true
```

### **ClusterIP Services with External IPs**

`ClusterIP` type exposes the service on a cluster-internal IP. With external IPs set, the service can be accessed from its external endpoint.

With `enableExternalIpServices` option enabled, Aerospike helm chart will create a `ClusterIP` type service for each aerospike pod at the time of deployment. User can specify only one external IP and Port.
The external endpoints can be specified using `externalIpEndpoints` option. Check [`values.yaml`](values.yaml).

> It is recommended to use `helm upgrade` command to perform scale-up/scale-down when ClusterIP-ExternalIP services are enabled.

> With `enableExternalIpService` enabled, user must specify number of endpoints equal to the number of Aerospike nodes/pods (`dbReplicas`).

User must specify a service account with appropriate permissions to query the API server and read the `Service` type resources. An existing service account can be specified using `rbac.serviceAccountName`. User can also set `rbac.create` to `true` for which Aerospike helm chart will automatically create a new serviceAccount with appropriate permissions and use it for the statefulset deployment.

Example,

```sh
helm install aerospike-release aerospike/aerospike \
		 	 --set dbReplicas=4 \
			 --set rbac.create=true \
			 --set enableExternalIpServices=true \
			 --set externalIpEndpoints[0].IP=10.160.15.224 \
			 --set externalIpEndpoints[0].Port=7001 \
			 --set externalIpEndpoints[1].IP=10.160.15.224 \
			 --set externalIpEndpoints[1].Port=7002 \
			 --set externalIpEndpoints[2].IP=10.160.15.223 \
			 --set externalIpEndpoints[2].Port=8001
			 --set externalIpEndpoints[3].IP=10.160.15.223 \
			 --set externalIpEndpoints[3].Port=8002
```

For Helm v2,

```sh
helm install --name aerospike-release aerospike/aerospike \
		 	 --set dbReplicas=4 \
			 --set rbac.create=true \
			 --set enableExternalIpServices=true \
			 --set externalIpEndpoints[0].IP=10.160.15.224 \
			 --set externalIpEndpoints[0].Port=7001 \
			 --set externalIpEndpoints[1].IP=10.160.15.224 \
			 --set externalIpEndpoints[1].Port=7002 \
			 --set externalIpEndpoints[2].IP=10.160.15.223 \
			 --set externalIpEndpoints[2].Port=8001
			 --set externalIpEndpoints[3].IP=10.160.15.223 \
			 --set externalIpEndpoints[3].Port=8002
```

### Aerospike Monitoring Stack

Aerospike Helm Chart provides Aerospike Monitoring Stack which includes an Aerospike prometheus exporter (sidecar), Prometheus statefulset, Grafana statefulset and Alertmanager statefulset.

User can enable Aerospike Monitoring by setting `enableAerospikeMonitoring` option to `true`.

To add a custom Aerospike alert rules configuraton file, use option `--set-file prometheus.aerospikeAlertRulesFilePath`.

> `prometheus.aerospikeAlertRulesFilePath` should be a file path on helm "client" machine (where the user is running 'helm install')

To add an alertmanager configuration file, use option `--set-file alertmanager.alertmanagerConfFilePath`.

> `alertmanager.alertmanagerConfFilePath` should be a file path on helm "client" machine (where the user is running 'helm install')

Check below [configuration section](#configuration) and [`values.yaml`](values.yaml) file in [this repository](https://github.com/aerospike/aerospike-kubernetes/tree/master/helm) for more details on other configuration of the `Aerospike Prometheus Exporter`, `Prometheus`, `Grafana` and `Alertmanager`.


### Configuration

| Parameter                                             | Description                                                                                                                                                                               | Default Value                                                                                                        |
| ------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------------------------------------:|
| `dbReplicas`                                          | Number of Aerospike nodes or pods in the cluster                                                                                                                                          | `3`                                                                                                                  |
| `terminationGracePeriodSeconds`                       | Number of seconds to wait after `SIGTERM` before force killing the pod.                                                                                                                   | `120`                                                                                                                |
| `image.repository`                                    | Aerospike Server Docker Image                                                                                                                                                             | `aerospike/aerospike-server`                                                                              |
| `image.tag`                                           | Aerospike Server Docker Image Tag                                                                                                                                                         | `4.8.0.5`                                                                                                           |
| `initImage.repository`                                | Aerospike Kubernetes Init Container Image                                                                                                                                                 | `aerospike/aerospike-kubernetes-init`                                                                                |
| `initImage.tag`                                       | Aerospike Kubernetes Init Container Image Tag                                                                                                                                             | `1.0.0`                                                                                                              |
| `autoGenerateNodeIds`                                 | Auto generate and assign node-id(s) based on Pod's Ordinal Index                                                                                                                          | `false`                                                                                                              |
| `aerospikeNamespace`                                  | Aerospike Namespace name                                                                                                                                                                  | `test`                                                                                                               |
| `aerospikeNamespaceMemoryGB`                          | Aerospike Namespace Memory in GB                                                                                                                                                          | `1`                                                                                                                  |
| `aerospikeReplicationFactor`                          | Aerospike Namespace Replication Factor                                                                                                                                                    | `2`                                                                                                                  |
| `aerospikeDefaultTTL`                                 | Aerospike Namespace Record default TTL                                                                                                                                                    | `0` (Never Expire)                                                                                                   |
| `aerospikeClientPort`                                 | Aerospike TCP Service Port                                                                                                                                                                | `3000`                                                                                                               |
| `aerospikeHeartbeatPort`                              | Aerospike TCP Hearbeat Port                                                                                                                                                               | `3002`                                                                                                               |
| `aerospikeFabricPort`                                 | Aerospike TCP Fabric Port                                                                                                                                                                 | `3001`                                                                                                               |
| `aerospikeInfoPort`                                   | Aerospike TCP Info Port                                                                                                                                                                   | `3003`                                                                                                               |
| `autoRolloutConfig`		   	                        | Rollout ConfigMap/Secrets changes on 'helm upgrade'    			                                                                                                                        | `false`					   	                                                                                       |
| `hostNetworking`		 			                    | Enable `hostNetwork`. Allows Pods to access host network.			                                                                                                                        | `false`					   	                                                                                       |
| `platform`		 				                    | Set platform. Use with `hostNetworking` and `enableNodePortServices` configuration to consider instance's external IP. Supported values - `eks` (AWS) or `gke` (GCP) or `none`    		| `none`					   	                                                                                       |
| `enableNodePortServices`		 	                    | Enable NodePort Services (`Type: NodePort`) to expose aerospike statefulset                                                                                                               | `false`					   	                                                                                       |
| `enableLoadBalancerServices`		                    | Enable LoadBalancer Services (`Type: LoadBalancer`) to expose aerospike statefulset                                                                                                       | `false`					                                                                                           |
| `enableExternalIpServices`		                    | Enable external IP Services (`Type: ClusterIP`) to expose aerospike statefulset                                                                                                           | `false`					                                                                                           |
| `externalIpEndpoints`		 		                    | Specify External IP/Port endpoints for `enableExternalIpServices`	                                                                                                                        | `{}` (nil)					   	                                                                                   |
| `rbac.create`		 			                        | Create a new ServiceAccount with a new ClusterRole for Aerospike Statefulset                                                                                                              | `false`					   	                                                                                       |
| `rbac.serviceAccountName`		 	                    | Specify an existing ServiceAccount to use with Aerospike Statefulset                                                                                                                      | `default`					   	                                                                                       |
| `antiAffinity`		 			                    | Enable `PodAntiAffinity` rule to schedule one pod per node. Supported values - `off`, `soft`, `hard`                                                                                      | `off`                                                                                                                |
| `antiAffinityWeight`		 		                    | 'weight' in range 1-100 for "soft" antiAffinity option    			                                                                                                                    | `1`					   		                                                                                       |
| `affinity`		 				                    | Define custom `nodeAffinity`/`podAffinity`/`podAntiAffinity` rules	                                                                                                                    | `{}` (nil)				   	                                                                                       |
| `persistenceStorage`                                  | Define Peristent Volumes to be used (Map - to define multiple volumes)                                                                                                                    | `{}` (nil)                                                                                                           |
| `volumes`                                             | Define volumes section and template to be used                                                                                                                                            | `volume[0].mountPath: /opt/aerospike/data`,<br />`volume[0].name: datadir`,<br />`volume[0].template: emptyDir: {}`  |
| `resources`                                           | Resource configuration (`requests` and `limits`)                                                                                                                                          | `{}` (nil)                                                                                                           |
| `confFilePath`                                        | Custom aerospike.conf file path on helm client machine (To be used during the runtime, `helm install` .. etc)                                                                             | `not defined`                                                                                                        |
| `prometheus.aerospikeAlertRulesFilePath`              | Aerospike alert rules configuration file location on helm client machine (To be used during the runtime, `helm install` .. etc)                                                           | `not defined`                                                                                                        |
| `alertmanager.alertmanagerConfFilePath`               | Alertmanager configuration file location on helm client machine (To be used during the runtime, `helm install` .. etc)                                                                    | `not defined`                                                                                                        |
| `enableAerospikeMonitoring`		 	                | Enable Aerospike Monitoring - sidecar prometheus exporter, Prometheus, Grafana, Alertmanager stack                                                                                        | `false`					   	                                                                                       |
| `exporter.repository`                                 | Aerospike prometheus exporter image repository                                                                                                                                            | `aerospike/aerospike-prometheus-exporter`                                                                            |
| `exporter.tag`                                        | Aerospike prometheus exporter image tag                                                                                                                                                   | `1.0.0`                                                                                                              |
| `exporter.agentUpdateInterval`                        | Aerospike prometheus exporter update interval (in seconds)                                                                                                                                | `5`                                                                                                                  |
| `exporter.agentTags`                                  | Aerospike prometheus exporter agent tags                                                                                                                                                  | `"'agent', 'aerospike'"`                                                                                             |
| `exporter.agentBindHost`                              | Aerospike prometheus exporter IP to bind to                                                                                                                                               | `""`                                                                                                                 |
| `exporter.agentBindPort`                              | Aerospike prometheus exporter port to bind to                                                                                                                                             | `9145`                                                                                                               |
| `exporter.agentTimeout`                               | Metrics server timeout (in seconds)                                                                                                                                                       | `10`                                                                                                                 |
| `exporter.agentLogLevel`                              | Aerospike prometheus exporter logging level                                                                                                                                               | `"info"`                                                                                                             |
| `exporter.asHost`                                     | Aerospike container service IP to connect to                                                                                                                                              | `"localhost"`                                                                                                        |
| `exporter.asPort`                                     | Aerospike container service port to connect to                                                                                                                                            | `3000`                                                                                                               |
| `exporter.tickerInterval`                             | Ticker interval (in seconds) to request statistics from aerospike container                                                                                                               | `5`                                                                                                                  |
| `exporter.tickerTimeout`                              | Agent client timeout (in seconds) for sending command to aerospike container                                                                                                              | `5`                                                                                                                  |
| `exporter.asAuthMode`                                 | Security auth mode to be used by exporter to connect to aerospike container                                                                                                               | `""`                                                                                                                 |
| `exporter.asAuthUser`                                 | Username to be used by exporter to connect to aerospike container                                                                                                                         | `""`                                                                                                                 |
| `exporter.asAuthPassword`                             | Password to be used by exporter to connect to aerospike container                                                                                                                         | `""`                                                                                                                 |
| `prometheus.replicas`                                 | Number of replicas for prometheus statefulset                                                                                                                                             | `2`                                                                                                                  |
| `prometheus.serverPort`                               | Prometheus server port                                                                                                                                                                    | `9090`                                                                                                               |
| `prometheus.terminationGracePeriodSeconds`            | Number of seconds to wait after `SIGTERM` before force killing the pod.                                                                                                                   | `120`                                                                                                                |
| `prometheus.image.repository`                         | Prometheus Docker Image Repository                                                                                                                                                        | `prom/prometheus`                                                                                                    |
| `prometheus.image.tag`                                | Prometheus Docker Image Tag                                                                                                                                                               | `v2.11.1`                                                                                                            |
| `prometheus.persistenceStorage`                       | Define storage for prometheus data                                                                                                                                                        | `{}` (nil)                                                                                                           |
| `prometheus.volume`                                   | Define storage for prometheus data                                                                                                                                                        | `volume.mountPath: /data`,<br />`volume.name: prometheus-data`,<br />`volume.template: emptyDir: {}`                 |
| `prometheus.resources`                                | Resource configuration (`requests` and `limits`)                                                                                                                                          | `{}` (nil)                                                                                                           |
| `grafana.replicas`                                    | Number of replicas for grafana statefulset                                                                                                                                                | `1`                                                                                                                  |
| `grafana.httpPort`                                    | Grafana server `http_port`                                                                                                                                                                | `3000`                                                                                                               |
| `grafana.plugins`                                     | Grafana plugins to install at startup                                                                                                                                                     | `"camptocamp-prometheus-alertmanager-datasource"`                                                                    |
| `grafana.image.repository`                            | Grafana Docker Image Repository                                                                                                                                                           | `grafana/grafana`                                                                                                    |
| `grafana.image.tag`                                   | Grafana Docker Image Tag                                                                                                                                                                  | `6.3.2`                                                                                                              |
| `grafana.persistenceStorage`                          | Define storage for grafana data                                                                                                                                                           | `{}` (nil)                                                                                                           |
| `grafana.volume`                                      | Define storage for grafana data                                                                                                                                                           | `volume.mountPath: /var/lib/grafana`,<br />`volume.name: grafana-data`,<br />`volume.template: emptyDir: {}`         |
| `grafana.resources`                                   | Resource configuration (`requests` and `limits`)                                                                                                                                          | `{}` (nil)                                                                                                           |
| `grafana.user`                                        | Grafana username and password                                                                                                                                                             | `"admin"`                                                                                                            |
| `grafana.password`                                    | Grafana username and password                                                                                                                                                             | `"admin"`                                                                                                            |
| `alertmanager.replicas`                               | Number of replicas for alertmanager statefulset                                                                                                                                           | `1`                                                                                                                  |
| `alertmanager.webPort`                                | Alertmanager web port                                                                                                                                                                     | `9093`                                                                                                               |
| `alertmanager.meshPort`                               | Alertmanager gossip port                                                                                                                                                                  | `9094`                                                                                                               |
| `alertmanager.image.repository`                       | Alertmanager Docker Image Repository                                                                                                                                                      | `prom/alertmanager`                                                                                                  |
| `alertmanager.image.tag`                              | Alertmanager Docker Image Tag                                                                                                                                                             | `latest`                                                                                                             |
| `alertmanager.loglevel`                               | Alertmanager logging level                                                                                                                                                                | `info`                                                                                                               |
| `alertmanager.persistenceStorage`                     | Define storage for alertmanager data                                                                                                                                                      | `{}` (nil)                                                                                                           |
| `alertmanager.volume`                                 | Define storage for alertmanager data                                                                                                                                                      | `volume.mountPath: /data`,<br />`volume.name: alertmanager-data`,<br />`volume.template: emptyDir: {}`               |
| `alertmanager.resources`                              | Resource configuration (`requests` and `limits`)                                                                                                                                          | `{}` (nil)                                                                                                           |


Note that the namespace related configurations (`aerospikeNamespace`, `aerospikeNamespaceMemoryGB`, `aerospikeReplicationFactor` and `aerospikeDefaultTTL`) are intended for default single namespace configuration.

If using multiple namespaces, these config items can be ignored and a separate `aerospike.conf` file or template with multiple namespace configuration can be used.
