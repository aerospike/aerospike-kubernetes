# Helm chart for Aerospike on Kubernetes

Implements a dynamically scalable Aerospike cluster using Kubernetes StatefulSets.


## Usage:

1. Before installing the chart, copy all the files [config/](../configs/) directory to `files/` directory. These files are necessary to create configMap object.

2. Install the chart.

```sh
helm install --name aerospike ./
```

You can also set the configuration values as defined in `values.yaml` using `--set` option.
For example, 

```sh
helm install --set dBReplicas=5 --name aerospike-release ./
```

### Output:

```sh
NAME:   aerospike-release
LAST DEPLOYED: Tue Aug 27 15:40:36 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                    DATA  AGE
aerospike-release-conf  3     0s

==> v1/Pod(related)
NAME                 READY  STATUS    RESTARTS  AGE
aerospike-release-0  0/1    Init:0/1  0         0s

==> v1/Service
NAME               TYPE       CLUSTER-IP  EXTERNAL-IP  PORT(S)   AGE
aerospike-release  ClusterIP  None        <none>       3000/TCP  0s

==> v1/StatefulSet
NAME               READY  AGE
aerospike-release  0/3    0s
```

```sh
$ helm list
NAME             	REVISION	UPDATED                 	STATUS  	CHART          	APP VERSION	NAMESPACE
aerospike-release	1       	Tue Aug 27 15:40:36 2019	DEPLOYED	aerospike-1.0.0	4.6.0.2    	default  
```

3. To package the chart,

```sh
helm package ./
```
Note that the directory name and Chart name must match.
