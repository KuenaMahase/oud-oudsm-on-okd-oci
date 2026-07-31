# Historical source note

> Sanitized working note. Treat commands and values as historical evidence, not a current production runbook.

Use one StorageClass, cluster wide, named `nfs-rwx`. Point all three charts to it with PVCs. Do not duplicate the StorageClass in namespaces.

## OUD DS, `values-oud.yaml`

```yaml
persistence:
  enabled: true
  type: pvc
  size: 20Gi
  accessModes:
    - ReadWriteMany
  storageClassCreate: false
  storageClass: nfs-rwx
  networkstorage: {}

# If the chart supports it, set the mount path here.
persistence:
  mountPath: /u01/oracle/user_projects

# If it does not, add a volume mount.
extraVolumeMounts:
  - name: oud-data
    mountPath: /u01/oracle/user_projects

securityContext:
  runAsUser: 1000
  runAsGroup: 0
  fsGroup: 1000
```

Deploy

```bash
helm upgrade --install oud-ds <path-to-oud-ds-chart> -n oudns -f values-oud.yaml
```

## OUDSM, `values-oudsm.yaml`

```yaml
persistence:
  enabled: true
  type: pvc
  size: 10Gi
  accessModes:
    - ReadWriteMany
  storageClassCreate: false
  storageClass: nfs-rwx
  networkstorage: {}
  mountPath: /u01/oracle/user_projects/oudsm

securityContext:
  runAsUser: 1000
  runAsGroup: 0
  fsGroup: 1000
```

Deploy

```bash
helm upgrade --install oudsm <path-to-oudsm-chart> -n oudsmns -f values-oudsm.yaml
```

## OUD Proxy, `values-oud-proxy.yaml`

```yaml
persistence:
  enabled: true
  type: pvc
  size: 5Gi
  accessModes:
    - ReadWriteMany
  storageClassCreate: false
  storageClass: nfs-rwx
  networkstorage: {}
  mountPath: /u01/oracle/user_projects/proxy

securityContext:
  runAsUser: 1000
  runAsGroup: 0
  fsGroup: 1000


```

Deploy

```bash
helm upgrade --install oud-proxy <path-to-oud-proxy-chart> -n oudns -f values-oud-proxy.yaml
```

## NFS server and permissions

On the NFS VM ensure ownership and mode fit OUD UID and GID.

```bash
sudo chown -R 1000:0 /scratch/shared/oud_user_projects
sudo chmod 0775 /scratch/shared/oud_user_projects
```

## Verify bindings and mounts

```bash
oc -n oudns get pvc
oc -n oudsmns get pvc
oc get pv | grep nfs.csi.k8s.io

# Quick write tests
POD=$(oc -n oudns get pod -l app.kubernetes.io/name=oud -o jsonpath='{.items[0].metadata.name}')
oc -n oudns exec -it "$POD" -- bash -lc 'echo ds-ok > /u01/oracle/user_projects/.probe'

PPOD=$(oc -n oudns get pod -l app=oud-proxy -o jsonpath='{.items[0].metadata.name}')
oc -n oudns exec -it "$PPOD" -- sh -lc 'echo proxy-ok > /u01/oracle/user_projects/proxy/.probe'

SPOD=$(oc -n oudsmns get pod -l app=oudsm -o jsonpath='{.items[0].metadata.name}')
oc -n oudsmns exec -it "$SPOD" -- sh -lc 'echo sm-ok > /u01/oracle/user_projects/oudsm/.probe'

# On the NFS VM
sudo find /scratch/shared/oud_user_projects -maxdepth 2 -name .probe -print
```

### Notes

* StorageClass is cluster scoped. Create it once. Reference `storageClass: nfs-rwx` in every override file.
* PVCs are namespaced. Each chart creates its own PVCs in its namespace.
* Keep `reclaimPolicy: Retain` on the StorageClass to protect data on uninstall.


