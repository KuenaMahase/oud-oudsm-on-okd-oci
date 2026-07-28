# NFS server and OCI Block Volume

## Objective

Provide persistent shared infrastructure for dynamically provisioned Kubernetes volumes without allowing multiple OUD replicas to share one database directory.

## Successful implementation

- Oracle Linux 9 NFS VM.
- 1 TB OCI Block Volume attached and observed as a block device.
- Filesystem mounted under `/scratch`.
- Export root `/scratch/shared/oud_user_projects`.
- Cluster workers allowed to use the NFS service.
- Persistent mount added to `/etc/fstab`.

## Sanitized successful sequence

```bash
sudo dnf install -y nfs-utils
lsblk -f
sudo blkid

# Replace the device and filesystem to match the actual VM.
sudo mkfs.xfs /dev/sdb
sudo mkdir -p /scratch
sudo mount /dev/sdb /scratch
findmnt /scratch
df -hT /scratch

sudo mkdir -p /scratch/shared/oud_user_projects
sudo chown -R 1000:0 /scratch/shared/oud_user_projects
sudo chmod 2770 /scratch/shared/oud_user_projects

# Use the filesystem UUID for persistent mounting.
sudo blkid /dev/sdb
sudoedit /etc/fstab
sudo mount -a
findmnt --verify

printf '%s
' '/scratch/shared/oud_user_projects 10.20.0.0/16(rw,sync,no_subtree_check)'   | sudo tee /etc/exports.d/oud-projects.exports
sudo exportfs -rav
sudo exportfs -v
sudo systemctl enable --now nfs-server
sudo systemctl status nfs-server --no-pager
```

The public examples intentionally omit `no_root_squash`. Use it only when a proven application requirement and reviewed threat model justify it.

## Additional checks that make deployment smoother

```bash
# Confirm service listeners
sudo ss -lntup | grep -E ':(111|2049|20048)\b'

# Confirm RPC programs when NFSv3 services are used
rpcinfo -p localhost

# Confirm export visibility from a worker or admin host
showmount -e nfs01.lab.example

# Check recent server-side mount or export errors
sudo journalctl -u nfs-server --since '30 minutes ago' --no-pager
sudo dmesg --level=err,warn | tail -100
```

## Reboot failure and final corrective action

A later pod-mount failure was traced to `/scratch` not being mounted before the NFS service started. The permanent correction was a valid UUID-based `/etc/fstab` entry followed by `mount -a`, `findmnt --verify`, `exportfs -rav`, and a service restart.

## Official references

- OCI Block Volumes: https://docs.oracle.com/en-us/iaas/Content/Block/Concepts/overview.htm
- Oracle IAM Kubernetes enterprise deployment storage guidance: https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/
