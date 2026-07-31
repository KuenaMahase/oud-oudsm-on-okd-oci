# Historical source note

> Sanitized working note. Treat commands and values as historical evidence, not a current production runbook.

# override-values-oudsm.yaml — OUDSM on OpenShift (oudsmns), NFS-CSI, sequential 1→2

replicaCount: 1   # install with 1; after Ready, helm upgrade to 2

image:
  repository: <region>.ocir.io/<namespace>/oud/oudsm_cpu
  tag: "14.1.2.1-jdk17-ol9-250718"
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: ocir-pull-secret-oud

nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  name: oudsm-sa              # <— dedicated SA owned by this chart
  annotations: {}

# OpenShift-friendly: let SCC assign UID; if you choose anyuid later, you can set runAsUser: 1000
podSecurityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  fsGroupChangePolicy: "OnRootMismatch"

securityContext: {}

service:
  type: ClusterIP
  port: 7001
  sslPort: 7002

# Use an OpenShift Route separately; disable nginx ingress in the chart
ingress:
  enabled: false
  type: nginx
  host:
  domain:
  backendPort: http
  tlsEnabled: false
  tlsSecret:
  certCN:
  certValidityDays: 365
  nginxAnnotations: {}
  nginxAnnotationsTLS: {}

# Schedule on workers and spread replicas
nodeSelector:
  node-role.kubernetes.io/worker: ""
tolerations: []
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        topologyKey: "kubernetes.io/hostname"
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - oudsm

# Keep admin creds in values for now (for prod, switch to Secret: set secret.enabled: true & secret.name)
secret:
  enabled: false
  name:
  type: opaque

# Use a distinct PVC (separate from OUD); create 'oudsm-pvc' in namespace 'oudsmns'
persistence:
  enabled: true
  pvcname: oudsm-pvc        # distinct from OUD's claim
  accessMode: ReadWriteMany
  size: 20Gi
  reclaimPolicy: "Delete"
  storageClass: nfs-rwx

# OUDSM (WebLogic) runtime settings
oudsm:
  adminUser: weblogic
  adminPass: REDACTED     # use a strong secret in prod
  startupTime: 300                  # readiness buffer
  livenessProbeInitialDelay: 600    # first-boot comfort
  weblogicPluginEnabled: "true"

# Disable ELK integration by default
elk:
  imagePullSecrets:
    - name: ocir-busybox-pull
  IntegrationEnabled: false
  logStashImage: logstash:8.3.1
  logstashConfigMap:
  esindex: oudsmlogs-00001
  eshosts: http://elasticsearch.oudsmns.svc.cluster.local:9200
  sslenabled: false
  esuser: logstash_internal
  espassword: REDACTED
  esapikey:



