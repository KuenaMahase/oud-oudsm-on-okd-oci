# Security and disclosure policy

This repository is a sanitized portfolio reconstruction. Do not open a public issue containing credentials, customer information, internal domains, OCI OCIDs, LDAP data, certificates, or screenshots with browser/session context.

## Prohibited content

- Passwords, API tokens, kubeconfig, pull-secret JSON, private keys, keystores, and truststores.
- OCI tenancy, compartment, resource, job, volume, image, VCN, subnet, load-balancer, or DNS OCIDs.
- Real customer names, domains, suffixes, hostnames, addresses, usernames, or ticket identifiers.
- Pre-Authenticated Request URLs and Object Storage namespace details.
- Real LDAP entries or LDIF exports.

Run before every commit:

```bash
bash scripts/security/scan-sensitive-data.sh
```

Report sensitive findings privately to the repository owner. Do not paste the secret into the report.
