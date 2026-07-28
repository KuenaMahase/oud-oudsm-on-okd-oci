# NFS CSI and StorageClass

## Successful implementation

The NFS CSI driver was installed into `openshift-csi-driver-nfs-namespace`. Dedicated controller and node service accounts received the required SCC access. A test PVC and pod successfully created a dynamic NFS subdirectory and wrote `hello-from-nfs`.

## Final storage model

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-rwx
provisioner: nfs.csi.k8s.io
parameters:
  server: nfs01.lab.example
  share: /scratch/shared/oud_user_projects
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
```

Create the StorageClass once. It is cluster-scoped. PVCs in `oudns` and `oudsmns` reference it by name.

## Smooth-deployment commands

```bash
# Driver objects and health
oc get csidrivers
oc get csinode
oc get pods -n openshift-csi-driver-nfs-namespace -o wide
oc get daemonset,deployment -n openshift-csi-driver-nfs-namespace

# SCC and service-account review
oc adm policy who-can use scc/privileged
oc auth can-i use scc/privileged   --as system:serviceaccount:openshift-csi-driver-nfs-namespace:csi-nfs-node-sa

# Storage inventory
oc get sc
oc get sc nfs-rwx -o yaml
oc get pvc -A
oc get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,STATUS:.status.phase,CLAIM:.spec.claimRef.namespace/.spec.claimRef.name,SC:.spec.storageClassName,PROVISIONER:.spec.csi.driver

# Follow provisioning events
oc get events -A --sort-by=.lastTimestamp | tail -100
oc describe pvc -n <namespace> <pvc-name>
```

## Validation

```bash
oc apply -f manifests/storage/nfs-test-pvc.yaml
oc apply -f manifests/storage/nfs-test-pod.yaml
oc wait --for=condition=Ready pod/nfs-test-pod -n storage-validation --timeout=180s
oc exec -n storage-validation nfs-test-pod -- cat /data/hello
```

## Official references

- Kubernetes StorageClasses: https://kubernetes.io/docs/concepts/storage/storage-classes/
- Kubernetes Persistent Volumes: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- NFS CSI project: https://github.com/kubernetes-csi/csi-driver-nfs
- NFS CSI parameters: https://github.com/kubernetes-csi/csi-driver-nfs/blob/master/docs/driver-parameters.md
- OpenShift SCCs: https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html-single/authentication_and_authorization/index
