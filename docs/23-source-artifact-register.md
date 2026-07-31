# Source artifact register

This register records every major source artifact supplied for the reconstruction.
It distinguishes between material committed to Git and material intentionally
excluded for security, licensing, or confidentiality reasons.

| Source artifact | Repository treatment | Reason |
| --- | --- | --- |
| `OUD Implementarion on OKD on OCI.pptx` | Sanitized PPTX, PDF, transcript, and 17 rendered slides included | First-class project artifact |
| `oud-oci-okd-screenshots.zip` | All 130 images represented by sanitized thumbnails, seven contact sheets, and a SHA-256 manifest | Raw screens contain infrastructure identifiers and access material |
| Screenshot archive SHA-256 | `8a505b96987ac521c654c46b25b72b9623a39714678a796ecfea5bdc9ee9650e` | Proves the catalog corresponds to the supplied archive |
| `Artifacts-To-Be-Created-On-OUD-Kubenates-Cluster(1).doc` | Converted and sanitized to Markdown | Historical capacity and namespace artifact |
| `EDG-for-Oracle-Unified-Directory-in-a-Kubernetes-Cluster.doc` | Converted and sanitized to Markdown | Historical enterprise-deployment working draft |
| `nfs_okd_runbook*.pdf` | Sanitized Markdown runbook included | Original contained real private addressing |
| NFS YAML files | Historical manifests included | Direct implementation artifacts |
| Architecture PNGs | Included under `artifacts/architecture/` | User-created visual artifacts |
| Historical text notes | Sanitized Markdown copies included | Preserves design decisions, commands, and troubleshooting |
| `1 Pre Authenticated Request.txt` | **Excluded** | Contains access material that must never enter Git history |
| OCI Resource Manager raw job log | Summarized elsewhere; raw file excluded | Contains OCIDs and infrastructure identifiers |
| Oracle and Red Hat PDFs | Referenced, not copied | Third-party copyrighted documentation |
| `oci-openshift-1.2.1.zip` | Referenced, not copied | Upstream licensed source should be linked to its canonical repository |

## Publication rule

The project documents everything that was done, but does not publish secrets,
raw access URLs, credentials, customer identifiers, or unredacted cloud metadata.
