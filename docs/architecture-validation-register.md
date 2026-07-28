# Architecture validation register

| ID | Diagram | Component or connection | Historical evidence | Official reference | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| A-001 | OCI topology | 3 control-plane nodes | Node CLI screenshot | Red Hat Assisted Installer | OBSERVED | Names sanitized |
| A-002 | OCI topology | 3 worker nodes | Node CLI screenshot | Red Hat Assisted Installer | OBSERVED | Names sanitized |
| A-003 | LB flow | TCP 6443 -> control plane | OCI listener screenshot | OCI LB docs | OBSERVED | Backend membership inferred from name and architecture; verify exported LB config |
| A-004 | LB flow | TCP 443 -> workers/router | OCI listener and LB notes | OpenShift Routes / OCI LB | OBSERVED | Router health recovery documented |
| A-005 | LDAP flow | TCP 389 -> NodePort 30089 | OCI listener and `oc get svc` screenshot | Kubernetes NodePort | VERIFIED | Main LDAP path |
| A-006 | NFS | Block Volume -> NFS VM -> `/scratch` | NFS runbook and OCI screenshots | OCI Block Volume | VERIFIED | 1 TB observed |
| A-007 | NFS | export -> NFS CSI | NFS runbook and StorageClass | NFS CSI docs | VERIFIED | NFS 4.1 |
| A-008 | NFS | one `nfs-rwx` StorageClass | final YAML | Kubernetes StorageClass | VERIFIED | Cluster-scoped |
| A-009 | OUD | three OUD replicas | values and retained topology | Kubernetes StatefulSet / Oracle OUD | OBSERVED | Live StatefulSet YAML still desirable |
| A-010 | OUD | separate PVC per replica | StatefulSet/storage model | Kubernetes StatefulSet | VERIFIED design | Runtime PVC listing desirable |
| A-011 | Proxy | two OUD Proxy pods | CLI screenshot | Oracle OUD Proxy | OBSERVED | Running 1/1 |
| A-012 | Proxy | 3 extensions and proportional routes | dsconfig output | Oracle OUD | VERIFIED | Final network-group mapping VERIFY |
| A-013 | OUDSM | one-replica bootstrap then scale | values and troubleshooting notes | Oracle OUDSM | OBSERVED | Exact final count screenshot desirable |
| A-014 | OUDSM | Route -> HTTPS service | values and deployment notes | OpenShift re-encrypt Route | VERIFY | Recover final Route YAML |
| A-015 | LDAPS | 636 -> 30636 | memory/notes | Kubernetes NodePort | VERIFY | Excluded from final confirmed flow |
