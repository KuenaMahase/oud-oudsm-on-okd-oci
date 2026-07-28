# Operations command reference

These commands are intended to make a future deployment and incident investigation smoother. They are **operational helpers from official product documentation and platform practice**; their inclusion does not claim that every command was run during the historical deployment.

Replace placeholders before execution. Never paste credentials into shell history.

## 1. Fast cluster preflight

```bash
oc whoami
oc whoami --show-server
oc version
oc get clusterversion
oc get nodes -o wide
oc get clusteroperators
oc get infrastructure cluster -o yaml
oc get network.config.openshift.io cluster -o yaml
oc get ingresscontroller default -n openshift-ingress-operator -o yaml
```

Quickly isolate unhealthy objects:

```bash
oc get pods -A \
  --field-selector=status.phase!=Running,status.phase!=Succeeded
oc get events -A --sort-by=.lastTimestamp | tail -200
oc get nodes -o custom-columns=NAME:.metadata.name,READY:.status.conditions[-1].status,TAINTS:.spec.taints
oc adm top nodes
oc adm top pods -A --sort-by=memory
```

`oc adm top` requires metrics to be available.

## 2. API discovery and schema checks

Use these before writing manifests against an unfamiliar cluster or chart version:

```bash
oc api-resources | sort
oc api-versions | sort
oc explain statefulset.spec.volumeClaimTemplates
oc explain storageclass.parameters
oc explain route.spec.tls
oc explain securitycontextconstraints
```

## 3. RBAC and SCC preflight

```bash
oc auth can-i create statefulsets.apps -n oudns
oc auth can-i create persistentvolumeclaims -n oudns
oc auth can-i create routes.route.openshift.io -n oudsmns
oc auth can-i use scc/anyuid \
  --as system:serviceaccount:oudns:oud-sa
oc adm policy who-can use scc/anyuid
oc adm policy scc-subject-review -f /tmp/rendered-workload.yaml
oc describe scc anyuid
```

Prefer a dedicated service account and the narrowest suitable SCC. Do not grant `anyuid` to every service account in a namespace merely for convenience.

## 4. Helm preflight, installation, and recovery

```bash
helm version
helm env
helm list -A
helm show chart <chart>
helm show values <chart> > /tmp/default-values.yaml
helm lint <chart> -f values.yaml
helm template <release> <chart> \
  -n <namespace> -f values.yaml > /tmp/rendered.yaml
oc apply --dry-run=server -f /tmp/rendered.yaml
```

Inspect rendered security and storage before installing:

```bash
yq '. | select(.kind == "StatefulSet" or .kind == "Deployment") |
    {kind, name: .metadata.name,
     serviceAccount: .spec.template.spec.serviceAccountName,
     securityContext: .spec.template.spec.securityContext,
     volumes: .spec.template.spec.volumes}' /tmp/rendered.yaml

grep -nE 'storageClassName|volumeClaimTemplates|runAsUser|fsGroup|imagePullSecrets' \
  /tmp/rendered.yaml
```

Install and inspect:

```bash
helm upgrade --install <release> <chart> \
  -n <namespace> -f values.yaml \
  --wait --timeout 30m
helm status <release> -n <namespace>
helm history <release> -n <namespace>
helm get values <release> -n <namespace> --all
helm get manifest <release> -n <namespace> > /tmp/<release>-manifest.yaml
helm get hooks <release> -n <namespace>
```

Recovery:

```bash
helm rollback <release> <revision> -n <namespace> --wait --timeout 20m
```

Use `--atomic` only when automatic rollback matches the operational intent. It can remove failed-install resources that would otherwise help root-cause analysis.

## 5. NFS server and filesystem preflight

Run on the NFS VM:

```bash
sudo lsblk -f
sudo blkid
findmnt /scratch
findmnt --verify --verbose
sudo mount -a
findmnt /scratch
sudo df -hT /scratch
sudo stat -c '%U:%G %a %n' /scratch/shared/oud_user_projects
```

Validate exports and services:

```bash
sudo exportfs -rav
sudo exportfs -v
sudo systemctl status nfs-server --no-pager
sudo journalctl -u nfs-server -b --no-pager | tail -200
sudo ss -lntup | grep -E ':(111|2049|20048)\b'
sudo rpcinfo -p localhost
```

