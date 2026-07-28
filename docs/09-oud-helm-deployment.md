# OUD Helm deployment

## Successful implementation

The recovered configuration records three OUD replicas, Oracle's OUD CPU image, LDAP `1389`, LDAPS `1636`, administration `1444`, replication `1898`, persistent PVCs using `nfs-rwx`, and a pod security context aligned with NFS ownership.

## Important evidence rule

The uploaded values file contains fields that must be validated against the exact `fmw-kubernetes` chart revision before reuse. The sanitized file in `helm/oud/values.example.yaml` is therefore marked as a recovered configuration, not a universal chart schema.

## Deployment sequence

```bash
oc new-project oudns
oc create serviceaccount oud-sa -n oudns

# Grant only the SCC required by the actual image and storage behavior.
oc adm policy add-scc-to-user anyuid -z oud-sa -n oudns

# Inspect chart defaults before installing.
helm show chart <path-to-oud-chart>
helm show values <path-to-oud-chart> > /tmp/oud-default-values.yaml
helm lint <path-to-oud-chart> -f helm/oud/values.example.yaml
helm template oud-ds-rs <path-to-oud-chart>   -n oudns -f helm/oud/values.example.yaml > /tmp/oud-rendered.yaml

# Server-side validation catches API/schema errors without creating resources.
oc apply --dry-run=server -f /tmp/oud-rendered.yaml

helm upgrade --install oud-ds-rs <path-to-oud-chart>   -n oudns -f helm/oud/values.example.yaml   --wait --timeout 30m
```

## Smooth-deployment checks

```bash
helm list -n oudns
helm get values oud-ds-rs -n oudns --all
helm get manifest oud-ds-rs -n oudns > /tmp/oud-live-manifest.yaml
oc get statefulset,pods,svc,pvc -n oudns -o wide
oc rollout status statefulset/<oud-statefulset> -n oudns --timeout=20m
oc get events -n oudns --sort-by=.lastTimestamp | tail -100
```

## Replication and LDAP validation

```bash
# Root DSE without credentials
ldapsearch -x -H ldap://127.0.0.1:1389 -s base -b '' namingContexts

# Product status from a pod
oc exec -n oudns <oud-pod> -- /u01/oracle/oud/bin/status

# Use a protected password file for dsconfig / dsreplication; never place it in shell history.
oc exec -n oudns <oud-pod> -- /u01/oracle/oud/bin/dsreplication status   --hostname localhost --port 1444   --adminUID admin --adminPasswordFile /path/to/mounted/password-file   --trustAll --no-prompt
```

`--trustAll` is acceptable only for controlled lab validation and should be replaced with managed trust in a hardened environment.

## Official references

- Oracle OUD Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudku/
- Oracle `fmw-kubernetes`: https://github.com/oracle/fmw-kubernetes
- Kubernetes StatefulSets: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
