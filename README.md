# aerospike-kube

This project contains the init container used in Kubernetes (k8s).

## Usage:

Edit aerospike.conf with your configurations.

Build the container with `docker build -t <YOUR_DOCKER_REGISTRY>/aerospike-install .`

Push the container to your docker registry: `docker push <YOUR_DOCKER_REGISTRY>/aerospike/install`

Use this container in your kubernetes Aerospike PetSet (see Example)

## Requirements

* Kubernetes 1.3+ with alpha features (PetSet, init containers)
* Kubernetes DNS add-in

## Parameters:

**Kubernetes Namespace**: Pass in th thee `POD_NAMESPACE` envvar to set the k8s namespacee 

**Volumes**: A shared volume is required mount the re-written config file.


## Example

In your kubernetes PetSet yaml:

```
spec:
  serviceName: "aerospike"
  replicas: 3
  template:
    metadata:
      labels:
        app: aerospike
      annotations:
        pod.alpha.kubernetes.io/initialized: "true"
        pod.alpha.kubernetes.io/init-containers: '[
          {
             "name": "install",
             "image": "<YOUR_DOCKER_REGISTRY>/aerospike-install",
             "env": [
                  {
                      "name": "POD_NAMESPACE",
                      "valueFrom": {
                          "fieldRef": {
                              "apiVersion": "v1",
                              "fieldPath": "metadata.namespace"
                          }
                      }
                   }
                ],
             "volumeMounts": [
               {
                 "name":"confdir",
                 "mountPath": "/etc/aerospike"
               }
             ]
          }
        ]'
...
```
