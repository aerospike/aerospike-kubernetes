# Change Log

This file documents all notable changes to Aerospike Helm Chart.

## [1.0.1]
- Update Chart `4.7.0` to use Aerospike Server versions `4.7.0.3` (appVersion).
- Update Chart `4.6.0` to use Aerospike Server version `4.6.0.6` (appVersion).
- Added 'Expose Aerospike Cluster' section to README.
- Added CHANGELOG.md

## [1.0.0]

- Supports `NodeAffinity`/`PodAffinity`/`PodAntiAffinity` rules.
   - Set `antiAffinity` to ensure one Pod per Node (for a release).
     Supported Values:  `off`, `soft` ('preferred' during scheduling), and `hard` ('required' during scheduling). Default : `off`
   - Set `antiAffinityWeight` option to specify 'weight' for 'soft' 'antiAffinity' option above. Default : `1`
   - Users can also define their custom `PodAffinity`/`PodAntiAffinity`/`NodeAffinity` rules using a third option `affinity`. Default: `{}` (not set)
- Auto rollout changes to ConfigMaps on helm upgrade.
   - Set `autoRolloutConfig=true`. Default: `false`
- Added option `autoGenerateNodeIds` to generate unique default node-ids. Default: `false`
- Added option `hostNetworking` to enable host networking. Default: `false`
- Added option `platform` to work with hostNetworking. Use both to auto-configure Aerospike to use external IP as alternate access address if it exists.
Supported values : `none`, `gke`, and `eks`
- Peer finder will now work with hostNetworking and use K8s Cluster DNS.
- Renamed `dBReplicas` to `dbReplicas`.
- Increased termination grace period from `30` to `120` default.
- Changed default `aerospikeDefaultTTL` to `0` (Never Expire), dbReplicas to `3`.
- Update Chart `4.7.0` to use Aerospike Server versions `4.7.0.2` (appVersion).
- Update Chart `4.6.0` to use Aerospike Server version `4.6.0.5` (appVersion).