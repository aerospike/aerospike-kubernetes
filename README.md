# aerospike-kube

This project contains the init container used in Kubernetes (k8s) and the Aerospike StatefulSet definition

This manifest will allow you to deploy a fully formed Aerospike cluster in minutes.

A docker registry is no longer required to build an init container.

Design is similar to github.com/aerospike/aerospike-gke, but without the Aerospike Enterprise specific items
nor Google Marketplace specific items.

## Usage:

### Configure:

Set environment variables (modify if necessary):

```sh
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

```sh
cat manifests/* | envsubst > expanded.yaml
```

Deploy:

```sh
kubectl create -f expanded.yaml
```

Create the configmap object:

```sh
kubectl create configmap aerospike-conf -n $NAMESPACE --from-file=configs/
```

## Requirements

* Kubernetes 1.8+
* Kubernetes DNS add-in
