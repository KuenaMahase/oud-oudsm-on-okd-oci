# Complete implementation history and recovered runbook

> **Evidence status:** This document combines historical notes, screenshots,
> presentation material, and validated artifacts. It preserves the sequence of
> work while replacing real infrastructure identifiers with MaseruTel lab
> placeholders. Where sources conflict, the item remains marked `VERIFY`; the
> repository must not silently turn a remembered value into a claimed fact.

Yes—I remember the architecture and most of the implementation details.

Your deployment evolved through **two storage approaches**:

1. An earlier static-NFS design with separate exports such as:

   * `/export/oudpv_qa_nfs`
   * `/export/oudsmpv_qa_nsf`
   * `/export/oudconfigpv_qa_nsf`

2. A cleaner final design using the **Kubernetes NFS CSI driver**, one OCI-hosted NFS export, and dynamically provisioned `ReadWriteMany` PVCs:

   * NFS server: `nfs-server.example.internal`
   * Earlier private-IP reference: `10.20.30.40`
   * Export: `/scratch/shared/oud_user_projects`
   * StorageClass: `nfs-rwx`
   * Provisioner: `nfs.csi.k8s.io`
   * NFS version: `4.1`

The procedure below reconstructs the final NFS-CSI deployment. Some exact Helm value names changed between Oracle chart revisions, so I have marked those areas where the configuration must be compared with the chart version you originally cloned. I could not directly inspect the private repository through the connected GitHub integration, so this is reconstructed from your earlier commands, values, architecture decisions, and troubleshooting history.

---

## 1. Final architecture

```text
                            Internet
                               |
                    OCI Public Load Balancer
                       /                  \
              HTTPS 443                 TCP 389/636
                 |                           |
        OpenShift Router             Worker NodePorts
                 |                    30089 / 30636
        OUDSM OpenShift Route                |
                 |                       OUD Proxy
        OUDSM ClusterIP Service              |
                 |                   OUD DS/RS Services
        OUDSM pod(s)                         |
                                             |
                             OUD DS/RS StatefulSet pods
                                             |
                           RWX PVCs provisioned by NFS CSI
                                             |
                              OCI-hosted NFS server
                         /scratch/shared/oud_user_projects
```

Your namespace separation became:

| Namespace      | Purpose                                        |
| -------------- | ---------------------------------------------- |
| `oudns`        | OUD DS/RS, later OUD Proxy, services and PVCs  |
| `oudsmns`      | OUDSM/WebLogic pods, service, PVC and Route    |
| `elkns`        | ELK components when logging was included       |
| `oudingressns` | Used during the earlier ingress-nginx approach |

The final networking design used **one OCI Public Load Balancer**, not a separate Network Load Balancer:

* `443` forwarded to the OpenShift routers for OUDSM.
* `389` forwarded to NodePort `30089`.
* `636` forwarded to NodePort `30636`.
* OUD directory-server pods remained private.
* External LDAP traffic eventually went through the OUD Proxy rather than directly to each DS pod.

---

## Phase 1 — Prepare OCI infrastructure

## 2. OCI networking

Your remembered OpenShift VCN design used:

```text
VCN:             10.20.0.0/16
Public subnet:   10.20.0.0/20
Private subnet:  10.20.16.0/20
```

The NFS host was placed on the private OCI network and was reachable from the OpenShift workers.

You needed OCI NSG or Security List rules allowing:

| Source                  | Destination       |                  Port | Purpose                 |
| ----------------------- | ----------------- | --------------------: | ----------------------- |
| OpenShift worker subnet | NFS server        |              TCP 2049 | NFSv4.1                 |
| Administration network  | NFS server        |                TCP 22 | SSH administration      |
| OCI Load Balancer       | OpenShift workers | Router/NodePort ports | OUDSM and LDAP exposure |

Because the final StorageClass used `nfsvers=4.1`, the critical NFS network port was TCP `2049`.

An earlier values file referenced `10.20.30.40` as the NFS server. Later deployment records used the private DNS name:

```text
nfs-server.example.internal
```

Those likely represent two iterations of the OCI lab rather than one consistent network.

---

## Phase 2 — Build the OCI NFS server

## 3. Attach and mount the OCI storage volume

