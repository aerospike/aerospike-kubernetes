# aerospike-kube

This project contains the init container used in Kubernetes (k8s) and the Aerospike StatefulSet definition

This manifest will allow you to deploy a fully formed Aerospike cluster in minutes.

A docker registry is no longer required to build an init container.

Design is similar to github.com/aerospike/aerospike-gke, but without the Aerospike Enterprise specific items
nor Google Marketplace specific items.

## Usage:

### Configure:

Set environment variables (modify if necessary):

```
export APP_NAME=aerospike
export NAMESPACE=default
export AEROSPIKE_NODES=3
export AEROSPIKE_NAMESPACE=test
export AEROSPIKE_REPL=2
export AEROSPIKE_MEM=1
export AEROSPIKE_TTL=0
```

All `AEROSPIKE_*` parameters except AEROSPIKE\_NODES are optional. Default values are listed above.

All other parameters are required.

Uncomment either the storageclass-gcp.yaml or storageclass-aws.yaml, or provide your own storage class.

### Deploy:

Expand manifest template:

```
cat manifests/* | envsubst > expanded.yaml
```

Deploy:

```
kubectl create -f expanded.yaml
```

Create the configmap object:

```
kubectl create configmap aerospike-conf -n $NAMESPACE --from-file=configs/
```



## Requirements

* Kubernetes 1.3+ with alpha features (PetSet, init containers)   
or  
* Kubernetes 1.5+ with beta features (StatefulSet)  
or
* Kubernetes 1.8+


* Kubernetes DNS add-in


## Notes:

**Kubernetes 1.8+ (StatefulSet)**

Deploy your StatefulSet: `kubectl create -f aerospike-statefulset.yaml`

**Kubernetes 1.5 (StatefulSet old format)**

Deploy your StatefulSet: `kubectl create -f aerospike-statefulset.yaml`

*note* The last commit of the old template format is `cff91c3`.  

*note* PetSet, a k8s 1.3 alpha feature, is now StatefulSet, a 1.5 beta feature.

**Kubernetes 1.3 (PetSet)**

Deploy your PetSet: `kubectl create -f aerospike-petset.yaml`
