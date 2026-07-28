# Validation

## Status model

Scripts use four outcomes:

- `PASS`: the check ran and succeeded.
- `FAIL`: the check ran and failed.
- `VERIFY`: required input or historical proof is missing.
- `SKIPPED`: deliberately not executed in the current environment.

## Historical validation evidence

- OCI Resource Manager initialized Terraform and managed resources.
- Six cluster nodes were observed Ready.
- Applications and API listeners were observed.
- The LDAP listener and NodePort Service were observed.
- NFS CSI created a PVC directory and the test pod read `hello-from-nfs`.
- Two OUD Proxy pods were observed Running.
- Proxy extensions and proportional routing elements were listed through `dsconfig`.

## Public execution evidence

![Sanitized NFS CSI smoke test](../evidence/sanitized/01-nfs-csi-smoke-test-sanitized.png)

This capture supports the NFS CSI smoke-test claim only. It does not establish final OUD or OUDSM runtime state.

## Validation commands

```bash
bash scripts/validation/validate-prerequisites.sh
bash scripts/validation/validate-cluster.sh
bash scripts/validation/validate-nfs-csi.sh
bash scripts/validation/validate-storageclass.sh
bash scripts/validation/validate-pvcs.sh
bash scripts/validation/validate-oud.sh
bash scripts/validation/validate-oud-proxy.sh
bash scripts/validation/validate-oudsm.sh
```

## Evidence capture

Use structured text rather than unreviewed screenshots where possible:

```bash
mkdir -p /tmp/oud-evidence
oc get nodes -o wide > /tmp/oud-evidence/nodes.txt
oc get sc nfs-rwx -o yaml > /tmp/oud-evidence/storageclass.yaml
oc get pods,svc,pvc -n oudns -o wide > /tmp/oud-evidence/oud-resources.txt
oc get pods,svc,pvc,route -n oudsmns -o wide > /tmp/oud-evidence/oudsm-resources.txt
```

Review and sanitize every file before moving it into `evidence/sanitized/`.

## Official references

- `kubectl rollout status`: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/kubectl_rollout_status/
- Kubernetes self-healing: https://kubernetes.io/docs/concepts/architecture/self-healing/
