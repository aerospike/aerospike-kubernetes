## Example - Deploy an Aerospike cluster with namespace data storage on local SSDs and with Shadow Device configuration

### Description

This example includes:

- Deploying an Aerospike cluster with namespace `storage-engine` as `device` (raw block device mode).
- Use Aerospike **Shadow Device configuration** to guarantee persistence.

    In cloud environments, the direct-attached or local SSDs (also called as ephemeral drives/volumes) does not guarantee persistence. These volumes are created along with the instance, and purged when the instance stops. The local ephemeral volumes are much faster compared to persistent disks which are network attached (for example, EBS volumes on AWS). Aerospike allows the [configuration of shadow devices](https://www.aerospike.com/docs/operations/configure/namespace/storage/#recipe-for-shadow-device) where all the writes are also propagated to a secondary persistent storage device.

    ```sh
    storage-engine device{
            device /dev/sdb /dev/sdf
            device /dev/sdc /dev/sdg
            ...
    }
    ```
- Configure and deploy a local volume provisioner to manage local SSDs and automate volume provisioning for Aerospike pods.

Let's get started.

In this example, we will set and use the Kubernetes `namespace` as `dev` and `app` name as `aerospike-test`.

### Create namespace `dev`

The namespace definition is present in [namespace.yaml](namespace.yaml)
```sh
$ kubectl create -f namespace.yaml
```
```sh
$ kubectl get namespaces

NAME          STATUS   AGE
default       Active   10d
dev           Active   6s
kube-public   Active   10d
kube-system   Active   10d
```

### Create discovery directory and link the devices

Before deploying local volume provisioner, create a discovery directory on each worker node and link the block devices to be used into the discovery directory. The provisioner will discover local block volumes from this directory.

In this example, there are two local SSDs (identified as `/dev/sdb` and `/dev/sdc`) attached to each worker node (we have two worker nodes in this example) which can be used for the Aerospike Cluster deployment.

```
$ lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sdb       8:16   0  375G  0 disk 
sdc       8:32   0  375G  0 disk
```

```sh
$ mkdir /mnt/disks
```

Use unique device IDs rather than the names `/dev/sdb` or `/dev/sdc`.

```sh
$ ln -s /dev/disk/by-id/local-ssd-0 /mnt/disks
$ ln -s /dev/disk/by-id/local-ssd-1 /mnt/disks
```

> Note : <br /> You can also use your own discovery directory, but make sure that the [provisioner](aerospike-local-volume-provisioner.yaml) is also configured to point to the same directory.

### Configure and deploy local volume provisioner

To automate the local volume provisioning, we will create and run a provisioner based on [kubernetes-sigs/sig-storage-local-static-provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner). 

The provisioner will run as a `DaemonSet` which will manage the local SSDs on each node based on a discovery directory, create/delete the PersistentVolumes and clean up the storage when it is released.

The local volume static provisioner for this example is defined in [aerospike-local-volume-provisioner.yaml](aerospike-local-volume-provisioner.yaml). Each specification is highlighted with comments in the same file.

Deploy the provisioner,

```sh
$ kubectl create -f aerospike-local-volume-provisioner.yaml

configmap/local-provisioner-config created
daemonset.apps/local-volume-provisioner created
storageclass.storage.k8s.io/aerospike-ssds created
serviceaccount/local-storage-admin created
clusterrolebinding.rbac.authorization.k8s.io/local-storage-provisioner-pv-binding created
clusterrole.rbac.authorization.k8s.io/local-storage-provisioner-node-clusterrole created
clusterrolebinding.rbac.authorization.k8s.io/local-storage-provisioner-node-binding created
```

Verify the discovered and created PV objects,
```sh
$ kubectl get pv

NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS     REASON   AGE
local-pv-342b45ed   375Gi      RWO            Delete           Available           aerospike-ssds            3s
local-pv-3587dbec   375Gi      RWO            Delete           Available           aerospike-ssds            3s
local-pv-df716a06   375Gi      RWO            Delete           Available           aerospike-ssds            3s
local-pv-eaf4a027   375Gi      RWO            Delete           Available           aerospike-ssds            3s
```

Note that the `storageclass` configured here is `aerospike-ssds`. We will use this storageclass in PVC or volumeClaimTemplates to talk to the provisioner and request PV resources (See [Statefulset definition](#deploy-aerospike-cluster-using-a-statefulset-defintion)).

### Provisioning Shadow device volumes

Define a `storageClass` for provisioning of 'shadow device' persistent disks. Kubernetes allows [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/) (create storage volumes on-demand) using pre-created [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/).

For this example, we will create a StorageClass `shadow` which uses `gce-pd` provisioner (since this setup is running on GKE) and specify the parameters as `type: pd-ssd` (volume type). Please check [storageclass-gcp.yaml](storageclass-gcp.yaml)

```sh
$ kubectl create -f storageclass-gcp.yaml
```

### Create and deploy ConfigMap object

The [configmap](configmap) directory contains the Aerospike configuration file template for this example - `aerospike.template.conf`.

Create configMap object,

```sh
$ kubectl create configmap aerospike-conf -n dev --from-file=configmap/
```

> Note : <br /> For this example, we will configure only a single Aerospike Namespace with data storage on a single raw block volume with a shadow device. If you prefer to use multiple namespaces, please use a custom aerospike.conf file or template accordingly.

Note that `storage-engine` configuration in `aerospike.template.conf` is using a primary block device `/dev/xvdb` and a secondary 'shadow device' `/dev/xvdf`. You can also use multiple raw devices in the storage-engine configuration, but make sure that each of them have a corresponding PVC through `volumeClaimTemplates` in the statefulset definition (Check [Things to note](#things-to-note) section).
```
...
	storage-engine device {
        device /dev/xvdb /dev/xvdf # Shadow device configuration.
		# device /dev/<device> /dev/<shadowdevice>  # (optional) another raw device / shadow device.
        write-block-size 128K
        # data-in-memory true # Store data in memory in addition to file.
	}
...
```

### Create and run a 'headless' service (for DNS lookup)

For this example, we will use the Service defined in [service.yaml](service.yaml)

```sh
$ kubectl create -f service.yaml
```


### Deploy Aerospike cluster using a statefulset defintion

For this example, the statefulset definition is present in [statefulset-shadow-device.yaml](statefulset-shadow-device.yaml).

Set necessary variables (rest are optional),

```sh
export AEROSPIKE_NODES=3
export AEROSPIKE_MEM=1
export AEROSPIKE_STORAGE_SZ=375
```
Below are the default values for rest of the variables.

```
AEROSPIKE_NAMESPACE=test
AEROSPIKE_REPL=2
AEROSPIKE_TTL=0
```

Substitute the above variables into the `statefulset-shadow-device.yaml` and deploy.

```sh
$ cat statefulset-shadow-device.yaml | envsubst '$AEROSPIKE_NODES $AEROSPIKE_NAMESPACE $AEROSPIKE_REPL $AEROSPIKE_MEM $AEROSPIKE_TTL $AEROSPIKE_STORAGE_SZ' > statefulset.yaml
```
Deploy,

```sh
$ kubectl create -f statefulset.yaml
```

#### Things to note:

- The `volumeClaimTemplates` is used to request PV resource from the deployed provisioner via storageClass `aerospike-ssds`. The `volumeMode` is set to `Block` (Block device mode). For the shadow device volumes, we will be using the storageClass `shadow` created in [Provisioning shadow device volumes](#provisioning-shadow-device-volumes).
    ```sh
    ......
    volumeClaimTemplates:
  - metadata:
      name: data-dev
      labels: *AerospikeDeploymentLabels
    spec:
      volumeMode: Block
      accessModes:
        - ReadWriteOnce
      storageClassName: aerospike-ssds
      resources:
        requests:
          storage: ${AEROSPIKE_STORAGE_SZ}Gi
  - metadata:
      name: shadow-dev
      labels: *AerospikeDeploymentLabels
    spec:
      volumeMode: Block
      accessModes:
        - ReadWriteOnce
      storageClassName: shadow
      resources:
        requests:
          storage: ${AEROSPIKE_STORAGE_SZ}Gi
    ```
- `volumeDevices` (block mode) must use the same name as specified in `volumeClaimTemplates` and a device path (like `/dev/xvdb` and `/dev/xvdf`below) accessible within the container must be specified. This device path can then be used within the aerospike namespace `storage-engine` configuration.
    ```sh
    .....
    volumeDevices:
      - name: data-dev
        devicePath: /dev/xvdb
      - name: shadow-dev
        devicePath: /dev/xvdf
    ....
    ```

### Output:


```sh
$ kubectl get pv

NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                        STORAGECLASS     REASON   AGE
local-pv-342b45ed                          375Gi      RWO            Delete           Available                                aerospike-ssds            6m56s
local-pv-3587dbec                          375Gi      RWO            Delete           Bound       dev/data-dev-aerospike-1     aerospike-ssds            7m32s
local-pv-df716a06                          375Gi      RWO            Delete           Bound       dev/data-dev-aerospike-2     aerospike-ssds            8m05s
local-pv-eaf4a027                          375Gi      RWO            Delete           Bound       dev/data-dev-aerospike-0     aerospike-ssds            6m56s
pvc-b7285001-da43-11e9-ac74-42010aa0014b   375Gi      RWO            Delete           Bound       dev/shadow-dev-aerospike-0   shadow                    3m56s
pvc-3421ed54-d944-11e9-ac74-42010aa0014b   375Gi      RWO            Delete           Bound       dev/shadow-dev-aerospike-1   shadow                    7m05s
pvc-5ca77b01-d944-11e9-ac74-42010aa0014b   375Gi      RWO            Delete           Bound       dev/shadow-dev-aerospike-2   shadow                    7m55s
```

```sh
Sep 18 2019 18:41:10 GMT: INFO (drv_ssd): (drv_ssd.c:3216) opened device /dev/xvdb: usable size 402653184000, io-min-size 4096
Sep 18 2019 18:41:10 GMT: INFO (drv_ssd): (drv_ssd.c:3270) shadow device /dev/xvdf is compatible with main device, shadow-io-min-size 512
Sep 18 2019 18:41:10 GMT: INFO (drv_ssd): (drv_ssd.c:1068) /dev/xvdb has 3072000 wblocks of size 131072
...
Sep 18 2019 16:20:29 GMT: INFO (drv_ssd): (drv_ssd.c:1919) {test} /dev/xvdb: used-bytes 0 free-wblocks 3071936 write-q 0 write (0,0.0) defrag-q 0 defrag-read (0,0.0) defrag-write (0,0.0)
Sep 18 2019 16:20:29 GMT: INFO (info): (ticker.c:162) NODE-ID bb9fe910a5d3186 CLUSTER-SIZE 3
...
```

```sh
$ kubectl get all --namespace dev

NAME                                 READY   STATUS    RESTARTS   AGE
pod/aerospike-0                      1/1     Running   0          21m
pod/aerospike-1                      1/1     Running   0          12m
pod/aerospike-2                      1/1     Running   0          11m
pod/local-volume-provisioner-lp5h7   1/1     Running   0          54m
pod/local-volume-provisioner-vwpd5   1/1     Running   0          122m

NAME                TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/aerospike   ClusterIP   None         <none>        3000/TCP   13m

NAME                                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/local-volume-provisioner   2         2         2       2            2           <none>          123m

NAME                         READY   AGE
statefulset.apps/aerospike   3/3     21m
```