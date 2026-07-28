# Troubleshooting and recovery

## NFS mount failure after reboot

**Symptom:** PVC-consuming pods stopped mounting storage.

**Evidence:** NFS service/export checks and block-device inspection showed `/scratch` was not mounted.

**Root cause:** The block-volume filesystem was not reliably mounted before NFS startup.

**Final correction:** Repair the UUID-based `/etc/fstab` entry, run `mount -a`, validate with `findmnt --verify`, reload exports, and restart NFS.

## PVC Pending

```bash
oc describe pvc -n <namespace> <pvc>
oc get events -n <namespace> --sort-by=.lastTimestamp
oc get sc nfs-rwx -o yaml
oc get pods -n openshift-csi-driver-nfs-namespace -o wide
getent hosts nfs01.lab.example
nc -vz nfs01.lab.example 2049
```

Check StorageClass name, CSI controller, DNS, TCP 2049, export path, and permissions.

## Pod ContainerCreating

```bash
oc describe pod -n <namespace> <pod>
oc get events -n <namespace> --field-selector involvedObject.name=<pod>
oc adm policy scc-subject-review -f <rendered-pod-or-workload.yaml>
```

Check mount errors, UID/GID, `fsGroup`, SCC admission, and server-side ownership.

## ImagePullBackOff

```bash
oc describe pod -n <namespace> <pod> | sed -n '/Events:/,$p'
oc get sa -n <namespace> <service-account> -o yaml
oc get secret -n <namespace>
```

Confirm every init container, hook, sidecar, and job has registry access.

## Load-balancer backends unhealthy

```bash
oc get pods -n openshift-ingress -o wide
oc get endpointslices -n openshift-ingress
oci lb backend-set-health get --load-balancer-id "$LB_OCID"   --backend-set-name "$BACKEND_SET"
```

Match health-check protocol, port, and URI to the target. Confirm router replicas actually exist on backend workers.

## OUDSM duplicate YAML key

A duplicate top-level `oudsm:` block caused earlier settings to be overwritten by the later block. Parse YAML and inspect the rendered Helm output before installation.

```bash
python3 - <<'PY_CHECK'
import yaml
with open('helm/oudsm/values.example.yaml', encoding='utf-8') as f:
    data = yaml.safe_load(f)
print(sorted(data))
PY_CHECK
helm template oudsm <chart> -f helm/oudsm/values.example.yaml > /tmp/oudsm.yaml
```

## OUD Proxy workflow incomplete

A proxy can accept a bind yet return no-such-object when no workflow maps the requested base DN to the load-balancing workflow. Inspect extensions, workflows, network groups, and workflow elements as separate objects.

## Official references

- OpenShift troubleshooting and SCC concepts: https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html-single/authentication_and_authorization/index
- NFS CSI troubleshooting: https://github.com/kubernetes-csi/csi-driver-nfs
- OCI health checks: https://docs.oracle.com/iaas/Content/Balance/Tasks/load_balancer_health_management.htm