Check boot ordering after modifying `/etc/fstab`:

```bash
systemctl list-dependencies nfs-server.service
systemctl status remote-fs.target nfs-server.service --no-pager
sudo systemd-analyze verify /etc/fstab
```

`systemd-analyze verify /etc/fstab` is not supported identically on every distribution; `findmnt --verify` is the more portable first check.

From an OpenShift worker debug shell or administrative host:

```bash
showmount -e nfs01.lab.example
rpcinfo -p nfs01.lab.example
nc -vz nfs01.lab.example 2049
```

## 6. NFS CSI and dynamic provisioning

```bash
oc get csidrivers
oc get storageclasses
oc get sc nfs-rwx -o yaml
oc get pods -n openshift-csi-driver-nfs-namespace -o wide
oc get daemonsets,deployments \
  -n openshift-csi-driver-nfs-namespace
oc get events -n openshift-csi-driver-nfs-namespace \
  --sort-by=.lastTimestamp | tail -100
```

PVC and PV investigation:

```bash
oc get pvc -A
oc get pv
oc describe pvc -n <namespace> <pvc>
oc get pv <pv> -o yaml
oc get volumeattachments.storage.k8s.io
oc get events -n <namespace> --field-selector involvedObject.kind=PersistentVolumeClaim
```

Run a disposable smoke test before installing OUD:

```bash
oc apply -f manifests/storage/nfs-test-pvc.yaml
oc apply -f manifests/storage/nfs-test-pod.yaml
oc wait --for=condition=Ready pod/nfs-test-pod \
  -n openshift-csi-driver-nfs-namespace --timeout=5m
oc exec -n openshift-csi-driver-nfs-namespace nfs-test-pod -- \
  cat /data/hello
```

Expected retained historical value:

```text
hello-from-nfs
```

## 7. Workload rollout and pod inspection

```bash
oc get statefulsets,deployments -n <namespace>
oc rollout status statefulset/<name> -n <namespace> --timeout=20m
oc rollout status deployment/<name> -n <namespace> --timeout=20m
oc rollout history deployment/<name> -n <namespace>
oc wait --for=condition=Ready pod -l <label-selector> \
  -n <namespace> --timeout=20m
```

Inspect placement, container state, and previous failures:

```bash
oc get pod -n <namespace> <pod> \
  -o jsonpath='{.spec.nodeName}{"\n"}'
oc get pod -n <namespace> <pod> \
  -o jsonpath='{range .status.containerStatuses[*]}{.name}{" ready="}{.ready}{" restarts="}{.restartCount}{" imageID="}{.imageID}{"\n"}{end}'
oc describe pod -n <namespace> <pod>
oc logs -n <namespace> <pod> --all-containers --prefix --tail=200
oc logs -n <namespace> <pod> --all-containers --previous --tail=200
```

Node-level troubleshooting:

```bash
oc debug node/<node-name>
chroot /host
journalctl -u kubelet -b --no-pager | tail -200
mount | grep -E ' type nfs4? '
exit
```

## 8. Services, EndpointSlices, Routes, and ingress

```bash
oc get svc,endpoints,endpointslices -n <namespace>
oc describe svc -n <namespace> <service>
oc get endpointslice -n <namespace> \
  -l kubernetes.io/service-name=<service> -o yaml
oc get route -n <namespace> -o wide
oc get route -n <namespace> <route> -o yaml
```

Ingress router checks:

```bash
oc get ingresscontroller default -n openshift-ingress-operator -o yaml
oc get pods -n openshift-ingress -o wide
oc get svc -n openshift-ingress
oc get endpointslices -n openshift-ingress
oc logs -n openshift-ingress -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default \
  --tail=200 --prefix
```

For an external load balancer in front of the OpenShift router, validate the router readiness endpoint used by the deployed endpoint publishing strategy. OpenShift documents `/healthz/ready` on the health-check port, commonly `1936` for host-network publishing.

```bash
curl -fsS http://<worker-or-router-endpoint>:1936/healthz/ready
```

Do not assume this port or path without checking the IngressController status and the version-specific Red Hat documentation.