The NFS VM had a separate volume mounted at:

```text
/scratch
```

One remembered filesystem UUID was:

```text
<filesystem-uuid>
```

First inspect the device and filesystem:

```bash
sudo lsblk -f
sudo blkid
```

Create the mount point:

```bash
sudo mkdir -p /scratch
```

Mount the volume:

```bash
sudo mount UUID=<filesystem-uuid> /scratch
```

Confirm it:

```bash
findmnt /scratch
df -hT /scratch
```

Persist it in `/etc/fstab`. The filesystem type must match `lsblk -f`:

```text
UUID=<filesystem-uuid> /scratch <filesystem-type> defaults,_netdev,nofail 0 2
```

Validate the entry without rebooting:

```bash
sudo umount /scratch
sudo mount -a
findmnt /scratch
```

This persistent mount was important because you later encountered a failure where:

* The host rebooted.
* `/scratch` was not mounted.
* `nfs-server` entered a failed/dependency-failed state.
* The export path appeared missing.
* OUD/OUDSM PVC mounts failed.

---

## 4. Install and configure NFS

On the NFS server:

```bash
sudo dnf install -y nfs-utils
```

Create the shared export:

```bash
sudo mkdir -p /scratch/shared/oud_user_projects
```

The directory needed to be writable by the OpenShift workload UID and by the NFS CSI provisioner.

Your OUD containers were configured around:

```text
runAsUser:  1000
runAsGroup: 0
fsGroup:    1000
```

A suitable ownership baseline was therefore:

```bash
sudo chown -R 1000:0 /scratch/shared/oud_user_projects
sudo chmod -R 2770 /scratch/shared/oud_user_projects
```

During troubleshooting, a wider lab permission may have been used temporarily. The exact mode from the original lab needs verification, but the main requirement was that the dynamic provisioner could create a directory for every PVC and that UID `1000` could write inside it.

Configure `/etc/exports`:

```text
/scratch/shared/oud_user_projects 10.20.0.0/16(rw,sync,no_subtree_check)
```

Apply the export:

```bash
sudo exportfs -rav
sudo exportfs -v
```

Enable and start NFS:

```bash
sudo systemctl enable --now nfs-server
sudo systemctl status nfs-server
```

Validate:

```bash
showmount -e localhost
```

Expected export:

```text
/scratch/shared/oud_user_projects
```

---

## 5. Validate NFS from the OpenShift network

From a worker or a temporary test host:

```bash
getent hosts nfs-server.example.internal
nc -vz nfs-server.example.internal 2049
```

A manual mount test could be performed where permitted:

```bash
sudo mkdir -p /mnt/nfstest

sudo mount -t nfs4 \
  -o nfsvers=4.1 \
  nfs-server.example.internal:/scratch/shared/oud_user_projects \
  /mnt/nfstest

touch /mnt/nfstest/openshift-nfs-test
ls -l /mnt/nfstest/openshift-nfs-test
sudo umount /mnt/nfstest
```

---

## Phase 3 — Install NFS CSI in OpenShift

## 6. Deploy the NFS CSI driver

You installed the Kubernetes NFS CSI driver so OpenShift could dynamically create NFS-backed PVs.

The required CSI driver identity was:

```text
nfs.csi.k8s.io
```

Validation:

```bash
oc get csidriver
```

Expected:

```text
nfs.csi.k8s.io
```

Check its controller and node components:

```bash
oc get pods -A | grep -i nfs
```

Every worker that could run OUD or OUDSM required a healthy NFS CSI node pod.

---

## 7. Create the `nfs-rwx` StorageClass

Your final StorageClass was:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-rwx
provisioner: nfs.csi.k8s.io
parameters:
  server: nfs-server.example.internal
  share: /scratch/shared/oud_user_projects
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
```

Apply it:

```bash
oc apply -f nfs-rwx-storageclass.yaml
```

Validate:

```bash
oc get storageclass nfs-rwx -o yaml
```

Important properties:

```text
Access mode:          ReadWriteMany
Reclaim policy:       Retain
Volume binding:       Immediate
NFS version:          4.1
Dynamic provisioner:  nfs.csi.k8s.io
```

---

## 8. Test dynamic provisioning before OUD

Create a test project:

```bash
oc new-project nfs-test
```

Create a test PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-test-pvc
  namespace: nfs-test
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-rwx
  resources:
    requests:
      storage: 1Gi
```

