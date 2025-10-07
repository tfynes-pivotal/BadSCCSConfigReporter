# BadSCCSConfigReporter

Utility to be run from OpsManager VM

Uses authenticated CredHub cli to find all spring cloud services stored configurations

Tests each for the presence of invalid configuration keys for Tanzu SCCS 
["defaultLabel","passphrase","baseDir","tryMasterBranch","forcePull","knownHostFile","preferredAuthentications","ignoreLocalSshSettings","cloneSubmodules","deleteUntrackedBranches","repos"]

If a credhub reference flags as positive for storing one of these forbidden keys, the utility will use the authenticated cf cli to determine which app in which space is bound to the config-server SI that uses this credhub reference

A CSV output is generated listing all SCCS SI instances flagged for having an illegal/unsupported OSS config service key present;

CSV output will emit;
ConfigServerSIGuid, AppSpaceGuid, AppSpaceName, BoundAppGuid, BoundAppName

e.g.
ConfigServerSIGuid, AppSpaceGuid, AppSpaceName, BoundAppGuid, BoundAppName
d58bf646-b3b6-4c81-9041-ca4becbdeb3d, e9b23f0b-35c4-4aed-81af-51a426aceef2, DemoSpace, 1ea2c58f-26ee-4e5d-8d27-fe6e9a4f0848, tdemo
