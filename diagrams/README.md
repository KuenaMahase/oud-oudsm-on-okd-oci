# Diagrams

Mermaid is the primary source format because GitHub renders it natively. D2 is used selectively for a polished source-as-code view. The draw.io file is the editable source for a detailed cloud/network layout.

## Status convention

- Solid node/arrow: verified or strongly observed.
- Dashed `VERIFY` node/arrow: unresolved and excluded from confirmed claims.
- Rendered SVGs are generated from `.mmd` files by `scripts/rendering/render-mermaid.sh`.

## GitHub-rendered gallery

Open [`GALLERY.md`](GALLERY.md) to view every Mermaid diagram rendered natively by GitHub.

## Diagram inventory

| File | Purpose |
|---|---|
| `01-final-platform-context.mmd` | Recruiter-readable full platform context |
| `02-final-oci-network-topology.mmd` | OCI nodes, listeners and NFS |
| `03-final-okd-cluster-topology.mmd` | OpenShift roles, namespaces and workloads |
| `04-final-load-balancer-and-ingress-flow.mmd` | API, HTTPS and LDAP flows |
| `05-final-nfs-csi-storage-flow.mmd` | Dynamic provisioning |
| `06-final-oud-statefulset-storage.mmd` | Per-replica persistence |
| `07-final-oud-replication-topology.mmd` | Replication relationships |
| `08-final-oud-proxy-routing.mmd` | `dsconfig` routing objects |
| `09-final-oudsm-access-flow.mmd` | UI and administration sequence |
| `10-final-deployment-sequence.mmd` | Successful implementation order |
| `11-final-nfs-failure-recovery.mmd` | Recovery decision flow |
| `12-final-security-trust-boundaries.mmd` | Trust boundaries |