Apply and inspect:

```bash
oc apply -f nfs-test-pvc.yaml
oc get pvc -n nfs-test
oc get pv
```

The PVC should become:

```text
Bound
```

The NFS CSI provisioner would create a PVC-specific subdirectory underneath:

```text
/scratch/shared/oud_user_projects/
```

That dynamic subdirectory behavior became important for OUD.

---

## Phase 4 — Prepare OpenShift projects and security

## 9. Create the namespaces

```bash
oc new-project oudns
oc new-project oudsmns
oc new-project elkns
```

Earlier deployment commands also used:

```bash
oc new-project oudingressns
```

That namespace was for the ingress-nginx approach before you standardized on OpenShift Routes for OUDSM.

---

## 10. Configure OpenShift SCC permissions

Oracle’s container images expected a known UID and filesystem permissions that did not always fit OpenShift’s default random UID model.

Your lab workaround was:

```bash
oc adm policy add-scc-to-user anyuid \
  -z default \
  -n oudns

oc adm policy add-scc-to-user anyuid \
  -z default \
  -n oudsmns
```

When ingress-nginx was used:

```bash
oc adm policy add-scc-to-user anyuid \
  -z default \
  -n oudingressns
```

The later, better-scoped approach is to grant the SCC to the actual OUD or OUDSM service account created by the Helm release rather than the namespace-wide `default` account.

Verify:

```bash
oc adm policy who-can use scc anyuid
```

---

## Phase 5 — Prepare container images and registry access

## 11. Oracle container images

Your remembered OUD image was:

```text
container-registry.oracle.com/middleware/oud_cpu:14.1.2.1-jdk17-ol9-250718
```

Your OUDSM image was:

```text
container-registry.oracle.com/middleware/oudsm_cpu:14.1.2.1-jdk17-ol9-250718
```

You worked with both Oracle Container Registry and OCI Container Registry.

The image pull secrets included names such as:

```text
oracle-registry-secret
ocir-pull-secret
ocirsecret
regcred
```

Create the Oracle registry secret:

```bash
oc create secret docker-registry oracle-registry-secret \
  --docker-server=container-registry.oracle.com \
  --docker-username='<oracle-account>' \
  --docker-password='<oracle-registry-token-or-password>' \
  --docker-email='<email>' \
  -n oudns
```

Create it for OUDSM as well:

```bash
oc create secret docker-registry oracle-registry-secret \
  --docker-server=container-registry.oracle.com \
  --docker-username='<oracle-account>' \
  --docker-password='<oracle-registry-token-or-password>' \
  --docker-email='<email>' \
  -n oudsmns
```

Link the secret where necessary:

```bash
oc secrets link default oracle-registry-secret \
  --for=pull \
  -n oudns

oc secrets link default oracle-registry-secret \
  --for=pull \
  -n oudsmns
```

Your override files also had to apply the pull secret to auxiliary images:

* OUD image
* OUDSM image
* BusyBox/init containers
* ELK images
* CronJob `kubectl` image
* Any OCIR mirror image

One of your refinements used images resembling:

```text
<region>.ocir.io/<tenancy>/oracle/oud
<region>.ocir.io/<tenancy>/mirrors/busybox:1.36
<region>.ocir.io/<tenancy>/mirrors/bitnami/kubectl
```

A common failure was configuring the secret for the main OUD container but forgetting an init container or Helm-created CronJob.

---

## Phase 6 — Obtain the Oracle Helm charts

## 12. Clone the Oracle Kubernetes repository

```bash
git clone https://github.com/oracle/fmw-kubernetes.git
cd fmw-kubernetes
```

OUD chart path:

```text
OracleUnifiedDirectory/kubernetes/helm/oud-ds-rs
```

OUDSM appeared in two paths depending on the repository revision:

```text
OracleUnifiedDirectorySM/kubernetes/helm/oudsm
```

or:

```text
OracleUnifiedDirectorySM/kubernetes/helm14c/oudsm
```

One of your working directories was:

