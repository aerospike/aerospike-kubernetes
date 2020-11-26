# aerospike-kubernetes

This project uses Aerospike Server Community Edition. For Aerospike Server Enterprise Edition, please refer [aerospike/aerospike-kubernetes-enterprise](https://github.com/aerospike/aerospike-kubernetes-enterprise).

This project contains the init container used in Kubernetes (k8s) and the Aerospike StatefulSet definition.
These manifests will allow you to deploy a fully formed Aerospike cluster in minutes.

It uses:

- [aerospike-server docker image](https://hub.docker.com/r/aerospike/aerospike-server)
- [aerospike-kubernetes-init docker image](https://hub.docker.com/r/aerospike/aerospike-kubernetes-init)

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
export AEROSPIKE_NSUP_PERIOD=0 # if AEROSPIKE_TTL is not 0, AEROSPIKE_NSUP_PERIOD should not be 0.
```

All `AEROSPIKE_*` parameters except AEROSPIKE\_NODES, AEROSPIKE_MEM are optional. Default values are listed above.
All other parameters are required.

### Configuring Storage:

The [statefulset definition](manifests/statefulset.yaml) refers to a custom StorageClass `ssd`.
You can find the storageclass `ssd` definition in [storageclass-aws.yaml](manifests/storageclass-aws.yaml) or [storageclass-gcp.yaml](manifests/storageclass-gcp.yaml) (Uncomment them to use). You can also define your own storageclass and use it within the statefulset definition.

> Dynamic provisioning for local volumes are not supported yet. However, a local volume provisioner can be deployed to automate the provisioning of local devices. Please check [`examples/`](examples/) for using a local volume static provisioner.

If you want to use the raw block volume mode, you need to define `volumeMode` as `Block` in the Volume Claim and use `volumeDevices` and `devicePath` instead of `volumeMounts` and `mountPath` as shown in the example below.

```
  volumeClaimTemplates:
  - metadata:
      name: data-dev
      labels: *AerospikeDeploymentLabels
    spec:
      volumeMode: Block
      accessModes:
        - ReadWriteOnce
      storageClassName: ssd
      resources:
        requests:
          storage: ${AEROSPIKE_MEM}Gi
```
```
.....
volumeMounts:
        - name: confdir
          mountPath: /etc/aerospike
volumeDevices:
        - name: data-dev
          devicePath: /dev/sdb
.....
```

For Kubernetes version > 1.11, there's a default storage class `gp2` available on AWS EKS clusters, uses `aws-ebs` provisioner and volume type `gp2`.

### Examples:

To view and run the examples, go to [`examples/`](examples/)

### Deployment:

Please follow the below steps or run `start.sh` script:

1. Expand manifest template:

```sh
cat manifests/* | envsubst > expanded.yaml
```

2. Create the configmap object:

```sh
kubectl create configmap aerospike-conf -n $NAMESPACE --from-file=configs/
```

3. Deploy:

```sh
kubectl create -f expanded.yaml
```

### Helm Charts

Helm chart for the same can be found [here](helm/)

## Requirements

* Kubernetes 1.8+
* Kubernetes DNS add-in