## 9. DNS and in-cluster service discovery

```bash
oc run dns-check --rm -it --restart=Never \
  --image=registry.access.redhat.com/ubi9/ubi-minimal -- sh
```

Inside the disposable pod:

```bash
cat /etc/resolv.conf
getent hosts kubernetes.default.svc
getent hosts <service>.<namespace>.svc.cluster.local
```

Inspect cluster DNS:

```bash
oc get dns.operator/default -o yaml
oc get configmap/dns-default -n openshift-dns -o yaml
oc get pods -n openshift-dns -o wide
```

## 10. OCI Resource Manager evidence and diagnostics

```bash
oci resource-manager job get --job-id "$JOB_OCID"
oci resource-manager job get-job-logs \
  --job-id "$JOB_OCID" --all > job-logs.json
oci resource-manager job get-job-logs-content \
  --job-id "$JOB_OCID" --file job.log
oci resource-manager job-output-summary list-job-outputs \
  --job-id "$JOB_OCID" --all
```

Review a plan before applying it:

```bash
jq -r '.data[]?.message // empty' job-logs.json | less
```

Never commit the unredacted log; Resource Manager logs commonly contain OCIDs and environment names.

## 11. OCI load-balancer diagnostics

```bash
oci lb load-balancer-health get --load-balancer-id "$LB_OCID"
oci lb backend-set list --load-balancer-id "$LB_OCID" --all
oci lb backend-set-health get \
  --load-balancer-id "$LB_OCID" \
  --backend-set-name "$BACKEND_SET"
oci lb health-checker get \
  --load-balancer-id "$LB_OCID" \
  --backend-set-name "$BACKEND_SET"
oci lb backend get \
  --load-balancer-id "$LB_OCID" \
  --backend-set-name "$BACKEND_SET" \
  --backend-name "$BACKEND_IP:$BACKEND_PORT"
oci lb backend-health get \
  --load-balancer-id "$LB_OCID" \
  --backend-set-name "$BACKEND_SET" \
  --backend-name "$BACKEND_IP:$BACKEND_PORT"
```

List listeners to verify that frontend ports target the intended backend sets:

```bash
oci lb listener list --load-balancer-id "$LB_OCID" --all
```

## 12. OUD deployment inspection

```bash
oc get statefulset,pods,svc,pvc -n oudns -o wide
oc get events -n oudns --sort-by=.lastTimestamp | tail -100
oc logs -n oudns <oud-pod> --all-containers --tail=200
oc get pod -n oudns <oud-pod> \
  -o jsonpath='{range .status.containerStatuses[*]}{.name}{" image="}{.image}{" imageID="}{.imageID}{"\n"}{end}'
```

Root-DSE connectivity:

```bash
oc exec -n oudns <oud-pod> -- \
  ldapsearch -x -H ldap://localhost:1389 -s base -b '' namingContexts
```

Do not place directory passwords directly on the command line. Use a protected password file or an interactive prompt.

## 13. OUD replication validation

Oracle documents `dsreplication status` from inside an OUD pod. Adapt the instance path to the actual release and pod name:

```bash
oc exec -it -n oudns -c oud-ds-rs <oud-pod> -- bash
```

Inside the pod:

```bash
read -rsp 'Replication administrator password: ' ADMIN_PASSWORD; echo
printf '%s' "$ADMIN_PASSWORD" > /tmp/admin-password
chmod 600 /tmp/admin-password
unset ADMIN_PASSWORD

/u01/oracle/user_projects/<pod-name>/OUD/bin/dsreplication status \
  --trustAll \
  --hostname <pod-name> \
  --port 1444 \
  --adminUID admin \
  --adminPasswordFile /tmp/admin-password \
  --dataToDisplay compat-view \
  --dataToDisplay rs-connections

rm -f /tmp/admin-password
```

`--trustAll` is convenient in a lab but weakens certificate validation. Prefer a managed truststore for long-lived environments.

## 14. OUD Proxy inspection

```bash
oc get pods,svc -n oudns -l app.kubernetes.io/name=oud-proxy -o wide
oc describe svc -n oudns oud-proxy-ldap-public
```

Inside a proxy pod, after creating a protected password file:

