# End-to-end NFS and OKD runbook on OCI

> Sanitized reconstruction of the original working runbook.

1. Provision an Oracle Linux 9 NFS VM and attach a 1 TB balanced block volume.
2. Mount the volume at `/scratch` and persist it in `/etc/fstab`.
3. Export `/scratch/shared/oud_user_projects` to the cluster CIDR.
4. Install the Kubernetes NFS CSI driver with the required OpenShift SCCs.
5. Create `nfs-rwx` and validate a `ReadWriteMany` PVC.
6. Confirm the test pod writes `hello-from-nfs` and a PVC-specific directory is created.

## Historical validation

- NFS server: Oracle Linux 9
- Storage: 1 TB OCI block volume
- Export: `/scratch/shared/oud_user_projects`
- Provisioner: `nfs.csi.k8s.io`
- Test: `hello-from-nfs` written from an OpenShift pod

## Recovery lesson

A reboot exposed a missing `/scratch` mount. The durable fix was to correct
`/etc/fstab`, mount the volume before `nfs-server`, reload exports, and then
verify the PVC mounts from the cluster.