```text
/scratch/shared/OUDContainer/fmw-kubernetes/OracleUnifiedDirectorySM/kubernetes/helm/oudsm
```

The directory contained:

```text
Chart.yaml
README.md
pvc-oudsm.yaml
templates/
values.yaml
values-override-oudsm.yaml
```

---

## Phase 7 — Deploy OUD DS/RS

## 13. OUD configuration

Your OUD DS/RS configuration included:

```text
Replicas:       3
Base DN:        o=maserutel
Root DN:        cn=Directory Manager
Sample entries: 200
LDAP:           1389
LDAPS:          1636
Admin:          1444
```

The image was:

```text
container-registry.oracle.com/middleware/oud_cpu:14.1.2.1-jdk17-ol9-250718
```

Security context:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 0
  fsGroup: 1000
```

Do not preserve the old clear-text lab root password in documentation or Git. It should be stored in an OpenShift Secret.

---

## 14. The original direct-NFS configuration

An earlier override used the NFS server directly:

```yaml
persistence:
  type: networkstorage
  networkstorage:
    nfs:
      server: 10.20.30.40
      path: /scratch/shared/oud_user_projects
  storageClassCreate: false
  storageClass: csi-nfs-dynamic
```

This mixed chart-managed network storage and an external StorageClass.

You later changed this to a cleaner PVC-based model.

---

## 15. Final PVC-based OUD storage model

Conceptually, your final values became:

```yaml
replicaCount: 3

image:
  repository: container-registry.oracle.com/middleware/oud_cpu
  tag: 14.1.2.1-jdk17-ol9-250718
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: oracle-registry-secret
  - name: ocir-pull-secret

persistence:
  enabled: true
  type: pvc
  storageClass: nfs-rwx
  accessModes:
    - ReadWriteMany
  networkstorage: {}

securityContext:
  runAsUser: 1000
  runAsGroup: 0
  fsGroup: 1000

oudConfig:
  baseDN: o=maserutel
  rootUserDN: cn=Directory Manager
  rootUserPassword: REDACTED
  sampleData: 200

service:
  ldapPort: 1389
  ldapsPort: 1636
  adminPort: 1444
```

The exact property nesting must match the `values.yaml` from the chart commit you used.

---

## 16. Critical NFS design rule for OUD

Although the NFS server provided one shared export, the OUD replicas **must not all write to the same physical OUD instance directory**.

Correct design:

```text
Shared NFS export
└── dynamically-created PVC directories
    ├── PVC for OUD pod 1
    ├── PVC for OUD pod 2
    └── PVC for OUD pod 3
```

Each StatefulSet replica receives its own PVC and its own NFS subdirectory.

```text
OUD replica 1 → PVC 1 → unique NFS directory
OUD replica 2 → PVC 2 → unique NFS directory
OUD replica 3 → PVC 3 → unique NFS directory
```

OUD replication synchronizes directory data between the replicas.

NFS provides persistent filesystems; it does **not** replace OUD replication.

Pointing every replica at the exact same data directory would risk backend and configuration corruption.

---

## 17. Install the OUD Helm release

From the OUD chart directory:

```bash
cd fmw-kubernetes/OracleUnifiedDirectory/kubernetes/helm/oud-ds-rs
```

Your historical command pattern was:

```bash
helm install my-oud-ds-rs . \
  --namespace oudns \
  --values values-override.yaml
```

Watch the rollout:

```bash
oc get pods -n oudns -w
```

Inspect everything created:

```bash
oc get statefulset -n oudns
oc get pods -n oudns -o wide
oc get pvc -n oudns
oc get pv
oc get svc -n oudns
```

Check events:

```bash
oc get events -n oudns \
  --sort-by=.metadata.creationTimestamp
```

Check logs:

```bash
oc logs -n oudns <oud-pod-name>
```

Verify the NFS mount:

```bash
oc exec -n oudns <oud-pod-name> -- \
  df -hT
```

Or:

```bash
oc exec -n oudns <oud-pod-name> -- \
  mount | grep -i nfs