```bash
DS=/u01/oracle/oud/bin/dsconfig
"$DS" -h localhost -p 1444 -D 'cn=Directory Manager' \
  -j /tmp/oud-password -X -n list-extensions
"$DS" -h localhost -p 1444 -D 'cn=Directory Manager' \
  -j /tmp/oud-password -X -n list-workflow-elements
"$DS" -h localhost -p 1444 -D 'cn=Directory Manager' \
  -j /tmp/oud-password -X -n list-workflows
"$DS" -h localhost -p 1444 -D 'cn=Directory Manager' \
  -j /tmp/oud-password -X -n list-network-groups
```

The final network-group-to-workflow mapping is a `VERIFY` item in this repository until the successful completion output is recovered.

## 15. OUDSM first-start and route checks

```bash
oc get deployment,pods,svc,pvc,route -n oudsmns -o wide
oc get events -n oudsmns --sort-by=.lastTimestamp | tail -100
oc logs -n oudsmns deployment/<oudsm-deployment> \
  --all-containers --prefix --tail=300
oc rollout status deployment/<oudsm-deployment> \
  -n oudsmns --timeout=30m
```

Verify Route-to-Service alignment:

```bash
oc get route -n oudsmns <route> \
  -o jsonpath='{.spec.tls.termination}{" target="}{.spec.port.targetPort}{" service="}{.spec.to.name}{"\n"}'
oc get svc -n oudsmns <service> -o yaml
oc get endpointslice -n oudsmns \
  -l kubernetes.io/service-name=<service> -o yaml
curl -kI "https://<route-host>/oudsm/"
openssl s_client -connect <route-host>:443 \
  -servername <route-host> -showcerts </dev/null
```

The exact historical Route target and final PVC size remain `VERIFY` until retained YAML is recovered.

## 16. LDAP and LDAPS client tests

```bash
ldapsearch -x -H ldap://<host>:389 -s base -b '' namingContexts
ldapsearch -x -H ldaps://<host>:636 -s base -b '' namingContexts
openssl s_client -connect <host>:636 -servername <host> -showcerts </dev/null
```

For StartTLS on an LDAP listener, use the form supported by the installed LDAP client, typically:

```bash
ldapsearch -x -ZZ -H ldap://<host>:389 -s base -b '' namingContexts
```

External LDAPS remains a `VERIFY` path in this historical reconstruction.

## 17. Evidence capture without secrets

```bash
mkdir -p /tmp/oud-evidence
oc get nodes -o wide > /tmp/oud-evidence/nodes.txt
oc get sc nfs-rwx -o yaml > /tmp/oud-evidence/storageclass.yaml
oc get pods,svc,pvc -n oudns -o wide > /tmp/oud-evidence/oud-resources.txt
oc get pods,svc,pvc,route -n oudsmns -o wide > /tmp/oud-evidence/oudsm-resources.txt
helm get values <release> -n <namespace> --all > /tmp/oud-evidence/helm-values.yaml
```

Before copying any output into the repository:

```bash
bash scripts/security/scan-sensitive-data.sh
```

Review manually for identifiers the scanner cannot infer.

## Official references

- Oracle OUD replication verification: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudku/verifying-oud-replication.html
- Oracle OUD command-line reference: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudag/oracle-unified-directory-command-line-interface-reference.html
- Oracle OUD Kubernetes verification: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudku/verifying-oud-deployment.html
- OpenShift IngressController API: https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/operator_apis/ingresscontroller-operator-openshift-io-v1
- OpenShift Routes: https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/ingress_and_load_balancing/routes
- OpenShift SCC documentation: https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-multi/authentication_and_authorization/index
- Kubernetes command reference: https://kubernetes.io/docs/reference/kubectl/generated/
- Kubernetes rollout status: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/kubectl_rollout_status/
- Kubernetes `auth can-i`: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_auth/kubectl_auth_can-i/
- OCI Resource Manager job logs: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/get-job-logs.htm
- OCI Resource Manager log download: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/get-job-logs-content.htm
- OCI load-balancer backend health: https://docs.oracle.com/en-us/iaas/Content/Balance/Tasks/get_backend-server-health.htm
