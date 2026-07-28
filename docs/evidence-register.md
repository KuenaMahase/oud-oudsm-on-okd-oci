# Evidence register

| ID | Artifact | What it proves | Sensitivity | Classification | Public action | Confidence |
|---|---|---|---|---|---|---|
| E-001 | OCI Resource Manager job log, June 2025 | Terraform initialized and OCI cluster/network resources were managed | Contains OCIDs and tenancy details | VERIFIED | Summarize only; original private | High |
| E-002 | Original OKD/OCI presentation | Project intent, Assisted Installer flow, early architecture and cluster access narrative | Contains historical cluster naming | OBSERVED | Recreate diagrams | Medium |
| E-003 | Node CLI screenshots | Three control-plane and three worker nodes Ready | Contains real node names and IPs | OBSERVED | Recreate as Mermaid; original private | High |
| E-004 | OCI LB listeners screenshot | TCP listeners 6443, 443 and 389 and associated backend sets | Contains real LB name and OCID in URL | OBSERVED | Recreate and describe | High |
| E-005 | LDAP NodePort screenshot | `oud-proxy-ldap-public`, 389:30089, two proxy pods | Contains node names and addresses | OBSERVED | Recreate and describe | High |
| E-006 | NFS runbook | OL9 VM, 1 TB block volume, export, CSI installation, successful test pod | Contains real addresses and FQDN | VERIFIED | Sanitized runbook | High |
| E-007 | `nfs-sc.yaml` | Final `nfs-rwx`, NFS CSI, Retain, Immediate, NFS 4.1 | Contains private DNS | VERIFIED | Commit sanitized version | High |
| E-008 | OUD values note | Three replicas, image tag, ports, persistence and security context | Contains customer suffix and password | OBSERVED | Sanitized reconstruction; chart schema VERIFY | Medium |
| E-009 | OUD Proxy dsconfig output | Three extensions, three proxy workflows, `lb-we`, proportional routes | Contains suffix and plaintext password in later snippet | VERIFIED in part | Sanitized procedure; original private | High |
| E-010 | OUDSM values note | Image tag, SA, ports, PVC, one-replica bootstrap | Contains OCIR namespace and password | OBSERVED | Sanitized values | High |
| E-011 | OpenShift and OUDSM screenshot collection | Mixed OCI/OKD, local Minikube, and documentation captures | Real domains, identities, IPs, and mixed environments | MIXED | Select individually; most recreate or reject | Medium |
| E-014 | Sanitized NFS CSI smoke-test capture | CSI components Running and `hello-from-nfs` read-back | Identity removed; no infrastructure identifiers retained | VERIFIED | Commit under `evidence/sanitized/` | High |
| E-015 | OUDSM screenshot labelled with a Minikube connection | OUDSM functionality in a separate local lab | Different environment from OCI/OKD project | REJECTED for final architecture | Exclude | High |
| E-012 | Credential and PAR notes | Contains secrets and access material | Critical | REJECTED | Never commit; revoke/invalidate | High |
| E-013 | Generic traffic-flow note | Proposed Route-based LDAP design | May not match final deployment | REJECTED for final architecture | Historical lesson only | Low |
