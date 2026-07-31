# Historical source note

> Sanitized working note. Treat commands and values as historical evidence, not a current production runbook.

Do not duplicate the StorageClass. StorageClass is cluster scoped, not namespaced. Create it once, then reference it from any namespace with `storageClassName: nfs-rwx`. PVCs are namespaced. PVs are cluster scoped.

## What to do

* Keep a single `StorageClass`:

  ```bash
  oc get sc
  oc get sc nfs-rwx -o yaml   # no namespace field
  ```
* Use it from both namespaces by name:

  * `oudns`
  * `oudsmns`

## Make it cluster wide default

One default at a time.

```bash
# mark nfs-rwx as default
oc annotate sc nfs-rwx storageclass.kubernetes.io/is-default-class="true" --overwrite

# remove default flag from others if present
oc annotate sc <old-default> storageclass.kubernetes.io/is-default-class- --overwrite
```

After this, any PVC without `storageClassName` picks `nfs-rwx`.



PVC in `oudns`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: oud-data-claim
  namespace: oudns
spec:
  accessModes: [ "ReadWriteMany" ]
  resources:
    requests:
      storage: 20Gi
  storageClassName: nfs-rwx
```

PVC in `oudsmns`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: oudsm-data-claim
  namespace: oudsmns
spec:
  accessModes: [ "ReadWriteMany" ]
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-rwx
```

StatefulSet `volumeClaimTemplates` in `oudns` will reference `storageClassName: nfs-rwx` the same way.

## Verify bindings

```bash
oc get pvc -A | grep -E 'oudns|oudsmns'
oc get pv | grep nfs.csi.k8s.io
sudo ls -l /scratch/shared/oud_user_projects   # pvc-<uid> folders
```


Do not create duplicate StorageClasses with the same name in different namespaces. That is not a thing. The driver’s pods live in their own namespace, which is fine. The StorageClass remains visible cluster wide.


