# Oracle OUD and OUDSM on OKD/OpenShift in OCI

[![Documentation checks](https://github.com/KuenaMahase/oud-oudsm-on-okd-oci/actions/workflows/docs.yml/badge.svg?branch=main)](https://github.com/KuenaMahase/oud-oudsm-on-okd-oci/actions/workflows/docs.yml)
[![Mermaid validation](https://github.com/KuenaMahase/oud-oudsm-on-okd-oci/actions/workflows/mermaid.yml/badge.svg?branch=main)](https://github.com/KuenaMahase/oud-oudsm-on-okd-oci/actions/workflows/mermaid.yml)
[![Redaction checks](https://github.com/KuenaMahase/oud-oudsm-on-okd-oci/actions/workflows/security.yml/badge.svg?branch=main)](https://github.com/KuenaMahase/oud-oudsm-on-okd-oci/actions/workflows/security.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **MaseruTel Enterprise Systems Lab** — a sanitized portfolio reconstruction of a successfully deployed Oracle directory-services platform on OKD/OpenShift in Oracle Cloud Infrastructure.

I provisioned an OCI-hosted OKD/OpenShift cluster, prepared NFS CSI-backed persistent storage, deployed Oracle Unified Directory, configured OUD Proxy routing, and deployed OUDSM with a persistent WebLogic domain. This repository is evidence-led: retained logs, commands, manifests, and screenshots establish what was implemented, while official vendor documentation explains the underlying platform behavior.

| Platform | Directory tier | Documentation |
| --- | --- | --- |
| 6-node OKD cluster (3 control-plane, 3 workers) | 3 OUD directory-server replicas | 28 documentation pages |
| 3 separated OCI load balancers | 2 OUD Proxy pods, 3 LDAP extensions | 12 architecture diagrams |
| 1 TB OCI Block Volume via NFSv4.1 | 1 OUDSM WebLogic domain | 15 validation scripts |
| 1 cluster-scoped `nfs-rwx` StorageClass | 4 dynamically provisioned PVCs | 130 catalogued screenshots |

> [!IMPORTANT]
> All names, domains, IP addresses, suffixes, credentials, OCIDs, and customer references are sanitized. Confidential source artifacts are intentionally excluded.

## Architecture at a glance

The diagram below is generated from [`diagrams/mermaid/01-final-platform-context.mmd`](diagrams/mermaid/01-final-platform-context.mmd). Do not edit it by hand — edit the source and run `python3 scripts/rendering/build-mermaid-gallery.py`.

<!-- BEGIN GENERATED: 01-final-platform-context -->

```mermaid
flowchart LR
    A[Platform administrator] -->|oc / browser| OCI[OCI entry points]
    L[LDAP and LDAPS clients] --> OCI

    subgraph VCN[OCI VCN - sanitized]
      OCI --> OKD[OKD / OpenShift cluster]
      BV[OCI Block Volume] --> NFS[Oracle Linux NFS server]
      NFS --> CSI[NFS CSI driver]
    end

    subgraph OUDNS[Namespace: oudns]
      PROXY[OUD Proxy - 2 observed pods]
      DS0[OUD DS 0]
      DS1[OUD DS 1]
      DS2[OUD DS 2]
      PROXY --> DS0
      PROXY --> DS1
      PROXY --> DS2
      DS0 <-. OUD replication .-> DS1
      DS1 <-. OUD replication .-> DS2
    end

    subgraph OUDSMNS[Namespace: oudsmns]
      OUDSM[OUDSM / WebLogic domain]
    end

    OKD --> PROXY
    OKD --> OUDSM
    OUDSM -->|administration connector| DS0
    CSI -->|dynamic PVs / PVCs| DS0
    CSI -->|dynamic PVs / PVCs| DS1
    CSI -->|dynamic PVs / PVCs| DS2
    CSI -->|dedicated PVC| OUDSM
```

<!-- END GENERATED: 01-final-platform-context -->

## Storage path

Dynamic provisioning was the prerequisite for every Oracle workload here, and it is the part of the build with the strongest retained evidence. One cluster-scoped StorageClass serves all four PVCs; each replica receives its own NFS subdirectory.

<!-- BEGIN GENERATED: 05-final-nfs-csi-storage-flow -->

```mermaid
flowchart LR
    BV[(OCI Block Volume\n1 TB observed)] -->|mounted at /scratch| VM[Oracle Linux 9 NFS VM]
    VM --> EXPORT[NFS export\n/scratch/shared/oud_user_projects]
    EXPORT -->|NFSv4.1| CSI[NFS CSI driver\nnfs.csi.k8s.io]
    CSI --> SC[StorageClass nfs-rwx\ncluster-scoped\nRetain / Immediate]

    SC --> P0[PVC for OUD DS 0]
    SC --> P1[PVC for OUD DS 1]
    SC --> P2[PVC for OUD DS 2]
    SC --> PS[PVC for OUDSM]

    P0 --> D0[(pvc-specific NFS subdirectory)]
    P1 --> D1[(pvc-specific NFS subdirectory)]
    P2 --> D2[(pvc-specific NFS subdirectory)]
    PS --> DS[(pvc-specific NFS subdirectory)]

    D0 --> O0[OUD DS 0]
    D1 --> O1[OUD DS 1]
    D2 --> O2[OUD DS 2]
    DS --> SM[OUDSM]
```

<!-- END GENERATED: 05-final-nfs-csi-storage-flow -->

## Diagram index

All twelve diagrams render on GitHub in the [gallery](diagrams/GALLERY.md); the `.mmd` files are the authoritative sources.

| # | Diagram | Source |
| --- | --- | --- |
| 1 | Final platform context | [`01-final-platform-context.mmd`](diagrams/mermaid/01-final-platform-context.mmd) |
| 2 | OCI network topology | [`02-final-oci-network-topology.mmd`](diagrams/mermaid/02-final-oci-network-topology.mmd) |
| 3 | OKD/OpenShift cluster topology | [`03-final-okd-cluster-topology.mmd`](diagrams/mermaid/03-final-okd-cluster-topology.mmd) |
| 4 | Load-balancer and ingress flows | [`04-final-load-balancer-and-ingress-flow.mmd`](diagrams/mermaid/04-final-load-balancer-and-ingress-flow.mmd) |
| 5 | NFS CSI storage flow | [`05-final-nfs-csi-storage-flow.mmd`](diagrams/mermaid/05-final-nfs-csi-storage-flow.mmd) |
| 6 | OUD StatefulSet and storage | [`06-final-oud-statefulset-storage.mmd`](diagrams/mermaid/06-final-oud-statefulset-storage.mmd) |
| 7 | OUD replication topology | [`07-final-oud-replication-topology.mmd`](diagrams/mermaid/07-final-oud-replication-topology.mmd) |
| 8 | OUD Proxy routing | [`08-final-oud-proxy-routing.mmd`](diagrams/mermaid/08-final-oud-proxy-routing.mmd) |
| 9 | OUDSM access flow | [`09-final-oudsm-access-flow.mmd`](diagrams/mermaid/09-final-oudsm-access-flow.mmd) |
| 10 | Successful deployment sequence | [`10-final-deployment-sequence.mmd`](diagrams/mermaid/10-final-deployment-sequence.mmd) |
| 11 | NFS failure recovery | [`11-final-nfs-failure-recovery.mmd`](diagrams/mermaid/11-final-nfs-failure-recovery.mmd) |
| 12 | Security trust boundaries | [`12-final-security-trust-boundaries.mmd`](diagrams/mermaid/12-final-security-trust-boundaries.mmd) |

Rendered SVG copies live in [`diagrams/rendered/svg/`](diagrams/rendered/svg/). They are produced by CI for offline and print use; GitHub strips the `foreignObject` elements Mermaid emits, so the fenced blocks above are the correct way to view them in the browser.

## What this project demonstrates

- OCI Resource Manager and Terraform-based cluster infrastructure provisioning evidence.
- A six-node OKD/OpenShift cluster with three control-plane and three worker nodes.
- OCI load-balancer separation for Kubernetes API, application ingress, and LDAP traffic.
- An Oracle Linux NFS server backed by a 1 TB OCI Block Volume.
- NFS CSI dynamic provisioning through one cluster-scoped `nfs-rwx` StorageClass.
- Three OUD directory-server replicas with separate PVC-backed data directories.
- Two OUD Proxy pods with LDAP server extensions and proportional routing to three OUD endpoints.
- OUDSM initialized safely with one replica and subsequently scaled after domain readiness.
- Failure diagnosis across OCI networking, OpenShift ingress, SCCs, CSI, NFS, Helm, OUD Proxy, and OUDSM.

## Evidence status

Claims are graded rather than asserted uniformly. Nothing was promoted to verified without a retained artifact behind it.

| | Area | Status | Summary |
| --- | --- | --- | --- |
| ✅ | OCI Resource Manager | Verified | Retained job log shows provider initialization and OCI resource refresh/create operations. |
| 🔍 | Cluster topology | Observed | Screenshots show three control-plane and three worker nodes ready. |
| ✅ | NFS CSI | Verified | Test PVC and pod wrote and read `hello-from-nfs`; a dynamic `pvc-*` directory was observed on the server. |
| ✅ | OUD storage | Verified design, partial runtime evidence | One StorageClass, namespaced PVCs, separate directories per replica. |
| 🔍 | OUD Proxy | Verified in part | Two pods, public LDAP NodePort `30089`, three LDAP extensions, and proportional routes were observed. Final network-group mapping remains `VERIFY` until the completion output is recovered. |
| 🔍 | OUDSM | Observed and reconstructed | Image/values and UI evidence exist; exact final Route target and PVC capacity remain in the verify register. |
| ⚠️ | LDAPS external path | Verify | Do not treat the remembered `636 -> 30636` path as final until listener and Service evidence is recovered. |

Legend: ✅ verified against a retained artifact · 🔍 observed but not fully reproducible · ⚠️ unresolved, tracked in the [verify register](docs/verify-register.md).

## Selected execution evidence

The repository includes only evidence that survived both relevance and sanitization review. This historical capture shows the successful NFS CSI smoke test used before deploying the Oracle workloads.

![Sanitized NFS CSI smoke test](evidence/sanitized/01-nfs-csi-smoke-test-sanitized.png)

See the [evidence policy](evidence/README.md) for artifacts that were recreated, rejected, or kept private.

## Platform overview

![OUD on OKD on OCI platform infographic](artifacts/architecture/oud-okd-oci-platform-infographic.png)

## Start here

1. [Project overview](docs/00-project-overview.md)
2. [Recovered deployment contract](docs/02-recovered-deployment-contract.md)
3. [Successful deployment runbook](docs/03-oci-foundation.md)
4. [NFS and dynamic storage](docs/06-nfs-server-and-block-volume.md)
5. [OUD deployment](docs/09-oud-helm-deployment.md)
6. [OUD Proxy routing](docs/10-oud-proxy-deployment.md)
7. [OUDSM deployment](docs/11-oudsm-helm-deployment.md)
8. [Validation](docs/13-validation.md)
9. [Troubleshooting and recovery](docs/14-troubleshooting-and-recovery.md)
10. [Operations command reference](docs/19-operations-command-reference.md)

## Repository map

```text
README.md                 Project landing page and verified architecture summary
docs/                     Evidence-led deployment and recovery documentation
diagrams/                 Mermaid-first diagram sources, D2 and draw.io sources
manifests/                Sanitized Kubernetes and OpenShift examples
helm/                     Sanitized values and chart applicability notes
scripts/validation/       Safe PASS/FAIL/VERIFY/SKIPPED checks
scripts/security/         Redaction and secret scanning
evidence/                 Public evidence policy; confidential originals excluded
reference/terraform/      Clearly labelled reference material, not claimed as original code
```

## Reproduction scope

This is a historical reconstruction, not a currently hosted public service. The repository provides the successful implementation sequence, sanitized manifests, architecture sources, validation commands, and operational lessons. Commands that could not be rerun against the retired historical environment are labelled `VERIFY` or `SKIPPED` rather than reported as passing.

## What I personally implemented

I worked across OCI provisioning, OKD/OpenShift installation and access, load-balancer troubleshooting, NFS server and CSI integration, Oracle image and Helm preparation, OUD deployment, OUD Proxy configuration, OUDSM deployment, and end-to-end validation. Oracle supplied the product images and Helm charts; Red Hat/OpenShift supplied the cluster platform; AI assisted with reconstruction, comparison, and documentation, but unsupported claims were not promoted to verified facts.

## Security

Read [SECURITY.md](SECURITY.md) and [the redaction policy](docs/15-security-and-redaction.md) before adding evidence. Never commit credentials, customer identifiers, OCIDs, private hostnames, real IP addresses, LDAP data, keystores, pull secrets, or raw browser screenshots without review.

Every pull request runs `scripts/security/scan-sensitive-data.sh`, which blocks known historical identifiers, secret patterns, and sensitive file types.

## Official documentation

The major documents link to the applicable Oracle, Red Hat/OpenShift, Kubernetes, Kubernetes NFS CSI, and OCI references. See [references.md](docs/references.md).

## Historical artifacts and work evidence

- [Complete implementation history](docs/20-complete-implementation-history.md)
- [Presentation transcript](docs/21-presentation-transcript.md)
- [Work evidence gallery](docs/22-work-evidence-gallery.md)
- [Source artifact register](docs/23-source-artifact-register.md)
- [Sanitized PowerPoint deck](artifacts/presentation/OUD-Implementation-on-OKD-on-OCI-sanitized.pptx)
- [Sanitized PDF deck](artifacts/presentation/OUD-Implementation-on-OKD-on-OCI-sanitized.pdf)

The raw screenshot archive and access-bearing source files remain offline.
All 130 screenshots are represented through sanitized thumbnails, contact
sheets, filenames, and SHA-256 hashes.
