# Historical source note

> Sanitized working note. Treat commands and values as historical evidence, not a current production runbook.

# OUD Configuration
replicaCount: 3

image:
  repository: container-registry.oracle.com/middleware/oud_cpu
  tag: "14.1.2.1-jdk17-ol9-250718"
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: oracle-registry-secret
  - name: ocir-pull-secret

# OUD Instance Configuration
oud:
  instanceName: "oud1"
  instanceType: "Directory"
  adminConnectorPort: 1444
  httpPort: 1080
  httpsPort: 1081
  ldapPort: 1389
  ldapsPort: 1636
  replicationPort: 1898

  baseDN: "o=maserutel"
  rootUserDN: "cn=Directory Manager"
  rootUserPassword: REDACTED   # move to a Secret in prod
  sampleData: "200"

  instances:
    - name: "oud-ds-1"
      type: "Directory"
      adminPort: 1444
      ldapPort: 1389
      ldapsPort: 1636
    - name: "oud-ds-2"
      type: "Directory"
      adminPort: 2444
      ldapPort: 2389
      ldapsPort: 2636
    - name: "oud-ds-3"
      type: "Directory"
      adminPort: 3444
      ldapPort: 3389
      ldapsPort: 3636

resources:
  requests:
    memory: "4Gi"
    cpu: "1"
  limits:
    memory: "8Gi"
    cpu: "2"

# Storage, use CSI dynamic provisioning
persistence:
  enabled: true
  type: pvc
  size: 20Gi
  accessModes:
    - ReadWriteMany
  storageClassCreate: false
  storageClass: "nfs-rwx"
  networkstorage: {}          # keep empty when using CSI
  mountPath: /scratch/shared/oud_user_projects

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values: ["oud"]
        topologyKey: kubernetes.io/hostname

service:
  type: ClusterIP
  ldapPort: 1389
  ldapsPort: 1636
  adminPort: 1444

replication:
  enabled: true
  servers:
    - oud-ds-1.oud-ds-rs.oudns.svc.cluster.local:1389
    - oud-ds-2.oud-ds-rs.oudns.svc.cluster.local:2389
    - oud-ds-3.oud-ds-rs.oudns.svc.cluster.local:3389

securityContext:
  runAsUser: 1000
  runAsGroup: 0
  fsGroup: 1000

livenessProbe:
  tcpSocket: { port: 1389 }
  initialDelaySeconds: 120
  periodSeconds: 30

readinessProbe:
  tcpSocket: { port: 1389 }
  initialDelaySeconds: 60
  periodSeconds: 10


