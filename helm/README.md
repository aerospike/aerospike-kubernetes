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

All the configurations defined in [`values.yaml`](values.yaml) or in the [configuration section](#configuration) can be set using `--set` or `--set-file` option. A custom `values.yaml` file can also be provided using `-f` option.

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

- `confFilePath` can be set using `--set-file` option,
	```sh
	helm install aerospike-release aerospike/aerospike \
				 --set-file confFilePath=/tmp/aerospike_templates/aerospike.template.conf
	```

### Storage configuration

Aerospike helm chart allows multiple volume mounts (filesystem type) and device mounts (raw block device) to be configured and used with Aerospike Statefulset. Check below [configuration section](#configuration) or [`values.yaml`](https://github.com/aerospike/aerospike-kubernetes/blob/master/helm/values.yaml) file for more details.


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
aerospike-release	1       	Fri Mar  6 15:50:33 2020	DEPLOYED	aerospike-5.0.0             5.0.0.4   	default
```

### Expose Aerospike Cluster

Aerospike Cluster can be exposed to client applications or to XDR clients which are outside the K8s network by enabling,
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

Client applications can connect to the Aerospike cluster using instance's external IP (if available) or by using host IP.

```sh
asadm -h <ExternalIP> -p 3000 --services-alternate
```

### **NodePort Services Per Pod**

NodePort type exposes the Service on each K8s Node’s IP at a static port (the `NodePort`). Applications will be able to connect to the NodePort Service from outside the K8s cluster by using `<NodeIP>:<NodePort>`.

> With NodePort type services, it allows multiple aerospike pods per K8s host and at the same time expose each aerospike pod.

To enable `NodePort` services per pod, `enableNodePortServices` option must be set to `true`.
Aerospike helm chart will automatically create a `NodePort` type service for each aerospike pod at the time of deployment. Applications can connect to the Aerospike cluster using any one of the `<NodeIP>:<NodePort>` as a seed IP and Port.

Setting `platform` will fetch external IP of the instances (if any) and add it to [`alternate-access-address`](https://www.aerospike.com/docs/reference/configuration/index.html#alternate-access-address) in `aerospike.conf`.

> Use `helm upgrade` command to perform scale-up/scale-down when NodePort services are enabled.

A service account with appropriate permissions is required to query the API server and read the `Service` type resources. An existing service account can be specified using `rbac.serviceAccountName`. To let Aerospike helm chart create a new `ServiceAccount` with appropriate `ClusterRole` set `rbac.create` to `true`. This `ServiceAccount` will be used with Aerospike Statefulset, and if monitoring is enabled, also with Prometheus, Grafana and Alertmanager Statefulsets.

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

> With LoadBalancer type services, it allows multiple aerospike pods per K8s host and at the same time expose each aerospike pod.

To enable `LoadBalancer` services per pod, `enableLoadBalancerServices` option must be set to `true`.
Aerospike helm chart will automatically create a `LoadBalancer` type service for each aerospike pod at the time of deployment.

Applications can connect to the Aerospike cluster using `<LoadBalancerIngressIP>:<LoadBalancerPort>`.

```sh
asadm -h <LoadBalancerIngressIP> -p <LoadBalancerPort> --services-alternate
```

> Use `helm upgrade` command to perform scale-up/scale-down when LoadBalancer type services are enabled.

A service account with appropriate permissions is required to query the API server and read the `Service` type resources. An existing service account can be specified using `rbac.serviceAccountName`. To let Aerospike helm chart create a new `ServiceAccount` with appropriate `ClusterRole` set `rbac.create` to `true`. This `ServiceAccount` will be used with Aerospike Statefulset, and if monitoring is enabled, also with Prometheus, Grafana and Alertmanager Statefulsets.

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

`ClusterIP` type exposes the service on a cluster-internal IP. With external IPs set, the service can be accessed from an external endpoint.

With `enableExternalIpServices` option enabled, Aerospike helm chart will create a `ClusterIP` type service for each aerospike pod at the time of deployment. The external endpoints can be specified using `externalIpEndpoints` option.

> Use `helm upgrade` command to perform scale-up/scale-down when ClusterIP-ExternalIP services are enabled.

> Number of endpoints should be equal to the number of Aerospike pods (`dbReplicas`). Only one external IP and Port per Service can be specified.

A service account with appropriate permissions is required to query the API server and read the `Service` type resources. An existing service account can be specified using `rbac.serviceAccountName`. To let Aerospike helm chart create a new `ServiceAccount` with appropriate `ClusterRole` set `rbac.create` to `true`. This `ServiceAccount` will be used with Aerospike Statefulset, and if monitoring is enabled, also with Prometheus, Grafana and Alertmanager Statefulsets.

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
			 --set externalIpEndpoints[2].Port=8001 \
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
			 --set externalIpEndpoints[2].Port=8001 \
			 --set externalIpEndpoints[3].IP=10.160.15.223 \
			 --set externalIpEndpoints[3].Port=8002
```

### Aerospike Monitoring Stack

Aerospike Helm Chart provides Aerospike Monitoring Stack which includes an Aerospike prometheus exporter (sidecar), Prometheus statefulset, Grafana statefulset and Alertmanager statefulset.

#### Deploy Aerospike Prometheus Exporter (only)
Aerospike Prometheus Exporter (sidecar) can be enabled by setting `enableAerospikePrometheusExporter` option to `true`.

```sh
helm install aerospike-release aerospike/aerospike \
			 --set enableAerospikePrometheusExporter=true
```

For Helm v2,

```sh
helm install --name aerospike-release aerospike/aerospike \
			 --set enableAerospikePrometheusExporter=true
```

#### Deploy Complete Monitoring Stack
To deploy a complete monitoring stack which includes Prometheus, Grafana and Alertmanager, set `enableAerospikeMonitoring` option to `true`.

Note that, setting `enableAerospikeMonitoring` to `true` will automatically enable Aerospike Prometheus Exporter (sidecar).

```sh
helm install aerospike-release aerospike/aerospike \
			 --set rbac.create=true \
			 --set enableAerospikeMonitoring=true
```

For Helm v2,

```sh
helm install --name aerospike-release aerospike/aerospike \
			 --set rbac.create=true \
			 --set enableAerospikeMonitoring=true
```

Use option `--set-file prometheus.aerospikeAlertRulesFilePath` to add a custom aerospike alert rules configuration file.

> `prometheus.aerospikeAlertRulesFilePath` should be a file path on helm "client" machine (where the user is running 'helm install')

Use option `--set-file alertmanager.alertmanagerConfFilePath` to add an alertmanager configuration file.

> `alertmanager.alertmanagerConfFilePath` should be a file path on helm "client" machine (where the user is running 'helm install')

Check the below [configuration section](#configuration) or [`values.yaml`](values.yaml) file for more details on configuration of the `Aerospike Prometheus Exporter`, `Prometheus`, `Grafana` and `Alertmanager`.

### Configuration

| Parameter                                             | Description                                                                                                                                                                               | Default Value                                                                                                        |
| ------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------------------------------------:|
| `dbReplicas`                                          | Number of Aerospike nodes or pods in the cluster                                                                                                                                          | `3`                                                                                                                  |
| `terminationGracePeriodSeconds`                       | Number of seconds to wait after `SIGTERM` before force killing the pod.                                                                                                                   | `120`                                                                                                                |
| `clusterServiceDnsDomain`                             | Kubernetes cluster service DNS domain                                                                                                                                                     | `cluster.local`                                                                                                      |
| `image.repository`                                    | Aerospike Server Docker Image                                                                                                                                                             | `aerospike/aerospike-server`                                                                                         |
| `image.tag`                                           | Aerospike Server Docker Image Tag                                                                                                                                                         | `5.0.0.4`                                                                                                            |
| `initImage.repository`                                | Aerospike Kubernetes Init Container Image                                                                                                                                                 | `aerospike/aerospike-kubernetes-init`                                                                                |
| `initImage.tag`                                       | Aerospike Kubernetes Init Container Image Tag                                                                                                                                             | `1.1.0`                                                                                                              |
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
| `tolerations`		 				                    | Define tolerations for scheduling pods based on node taints                                                                                                                               | `{}` (nil)				   	                                                                                       |
| `nodeSelector`	 				                    | Define nodeSelector for scheduling pods based on node labels                                                                                                                              | `{}` (nil)				   	                                                                                       |
| `persistenceStorage`                                  | Define Peristent Volumes to be used (Map - to define multiple volumes)                                                                                                                    | `{}` (nil)                                                                                                           |
| `volumes`                                             | Define volumes section and template to be used                                                                                                                                            | `volume[0].mountPath: /opt/aerospike/data`,<br />`volume[0].name: datadir`,<br />`volume[0].template: emptyDir: {}`  |
| `resources`                                           | Resource configuration (`requests` and `limits`)                                                                                                                                          | `{}` (nil)                                                                                                           |
| `confFilePath`                                        | Custom aerospike.conf file path on helm client machine (To be used during the runtime, `helm install` .. etc)                                                                             | `not defined`                                                                                                        |
| `prometheus.aerospikeAlertRulesFilePath`              | Aerospike alert rules configuration file location on helm client machine (To be used during the runtime, `helm install` .. etc)                                                           | `not defined`                                                                                                        |
| `alertmanager.alertmanagerConfFilePath`               | Alertmanager configuration file location on helm client machine (To be used during the runtime, `helm install` .. etc)                                                                    | `not defined`                                                                                                        |
| `enableAerospikePrometheusExporter` 	                | Enable Sidecar Aerospike Prometheus Exporter (only)                                                                                                                                       | `false`					   	                                                                                       |
| `enableAerospikeMonitoring`		 	                | Enable Aerospike Monitoring - sidecar prometheus exporter, Prometheus, Grafana, Alertmanager stack                                                                                        | `false`					   	                                                                                       |
| `exporter.repository`                                 | Aerospike prometheus exporter image repository                                                                                                                                            | `aerospike/aerospike-prometheus-exporter`                                                                            |
| `exporter.tag`                                        | Aerospike prometheus exporter image tag                                                                                                                                                   | `1.0.0`                                                                                                              |
| `exporter.metricLabels`                               | Aerospike prometheus exporter custom labels for metrics                                                                                                                                   | `""`                                                                                                                 |
| `exporter.agentBindHost`                              | Aerospike prometheus exporter IP to bind to                                                                                                                                               | `""`                                                                                                                 |
| `exporter.agentBindPort`                              | Aerospike prometheus exporter port to bind to                                                                                                                                             | `9145`                                                                                                               |
| `exporter.agentTimeout`                               | Metrics server timeout (in seconds)                                                                                                                                                       | `10`                                                                                                                 |
| `exporter.agentLogLevel`                              | Aerospike prometheus exporter logging level                                                                                                                                               | `"info"`                                                                                                             |
| `exporter.aerospikeHost`                              | Aerospike container service IP to connect to                                                                                                                                              | `"localhost"`                                                                                                        |
| `exporter.aerospikePort`                              | Aerospike container service port to connect to                                                                                                                                            | `3000`                                                                                                               |
| `exporter.httpBasicAuthUsername`                      | Basic HTTP Authentication username for `/metrics` URL of the aerospike prometheus exporter                                                                                                | `""`                                                                                                                 |
| `exporter.httpBasicAuthPassword`                      | Basic HTTP Authentication password for `/metrics` URL of the aerospike prometheus exporter                                                                                                | `""`                                                                                                                 |
| `exporter.tickerTimeout`                              | Agent client timeout (in seconds) for sending command to aerospike container                                                                                                              | `5`                                                                                                                  |
| `exporter.aerospikeAuthMode`                          | Security auth mode to be used by exporter to connect to aerospike container                                                                                                               | `""`                                                                                                                 |
| `exporter.aerospikeAuthUser`                          | Username to be used by exporter to connect to aerospike container                                                                                                                         | `""`                                                                                                                 |
| `exporter.aerospikeAuthPassword`                      | Password to be used by exporter to connect to aerospike container                                                                                                                         | `""`                                                                                                                 |
| `exporter.namespaceMetricsWhitelist`                  | Namespace metrics whitelist for aerospike prometheus exporter                                                                                                                             | `not defined`                                                                                                        |
| `exporter.setMetricsWhitelist`                        | Set metrics whitelist for aerospike prometheus exporter                                                                                                                                   | `not defined`                                                                                                        |
| `exporter.nodeMetricsWhitelist`                       | Node metrics whitelist for aerospike prometheus exporter                                                                                                                                  | `not defined`                                                                                                        |
| `exporter.xdrMetricsWhitelist`                        | XDR metrics whitelist for aerospike prometheus exporter                                                                                                                                   | `not defined`                                                                                                        |
| `prometheus.replicas`                                 | Number of replicas for prometheus statefulset                                                                                                                                             | `2`                                                                                                                  |
| `prometheus.serverPort`                               | Prometheus server port                                                                                                                                                                    | `9090`                                                                                                               |
| `prometheus.terminationGracePeriodSeconds`            | Number of seconds to wait after `SIGTERM` before force killing the pod.                                                                                                                   | `120`                                                                                                                |
| `prometheus.scrapeInterval`                           | Prometheus `scrape_interval` in seconds to define interval between each scrape                                                                                                            | `15s`                                                                                                                |
| `prometheus.evaluationInterval`                       | How frequently to evaluate alert rules                                                                                                                                                    | `15s`                                                                                                                |
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