```

---

## 18. OUD services

The exact service prefix depended on the Helm release name.

With a release named `my-oud-ds-rs`, services could have names such as:

```text
my-oud-ds-rs-lbr-admin
my-oud-ds-rs-lbr-ldap
```

Your later notes commonly used:

```text
oud-ds-rs-lbr-admin.oudns.svc
```

The administrative service exposed:

```text
1444
```

The LDAP services exposed:

```text
1389
1636
```

Your three OUD instances appeared as service-addressable endpoints such as:

```text
oud-ds-1.oud-ds-rs.oudns.svc.cluster.local
oud-ds-2.oud-ds-rs.oudns.svc.cluster.local
oud-ds-3.oud-ds-rs.oudns.svc.cluster.local
```

The remembered per-instance replication-related port values were `1389`, `2389`, and `3389`, but these need to be checked against the specific Oracle chart-generated topology rather than treated as a generic OUD convention.

---

## Phase 8 — Validate OUD

## 19. LDAP validation

From an administration host or test pod:

```bash
ldapsearch \
  -H ldap://<oud-service>:1389 \
  -x \
  -D "cn=Directory Manager" \
  -W \
  -b "o=maserutel" \
  -s base \
  "(objectClass=*)" \
  dn
```

For LDAPS:

```bash
ldapsearch \
  -H ldaps://<oud-service>:1636 \
  -x \
  -D "cn=Directory Manager" \
  -W \
  -b "o=maserutel" \
  -s base \
  "(objectClass=*)" \
  dn
```

Expected:

```text
dn: o=maserutel
```

Verify all three pods:

```bash
oc get pods -n oudns
```

Then query each pod or its individual service.

---

## 20. Persistence validation

Create or load a test entry.

Delete one OUD pod:

```bash
oc delete pod -n oudns <oud-pod-name>
```

Wait for recreation:

```bash
oc get pods -n oudns -w
```

Repeat the LDAP search.

Pass condition:

* Pod returns.
* The PVC is reattached.
* The OUD instance starts normally.
* The directory entry is still present.
* Replication remains healthy.

---

## Phase 9 — Deploy OUDSM

## 21. OUDSM deployment model

Your final OUDSM design used:

```text
Namespace:      oudsmns
Initial pods:   1
Final pods:     2
Image:          oudsm_cpu:14.1.2.1-jdk17-ol9-250718
StorageClass:   nfs-rwx
PVC size:       5Gi
Service:        ClusterIP
HTTPS port:     7002
Exposure:       OpenShift Route
TLS mode:       reencrypt
```

You intentionally started with one replica:

```text
replicaCount: 1
```

You waited for the initial WebLogic/OUDSM domain to finish initializing before scaling to:

```text
replicaCount: 2
```

This prevented two pods from trying to initialize the shared WebLogic domain simultaneously.

---

## 22. OUDSM PVC

Conceptual PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: oudsm-pvc
  namespace: oudsmns
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-rwx
  resources:
    requests:
      storage: 5Gi
```

Apply it:

```bash
oc apply -f pvc-oudsm.yaml
```

Validate:

```bash
oc get pvc -n oudsmns
oc describe pvc oudsm-pvc -n oudsmns
```

The dynamic provisioner created a path similar to:

```text
/scratch/shared/oud_user_projects/oudsmns/oudsm-pvc-<uid>
```

---

## 23. OUDSM override values

Your values were conceptually:

```yaml
replicaCount: 1

image:
  repository: container-registry.oracle.com/middleware/oudsm_cpu
  tag: 14.1.2.1-jdk17-ol9-250718
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: oracle-registry-secret

persistence:
  enabled: true
  storageClass: nfs-rwx
  size: 5Gi
  accessModes:
    - ReadWriteMany

service:
  type: ClusterIP
  port: 7002

ingress:
  enabled: false
```

You disabled the chart’s normal Kubernetes Ingress because OUDSM was exposed using an OpenShift Route.

### Important YAML problem you encountered

Your `values-override-oudsm.yaml` contained two separate top-level `oudsm:` blocks.

In YAML, the second duplicate key overwrote the first one. That caused values such as:

```text
adminUser
adminPass
```

to disappear.

The fix was to merge every OUDSM property under a single `oudsm:` key.

---

## 24. Install OUDSM

Go to the chart directory:

```bash
cd fmw-kubernetes/OracleUnifiedDirectorySM/kubernetes/helm14c/oudsm
```

