# aerospike-kube

This direcotry contains the init container used in Kubernetes (k8s).

## Usage:

Edit aerospike.conf with your configurations.

Build the container with `docker build -t <YOUR_DOCKER_REGISTRY>/aerospike-install .`

Push the container to your docker registry: `docker push <YOUR_DOCKER_REGISTRY>/aerospike/install`

Use this container in your kubernetes Aerospike PetSet (see Example)

## Parameters:

**Kubernetes Namespace**: Set the `POD_NAMESPACE` envvar to set the k8s namespacee 

**Volumes**: A shared volume is required mount the re-written config file at /etc/aerospike


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

### Hints

* To use an insecure registry, do the following on each (non-master) node.
```
edit /etc/sysconfig/docker, by adding the line:
INSECURE_REGISTRY='--insecure-registry YOUR_REGISTRY_ADDRESS:PORT'
```
