# Security and redaction

## Public-evidence policy

Raw source material is not automatically publishable. Many screenshots contain real DNS names, IP addresses, browser sessions, administrative identities, OCI resource identifiers, or customer details.

## Classification

- `SAFE-AS-IS`: no identifying or secret content.
- `CROP-AND-REDACT`: useful evidence after irreversible removal of sensitive areas.
- `RECREATE`: recreate the technical relationship as Mermaid, D2, or draw.io.
- `PRIVATE-ONLY`: retain outside GitHub for personal evidence.
- `REJECT`: contains credentials or cannot be safely transformed.

## Rejected source files

Any notes containing kubeadmin passwords, bearer tokens, Pre-Authenticated Request URLs, or OCIDs are excluded. Treat the exposed credentials as compromised even when believed expired.

## Least privilege

Historical lab deployment used `anyuid` and privileged SCC grants where required by images or the CSI driver. The repository recommends dedicated service accounts and the narrowest SCC that meets the verified requirement.

## Official references

- OpenShift SCCs: <https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html-single/authentication_and_authorization/index>
- Kubernetes Secrets: <https://kubernetes.io/docs/concepts/configuration/secret/>
