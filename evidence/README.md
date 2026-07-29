# Public evidence policy

Only sanitized evidence may be committed. Raw screenshots and logs remain outside this repository when they contain real hostnames, IP addresses, OCIDs, customer names, administrative identities, browser/session data, tokens, or credentials.

## Included evidence

| File | What it proves | Treatment |
|---|---|---|
| `sanitized/01-nfs-csi-smoke-test-sanitized.png` | NFS CSI controller/node components were Running and the test pod read `hello-from-nfs` | Cropped, identity removed, unsuccessful typo omitted |

## Excluded or recreated evidence

- OCI load-balancer, DNS, subnet, and instance screenshots: **RECREATE** as Mermaid/draw.io because they contain real infrastructure identifiers.
- Node and service terminal screenshots: **RECREATE** because safe redaction would destroy too much context.
- OUDSM screenshots labelled with a local Minikube connection: **REJECT for this repository** because they are not proof of the OCI/OKD deployment.
- Credential, token, kubeconfig, and Object Storage access notes: **REJECT / PRIVATE-ONLY**.
- Early `nfs-csi` StorageClass screenshots using `Delete`: **HISTORICAL**, not the final `nfs-rwx`/`Retain` configuration.

Prefer structured, reviewed command output and recreated diagrams. Every public artifact must state the exact claim it supports.
