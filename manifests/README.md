## Configuring Storage

The [statefulset definition](statefulset.yaml) refers to a custom StorageClass `ssd`.
You can find the storageclass `ssd` definition in [storageclass-aws.yaml](storageclass-aws.yaml) or [storageclass-gcp.yaml](storageclass-gcp.yaml) (Uncomment them to use). You can also define your own storageclass and use it within the statefulset definition.

If want to use the raw block volume mode, you need to use `volumeMode` as `Block` in the Volume Claim and use `VolumeDevices` and `devicePath` instead of `VolumeMounts` and `mountPath` as shown in the example below.

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