Or, depending on the revision:

```bash
cd fmw-kubernetes/OracleUnifiedDirectorySM/kubernetes/helm/oudsm
```

Install:

```bash
helm install oudsm . \
  --namespace oudsmns \
  --values values-override-oudsm.yaml
```

Watch the first pod:

```bash
oc get pods -n oudsmns -w
```

Review logs:

```bash
oc logs -n oudsmns <oudsm-pod-name> -f
```

Wait until WebLogic and the OUDSM application are ready before adding the second replica.

Scale through Helm:

```bash
helm upgrade oudsm . \
  --namespace oudsmns \
  --values values-override-oudsm.yaml \
  --set replicaCount=2
```

Validate:

```bash
oc get pods -n oudsmns
oc get pvc -n oudsmns
oc get svc -n oudsmns
```

---

## Phase 10 — Expose OUDSM with an OpenShift Route

## 25. OUDSM service

The final service pattern was:

```text
Service: oudsm-lbr
Type:    ClusterIP
Port:    7002
```

Earlier examples used service `oudsm` and port `7001`; your later TLS design used `oudsm-lbr:7002`.

Verify the actual service:

```bash
oc get svc -n oudsmns
oc describe svc oudsm-lbr -n oudsmns
```

---

## 26. Create the re-encrypt Route

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: oudsm
  namespace: oudsmns
spec:
  host: oudsm.apps.<cluster-domain>
  to:
    kind: Service
    name: oudsm-lbr
  port:
    targetPort: 7002
  tls:
    termination: reencrypt
    insecureEdgeTerminationPolicy: Redirect
```

Apply:

```bash
oc apply -f route-oudsm.yaml
```

Validate:

```bash
oc get route oudsm -n oudsmns
oc describe route oudsm -n oudsmns
```

Request path:

```text
Browser
  → OCI Public LB:443
  → OpenShift router
  → OUDSM Route
  → oudsm-lbr:7002
  → OUDSM pod
```

Test:

```bash
curl -kI https://oudsm.apps.<cluster-domain>/oudsm
```

Then open:

```text
https://oudsm.apps.<cluster-domain>/oudsm
```

---

## Phase 11 — Connect OUDSM to OUD

## 27. OUDSM connection values

The values you used in the OUDSM connection form were:

| Field               | Value                           |
| ------------------- | ------------------------------- |
| Directory Type      | `OIDOUD`                        |
| Server              | `oud-ds-rs-lbr-admin.oudns.svc` |
| Administration Port | `1444`                          |
| SSL Enabled         | Checked                         |
| User Name           | `cn=Directory Manager`          |
| Password            | Stored administrative password  |

With a different Helm release prefix, the server could instead be:

```text
my-oud-ds-rs-lbr-admin.oudns.svc
```

That service-name difference was one reason to inspect:

```bash
oc get svc -n oudns
```

rather than assuming the name.

After connecting, validate:

* Directory Manager page opens.
* Configuration tree loads.
* Naming context `o=maserutel` appears.
* Data Browser opens.
* Sample entries can be viewed.
* Replication topology is visible.

---

## Phase 12 — External LDAP exposure

## 28. Initial exposure options

During early iterations you considered or used:

* OpenShift NodePort
* ingress-nginx TCP services
* OCI Load Balancer
* Route for OUDSM
* Route passthrough for pure LDAPS

Your early ingress-nginx design pointed HTTP management traffic at a service resembling:

```text
my-oud-ds-rs-lbr-http:1080
```

You later simplified OUDSM exposure to a native OpenShift Route.

---

## 29. Final public load-balancer design

The final architecture used a single OCI Public Load Balancer:

```text
443 → OpenShift routers → OUDSM Route
389 → Worker NodePort 30089 → OUD Proxy LDAP
636 → Worker NodePort 30636 → OUD Proxy LDAPS
```

The OUD Proxy and OUD DS/RS remained in `oudns`.

The DS/RS services were private ClusterIP/headless services.

This separated responsibilities:

```text
OCI Load Balancer
    Provides public entry and transport forwarding.

OpenShift Route
    Routes HTTPS to OUDSM.

OUD Proxy
    Provides LDAP-aware backend routing and failover.

