# Historical source note

> Sanitized working note. Treat commands and values as historical evidence, not a current production runbook.

**OUD + OUDSM + Proxy** on OpenShift with **NFS CSI**.

I’ll include:

* **NFS Server setup** (exports, dirs, firewall)
* **OpenShift cluster prep** (namespaces, SCCs, secrets)
* **NFS-CSI driver installation (repo clone, Helm/manifests)**
* **StorageClass creation**
* **PV/PVC options (dynamic vs static)**
* **Helm override examples (OUD & OUDSM)**
* **Proxy YAML**
* **Verification checklist**

---

# 🚀 OUD/OUDSM Deployment with NFS CSI on OpenShift

---

## 1) Configure NFS Server (run on NFS host)

### Option A — Single export (recommended for CSI dynamic provisioning)

```bash
# Create parent dir
mkdir -p /scratch/shared/oud_user_projects
chown -R 1000:0 /scratch/shared/oud_user_projects
chmod 0775 /scratch/shared/oud_user_projects

# Add export
echo "/scratch/shared/oud_user_projects 10.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
exportfs -ra

# Start NFS service
systemctl enable --now nfs-server
```

### Option B — Three explicit exports (for static PVs)

```bash
mkdir -p /u01/oudpv /u01/oudsmpv /u01/oudconfigpv
chown -R 1000:0 /u01/oudpv /u01/oudsmpv /u01/oudconfigpv
chmod 0775 /u01/oudpv /u01/oudsmpv /u01/oudconfigpv

cat <<EOF >> /etc/exports
/u01/oudpv        10.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
/u01/oudsmpv      10.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
/u01/oudconfigpv  10.20.0.0/16(rw,sync,no_subtree_check,no_root_squash)
EOF
exportfs -ra
systemctl enable --now nfs-server
```

👉 **Firewall:** Allow **111/tcp,udp** and **2049/tcp,udp** from your OpenShift node CIDRs.

---

## 2) OpenShift Cluster Prep (run on workstation with `oc`)

```bash
# Namespaces
oc new-project oudns     || true   # OUD DS/RS/Proxy
oc new-project oudsmns   || true   # OUDSM
oc new-project elkns     || true   # (optional) ELK

# Loosen SCCs (needed for NFS mounts, widen only if perms errors)
oc adm policy add-scc-to-group anyuid system:serviceaccounts:oudns
oc adm policy add-scc-to-group anyuid system:serviceaccounts:oudsmns
```

---

## 3) Install NFS-CSI Driver

### Clone repo

```bash
git clone https://github.com/kubernetes-csi/csi-driver-nfs.git
cd csi-driver-nfs
```

### Option 1 — Install via Helm (recommended)

```bash
helm repo add csi-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update

helm upgrade --install csi-nfs csi-nfs/csi-driver-nfs \
  -n kube-system --create-namespace \
  --set kubeletDir=/var/lib/kubelet \
  --set controller.replicas=2

# Grant SCCs
oc adm policy add-scc-to-user privileged -z csi-nfs-controller-sa -n kube-system
oc adm policy add-scc-to-user privileged -z csi-nfs-node-sa       -n kube-system
```

### Option 2 — Install via raw manifests

```bash
cd deploy/kubernetes
oc apply -f rbac-csi-nfs.yaml
oc apply -f csi-nfs-driverinfo.yaml
oc apply -f csi-nfs-controller.yaml
oc apply -f csi-nfs-node.yaml

# SCCs
oc adm policy add-scc-to-user privileged -z csi-nfs-controller-sa -n kube-system
oc adm policy add-scc-to-user privileged -z csi-nfs-node-sa       -n kube-system
```

👉 Verify:

```bash
oc -n kube-system get pods -l app.kubernetes.io/name=csi-driver-nfs
```

---

## 4) Create StorageClass (RWX)

```bash
export NFS_SERVER=10.20.30.40
export NFS_SHARE=/scratch/shared/oud_user_projects

cat > sc-nfs-rwx.yaml <<'YAML'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-rwx
provisioner: nfs.csi.k8s.io
parameters:
  server: __NFS_SERVER__
  share: __NFS_SHARE__
mountOptions:
  - nfsvers=4.1
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
YAML

sed -i "s|__NFS_SERVER__|$NFS_SERVER|g; s|__NFS_SHARE__|$NFS_SHARE|g" sc-nfs-rwx.yaml
oc apply -f sc-nfs-rwx.yaml
oc get sc
```

---

## 5) PV/PVC Choices

* **Dynamic (recommended):** Helm chart PVCs use `storageClass: nfs-rwx` → CSI provisions PVs.
* **Static:** Manually create PVs for `/u01/oudpv`, `/u01/oudconfigpv`, `/u01/oudsmpv` and bind via PVC `volumeName`.