OUD DS/RS
    Stores and replicates directory data.
```

---

## Phase 13 — Full validation checklist

## 30. OpenShift resources

```bash
oc get pods -n oudns -o wide
oc get pods -n oudsmns -o wide

oc get pvc -n oudns
oc get pvc -n oudsmns
oc get pv

oc get svc -n oudns
oc get svc -n oudsmns

oc get route -n oudsmns
```

All PVCs should be:

```text
Bound
```

All workload pods should be:

```text
Running
Ready
```

---

## 31. Confirm NFS inside the pods

```bash
oc exec -n oudns <oud-pod> -- df -hT
oc exec -n oudns <oud-pod> -- mount | grep nfs

oc exec -n oudsmns <oudsm-pod> -- df -hT
oc exec -n oudsmns <oudsm-pod> -- mount | grep nfs
```

Expected NFS version:

```text
nfs4
```

---

## 32. Confirm dynamic NFS directories

On the NFS server:

```bash
sudo find /scratch/shared/oud_user_projects \
  -maxdepth 3 \
  -type d \
  -print
```

You should see separate subdirectories for:

* Each OUD PVC
* OUDSM PVC
* Proxy PVC where applicable
* Any test PVCs

---

## 33. Test OUD

Validate:

```text
LDAP bind on 1389
LDAPS bind on 1636
Administrative connection on 1444
Search under o=maserutel
Write an entry
Read the entry from another replica
Delete/recreate a pod
Confirm data remains
```

---

## 34. Test OUDSM

Validate:

```text
OCI LB answers on 443
OpenShift Route is admitted
OUDSM login page opens
OUDSM connects to the OUD admin service
Data Browser opens
Configuration tree loads
Both OUDSM replicas become Ready
OUDSM survives pod replacement
```

---

## Troubleshooting you encountered

## 35. NFS broke after the OCI VM rebooted

### Symptoms

```text
PVC mount failures
NFS server dependency failure
/scratch/shared/oud_user_projects missing
nfs-server inactive or failed
```

### Diagnosis

```bash
findmnt /scratch
lsblk -f
systemctl status nfs-server
journalctl -u nfs-server
```

### Fix

```bash
sudo mount UUID=<filesystem-uuid> /scratch
sudo mount -a
sudo exportfs -rav
sudo systemctl restart nfs-server
sudo systemctl status nfs-server
```

Then confirm:

```bash
showmount -e localhost
```

The permanent fix was the correct `/etc/fstab` entry.

---

## 36. PVC remained Pending

Check:

```bash
oc describe pvc <pvc-name> -n <namespace>
oc get storageclass
oc get csidriver
oc get pods -A | grep -i nfs
```

Likely causes:

* `nfs-rwx` did not exist.
* The provisioner name was wrong.
* NFS CSI controller was unhealthy.
* The NFS hostname did not resolve.
* TCP `2049` was blocked.
* The export path did not exist.
* The provisioner lacked write permission.

---

## 37. Pod failed with permission denied

Check:

```bash
oc describe pod <pod> -n <namespace>
oc logs <pod> -n <namespace>
```

Then examine:

* SCC assignment
* `runAsUser`
* `runAsGroup`
* `fsGroup`
* Export ownership
* Directory permissions
* NFS UID/GID mapping

Your working security context was based around:

```text
UID 1000
GID 0
fsGroup 1000
```

---

## 38. ImagePullBackOff

Check:

```bash
oc describe pod <pod> -n <namespace>
oc get secret -n <namespace>
oc get serviceaccount default -n <namespace> -o yaml
```

The pull secret had to cover more than the main Oracle container:

* Init container
* BusyBox image
* Helm hook
* Backup CronJob
* `kubectl` CronJob image
* ELK sidecar/image

---

## 39. OUDSM values silently disappeared

Cause:

```yaml
oudsm:
  adminUser: ...

# Later in the same file
oudsm:
  persistence: ...
```

The second `oudsm:` block overwrote the first.

Fix:

```yaml
oudsm:
  adminUser: ...
  adminPass: ...
  persistence: ...
```

Only one top-level key.

---

## 40. Two OUDSM pods initialized simultaneously

Symptoms could include:

* WebLogic domain lock errors
* Partial domain creation
* Inconsistent configuration
* One pod CrashLooping

Fix:

1. Deploy `replicaCount: 1`.
2. Wait for complete domain initialization.
3. Confirm OUDSM is reachable.
4. Upgrade to `replicaCount: 2`.

---

## 41. Port mismatch between Route and service

Your notes contained both:

```text
7001 — non-TLS/admin HTTP examples
7002 — final HTTPS/TLS service
```

The final re-encrypt Route had to point to the TLS service port:

```text
7002
```

Check:

```bash
oc get svc oudsm-lbr -n oudsmns -o yaml
oc get route oudsm -n oudsmns -o yaml
```

---

## 42. Service name did not resolve

The service name depended on the Helm release.

For example:

```text
Release: my-oud-ds-rs
Service: my-oud-ds-rs-lbr-admin
```

Versus later documentation:

```text
oud-ds-rs-lbr-admin
```

Always identify it from:

```bash
oc get svc -n oudns
```

Then use the complete internal DNS name:

```text
<service>.oudns.svc
```

---

## Earlier static-PV design

Before the dynamic NFS CSI model, your architecture used separate NFS exports and mount purposes:

| NFS export                   | PVC purpose                         | Container mount    |
| ---------------------------- | ----------------------------------- | ------------------ |
| `/export/oudpv_qa_nfs`       | OUD user projects and instance data | `/u01/oudpv`       |
| `/export/oudsmpv_qa_nsf`     | OUDSM domain data                   | `/u01/oudsmpv`     |
| `/export/oudconfigpv_qa_nsf` | OUD configuration input             | `/u01/oudconfigpv` |

You then moved toward:

```text
One NFS export
+ NFS CSI
+ nfs-rwx StorageClass
+ dynamically created PVC directories
```

That removed the need to manually create and maintain one static PV definition for every workload.

---

## What I consider firmly remembered

These details are strongly established from your deployment history:

* OUD and OUDSM ran on OpenShift/OKD in OCI.
* NFS was hosted on OCI and mounted through NFS CSI.
* Final export: `/scratch/shared/oud_user_projects`.
* Final NFS host: `nfs-server.example.internal`.
* StorageClass: `nfs-rwx`.
* Provisioner: `nfs.csi.k8s.io`.
* NFS version: `4.1`.
* `ReadWriteMany` storage.
* `Retain` reclaim policy.
* Namespaces: `oudns`, `oudsmns`, and `elkns`.
* OUD had three replicas.
* OUD base DN was `o=maserutel`.
* OUD ports included `1389`, `1636`, and `1444`.
* OUDSM was initially deployed as one replica and later scaled to two.
* OUDSM persistence was `5Gi` on `nfs-rwx`.
* OUDSM used an OpenShift re-encrypt Route.
* OUDSM connected to the OUD admin service on port `1444`.
* OCI used one public Load Balancer for HTTPS and LDAP/LDAPS.
* LDAP and LDAPS were forwarded to NodePorts `30089` and `30636`.
* `/scratch` failing to remount after reboot caused a major NFS failure.
* Duplicate `oudsm:` YAML keys caused configuration values to be overwritten.
* All image consumers needed registry pull secrets.

Items needing confirmation from the original chart files are:

* Exact Helm chart commit.
* Exact PVC capacity used for each OUD replica.
* Exact OUD values-key nesting.
* Exact service names produced by the release.
* Exact NFS export permission mode.
* Whether `10.20.30.40` and the `10.20.0.0/16` VCN belonged to the same cluster iteration.
* Whether the OUDSM Route initially used `7001` before being changed to `7002`.

## Key Takeaways

* **OCI NFS was the storage backend; NFS CSI turned it into dynamic OpenShift PVCs.**
* **The export was shared, but every OUD replica needed its own PVC directory.**
* **OUD replication—not a shared data directory—kept the replicas synchronized.**
* **OUDSM was initialized with one replica before scaling to two.**
* **OUDSM used Route → ClusterIP Service → pod, while LDAP/LDAPS used TCP NodePorts through the OCI Load Balancer.**
* **The most important storage recovery fix was persisting `/scratch` correctly in `/etc/fstab` before starting `nfs-server`.**