---

## 6) Helm Overrides

### OUD DS/RS `values-override.yaml`

```yaml
replicaCount: 1
image:
  repository: <ocir>/oracle/oud_cpu
  tag: "12.2.1.4-jdk8-ol8-<build>"
imagePullSecrets: [ { name: ocir-pull } ]

oudConfig:
  rootUserDN: "cn=Directory Manager"
  rootUserPassword: REDACTED
  baseDN: "dc=example,dc=com"

persistence:
  type: networkstorage
  size: 20Gi
  storageClass: "nfs-rwx"
  storageClassCreate: false
  networkstorage:
    nfs:
      server: "10.20.30.40"
      path: "/scratch/shared/oud_user_projects"
```

### OUDSM `values-oudsm.yaml`

```yaml
image:
  repository: <ocir>/oracle/oudsm
  tag: "12.2.1.4.0"
imagePullSecrets: [ { name: ocir-pull } ]

persistence:
  enabled: true
  size: 10Gi
  storageClass: "nfs-rwx"
  accessModes: [ "ReadWriteMany" ]
```

---

## 7) Deploy OUD & OUDSM

```bash
# Clone Oracle Helm charts
git clone https://github.com/oracle/fmw-kubernetes.git
cd fmw-kubernetes/OracleUnifiedDirectory/kubernetes/helm

# OUD
cd oud-ds-rs
helm upgrade --install oud-ds-rs . -n oudns -f ../values-override.yaml --wait --timeout 20m

# OUDSM
cd ../oudsm
helm upgrade --install oudsm . -n oudsmns -f values-oudsm.yaml --wait --timeout 15m

# Route for OUDSM UI
oc -n oudsmns expose svc/oudsm --name=oudsm-route
oc -n oudsmns get route/oudsm-route -o wide
```

---

## 8) Deploy OUD Proxy (optional)

```bash
cat > oud-proxy.yaml <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: oud-proxy-pvc, namespace: oudns }
spec:
  accessModes: ["ReadWriteMany"]
  resources: { requests: { storage: 10Gi } }
  storageClassName: nfs-rwx
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: oud-proxy, namespace: oudns }
spec:
  replicas: 2
  selector: { matchLabels: { app: oud-proxy } }
  template:
    metadata: { labels: { app: oud-proxy } }
    spec:
      imagePullSecrets: [ { name: ocir-pull } ]
      containers:
        - name: proxy
          image: <ocir>/oracle/oud_cpu:12.2.1.4-<build>
          env:
            - { name: OUD_INSTANCE_TYPE, value: "proxy" }
          volumeMounts:
            - { name: data, mountPath: /u01/oracle/user_projects }
      volumes:
        - name: data
          persistentVolumeClaim: { claimName: oud-proxy-pvc }
---
apiVersion: v1
kind: Service
metadata: { name: oud-proxy, namespace: oudns }
spec:
  selector: { app: oud-proxy }
  type: NodePort
  ports:
    - { name: ldap, port:1389, targetPort:1389, nodePort:32389 }
    - { name: ldaps, port:1636, targetPort:1636, nodePort:32636 }
YAML

oc apply -f oud-proxy.yaml
```

---

## 9) Verification

**NFS exports:**

```bash
showmount -e 10.20.30.40
```

**Driver running:**

```bash
oc -n kube-system get pods -l app.kubernetes.io/name=csi-driver-nfs
```

**StorageClass present:**

```bash
oc get sc nfs-rwx
```

**PVCs bound:**

```bash
oc -n oudns get pvc,pv
oc -n oudsmns get pvc,pv
```

**Pods up:**

```bash
oc -n oudns get pods
oc -n oudsmns get pods
```

**LDAP test:**

```bash
oc -n oudns port-forward statefulset/oud-ds-rs 1389:1389 1636:1636 &
ldapsearch -x -H ldap://127.0.0.1:1389 -s base -b "" namingContexts
```

**OUDSM UI:**

```bash
oc -n oudsmns get route/oudsm-route -o jsonpath='{.spec.host}{"\n"}'
```

Open in browser.

---

✅ This single runbook gives you:

* NFS server exports
* CSI driver installation
* StorageClass setup
* Namespace & SCC prep
* Helm overrides for OUD/OUDSM
* Proxy deployment
* End-to-end verification

---

Do you want me to also generate the **static PV + PVC manifests** (so each export `/u01/oudpv`, `/u01/oudsmpv`, `/u01/oudconfigpv` is bound explicitly), alongside the Helm overrides wired to them? That way you’ll have both dynamic and static recipes side by side.


