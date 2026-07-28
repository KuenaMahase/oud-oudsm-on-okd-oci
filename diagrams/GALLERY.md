# Mermaid architecture gallery

This page is generated from `diagrams/mermaid/*.mmd`. Edit the `.mmd` source and run `python3 scripts/rendering/build-mermaid-gallery.py`; do not edit generated diagram blocks by hand.

> Solid paths are verified or strongly observed. Dashed or explicitly labelled `VERIFY` paths remain unresolved.

## 1. Final platform context

Source: [`mermaid/01-final-platform-context.mmd`](mermaid/01-final-platform-context.mmd)

```mermaid
flowchart LR
    A[Platform administrator] -->|oc / browser| OCI[OCI entry points]
    L[LDAP and LDAPS clients] --> OCI

    subgraph VCN[OCI VCN - sanitized]
      OCI --> OKD[OKD / OpenShift cluster]
      BV[OCI Block Volume] --> NFS[Oracle Linux NFS server]
      NFS --> CSI[NFS CSI driver]
    end

    subgraph OUDNS[Namespace: oudns]
      PROXY[OUD Proxy - 2 observed pods]
      DS0[OUD DS 0]
      DS1[OUD DS 1]
      DS2[OUD DS 2]
      PROXY --> DS0
      PROXY --> DS1
      PROXY --> DS2
      DS0 <-. OUD replication .-> DS1
      DS1 <-. OUD replication .-> DS2
    end

    subgraph OUDSMNS[Namespace: oudsmns]
      OUDSM[OUDSM / WebLogic domain]
    end

    OKD --> PROXY
    OKD --> OUDSM
    OUDSM -->|administration connector| DS0
    CSI -->|dynamic PVs / PVCs| DS0
    CSI -->|dynamic PVs / PVCs| DS1
    CSI -->|dynamic PVs / PVCs| DS2
    CSI -->|dedicated PVC| OUDSM
```

## 2. OCI network topology

Source: [`mermaid/02-final-oci-network-topology.mmd`](mermaid/02-final-oci-network-topology.mmd)

```mermaid
flowchart TB
    ADMIN[Administrator] --> APILB[OCI API load balancer\nTCP 6443]
    WEB[Browser] --> APPSLB[OCI applications load balancer\nTCP 443]
    LDAP[LDAP client] --> LDAPLB[OCI LDAP listener\nTCP 389]

    subgraph VCN[OCI VCN]
      subgraph CP[Control-plane subnet]
        CP1[Control plane 1]
        CP2[Control plane 2]
        CP3[Control plane 3]
      end
      subgraph WORKERS[Worker subnets]
        W1[Worker 1]
        W2[Worker 2]
        W3[Worker 3]
      end
      subgraph STORAGE[Storage subnet]
        NFS[NFS compute instance]
        BV[(OCI Block Volume)]
        BV -->|mounted at /scratch| NFS
      end
      APILB --> CP1
      APILB --> CP2
      APILB --> CP3
      APPSLB --> W1
      APPSLB --> W2
      APPSLB --> W3
      LDAPLB -->|NodePort 30089 observed| W1
      LDAPLB -->|NodePort 30089 observed| W2
      LDAPLB -->|NodePort 30089 observed| W3
      W1 -->|NFS 4.1 / TCP 2049| NFS
      W2 -->|NFS 4.1 / TCP 2049| NFS
      W3 -->|NFS 4.1 / TCP 2049| NFS
    end

    LDAPS[LDAPS listener / port path]:::verify
    classDef verify stroke-dasharray: 5 5,stroke:#b45309,color:#92400e
```

## 3. OKD/OpenShift cluster topology

Source: [`mermaid/03-final-okd-cluster-topology.mmd`](mermaid/03-final-okd-cluster-topology.mmd)

```mermaid
flowchart TB
    subgraph OKD[OKD / OpenShift cluster]
      subgraph CP[3 control-plane nodes - observed]
        API[kube-apiserver]
        ETCD[etcd]
        SCHED[scheduler and controllers]
      end
      subgraph WK[3 worker nodes - observed]
        R1[router pod]
        R2[router pod]
        R3[router pod]
        OUDW[OUD and OUD Proxy workloads]
        OUDSMW[OUDSM workload]
      end
      subgraph NS1[oudns]
        P0[oud-proxy-0]
        P1[oud-proxy-1]
        D0[OUD DS 0]
        D1[OUD DS 1]
        D2[OUD DS 2]
      end
      subgraph NS2[oudsmns]
        SM[OUDSM domain]
      end
      subgraph CSINS[openshift-csi-driver-nfs-namespace]
        CCTRL[NFS CSI controllers]
        CNODE[NFS CSI node DaemonSet]
      end
    end
    R1 --> SM
    R2 --> SM
    R3 --> SM
    OUDW --> P0
    OUDW --> P1
    P0 --> D0
    P0 --> D1
    P0 --> D2
    P1 --> D0
    P1 --> D1
    P1 --> D2
    OUDSMW --> SM
    CNODE --> D0
    CNODE --> D1
    CNODE --> D2
    CNODE --> SM
```

## 4. Load-balancer and ingress flows

Source: [`mermaid/04-final-load-balancer-and-ingress-flow.mmd`](mermaid/04-final-load-balancer-and-ingress-flow.mmd)

```mermaid
flowchart LR
    ADMIN[oc client] -->|TCP 6443| APILB[OCI API LB]
    APILB --> CP[Control-plane nodes]
    CP --> API[kube-apiserver]

    BROWSER[Web browser] -->|TCP 443| APPSLB[OCI applications LB]
    APPSLB --> ROUTERS[OpenShift router pods on workers]
    ROUTERS --> ROUTE[OUDSM Route]
    ROUTE --> SMSVC[OUDSM ClusterIP Service]
    SMSVC --> SMPOD[OUDSM pod]

    LDAP[LDAP client] -->|TCP 389| PUBLB[OCI public LB listener]
    PUBLB -->|NodePort 30089| WORKERS[Worker nodes]
    WORKERS --> PROXYSVC[oud-proxy-ldap-public Service]
    PROXYSVC --> PROXY[OUD Proxy pods]

    LDAPS[LDAPS path]:::verify
    classDef verify stroke-dasharray: 5 5,stroke:#b45309,color:#92400e
```

## 5. NFS CSI storage flow

Source: [`mermaid/05-final-nfs-csi-storage-flow.mmd`](mermaid/05-final-nfs-csi-storage-flow.mmd)

```mermaid
flowchart LR
    BV[(OCI Block Volume\n1 TB observed)] -->|mounted at /scratch| VM[Oracle Linux 9 NFS VM]
    VM --> EXPORT[NFS export\n/scratch/shared/oud_user_projects]
    EXPORT -->|NFSv4.1| CSI[NFS CSI driver\nnfs.csi.k8s.io]
    CSI --> SC[StorageClass nfs-rwx\ncluster-scoped\nRetain / Immediate]

    SC --> P0[PVC for OUD DS 0]
    SC --> P1[PVC for OUD DS 1]
    SC --> P2[PVC for OUD DS 2]
    SC --> PS[PVC for OUDSM]

    P0 --> D0[(pvc-specific NFS subdirectory)]
    P1 --> D1[(pvc-specific NFS subdirectory)]
    P2 --> D2[(pvc-specific NFS subdirectory)]
    PS --> DS[(pvc-specific NFS subdirectory)]

    D0 --> O0[OUD DS 0]
    D1 --> O1[OUD DS 1]
    D2 --> O2[OUD DS 2]
    DS --> SM[OUDSM]
```

## 6. OUD StatefulSet and storage

Source: [`mermaid/06-final-oud-statefulset-storage.mmd`](mermaid/06-final-oud-statefulset-storage.mmd)

```mermaid
flowchart TB
    STS[OUD StatefulSet\n3 replicas observed/recovered]
    H[Headless service / stable DNS]
    STS --> P0[Pod DS 0]
    STS --> P1[Pod DS 1]
    STS --> P2[Pod DS 2]
    H --> P0
    H --> P1
    H --> P2
    P0 --> C0[PVC 0]
    P1 --> C1[PVC 1]
    P2 --> C2[PVC 2]
    C0 --> V0[(NFS directory 0)]
    C1 --> V1[(NFS directory 1)]
    C2 --> V2[(NFS directory 2)]
    P0 <-. replication .-> P1
    P1 <-. replication .-> P2
    NOTE[Shared NFS server does not mean shared OUD database directory]
    NOTE -.-> C1
```

## 7. OUD replication topology

Source: [`mermaid/07-final-oud-replication-topology.mmd`](mermaid/07-final-oud-replication-topology.mmd)

```mermaid
flowchart LR
    D0[OUD DS 0\nLDAP 1389\nAdmin 1444]
    D1[OUD DS 1\nLDAP 1389\nAdmin 1444]
    D2[OUD DS 2\nLDAP 1389\nAdmin 1444]
    D0 <-. replication port recovered as 1898 .-> D1
    D1 <-. replication .-> D2
    D2 <-. replication .-> D0
    V0[(PVC 0)] --> D0
    V1[(PVC 1)] --> D1
    V2[(PVC 2)] --> D2
```

## 8. OUD Proxy routing

Source: [`mermaid/08-final-oud-proxy-routing.mmd`](mermaid/08-final-oud-proxy-routing.mmd)

```mermaid
flowchart LR
    CLIENT[LDAP client]
    LISTENER[OUD Proxy LDAP listener 1389]
    NG[Network group]
    WF[Base-DN workflow]:::verify
    LB[lb-we\nproportional algorithm]
    P0[proxy-we-ds0]
    P1[proxy-we-ds1]
    P2[proxy-we-ds2]
    D0[DS endpoint 0:1389]
    D1[DS endpoint 1:1389]
    D2[DS endpoint 2:1389]
    CLIENT --> LISTENER --> NG --> WF --> LB
    LB --> P0 --> D0
    LB --> P1 --> D1
    LB --> P2 --> D2
    classDef verify stroke-dasharray: 5 5,stroke:#b45309,color:#92400e
```

## 9. OUDSM access flow

Source: [`mermaid/09-final-oudsm-access-flow.mmd`](mermaid/09-final-oudsm-access-flow.mmd)

```mermaid
sequenceDiagram
    actor User as Administrator
    participant LB as OCI applications LB
    participant Router as OpenShift router
    participant Route as OUDSM Route
    participant Service as OUDSM Service
    participant OUDSM as OUDSM/WebLogic
    participant OUD as OUD admin connector

    User->>LB: HTTPS 443
    LB->>Router: TCP 443
    Router->>Route: Match host
    Route->>Service: Re-encrypted HTTPS (VERIFY exact target)
    Service->>OUDSM: 7002 expected / 7001 also exposed
    User->>OUDSM: Authenticate to management UI
    OUDSM->>OUD: Admin connector 1444 over SSL
```

## 10. Successful deployment sequence

Source: [`mermaid/10-final-deployment-sequence.mmd`](mermaid/10-final-deployment-sequence.mmd)

```mermaid
sequenceDiagram
    participant RM as OCI Resource Manager
    participant AI as Assisted Installer
    participant OKD as OKD/OpenShift
    participant NFS as NFS VM
    participant CSI as NFS CSI
    participant OUD as OUD Helm release
    participant Proxy as OUD Proxy
    participant OUDSM as OUDSM Helm release

    RM->>RM: Terraform init, plan/apply, OCI resources
    AI->>OKD: Install 3 control-plane and 3 worker nodes
    OKD->>OKD: Validate nodes, API, console, ingress
    NFS->>NFS: Attach, format, mount 1 TB block volume
    NFS->>NFS: Export /scratch/shared/oud_user_projects
    OKD->>CSI: Install controller and node components
    CSI->>NFS: Validate RWX with test PVC and pod
    OKD->>OUD: Create namespace, secrets, SCC access, Helm install
    OUD->>OUD: Validate 3 DS pods and replication
    OKD->>Proxy: Deploy 2 proxy pods and configure dsconfig routes
    OKD->>OUDSM: Install with replicaCount=1
    OUDSM->>OUDSM: Wait for WebLogic domain readiness
    OKD->>OUDSM: Scale to 2 after validation
    OKD->>OKD: Validate external API, UI, LDAP and persistence
```

## 11. NFS failure recovery

Source: [`mermaid/11-final-nfs-failure-recovery.mmd`](mermaid/11-final-nfs-failure-recovery.mmd)

```mermaid
flowchart TD
    A[Pod mount failure / PVC workload not starting] --> B{NFS server reachable?}
    B -- no --> C[Check OCI security rules, DNS and TCP 2049]
    B -- yes --> D{Is /scratch mounted?}
    D -- no --> E[Inspect lsblk, blkid, findmnt and /etc/fstab]
    E --> F[Correct persistent UUID mount]
    F --> G[mount -a and verify df -h]
    D -- yes --> H[Check exportfs -v and /etc/exports]
    G --> H
    H --> I[exportfs -rav]
    I --> J[restart nfs-server]
    J --> K[Recreate or restart test pod]
    K --> L[Read/write hello-from-nfs]
    L --> M[Verify pvc-* directory on NFS server]
```

## 12. Security trust boundaries

Source: [`mermaid/12-final-security-trust-boundaries.mmd`](mermaid/12-final-security-trust-boundaries.mmd)

```mermaid
flowchart TB
    subgraph PUBLIC[External client zone]
      ADMIN[Administrator]
      LDAP[LDAP clients]
    end
    subgraph OCI[OCI VCN boundary]
      LB[OCI load balancers and listeners]
      subgraph OKD[OKD/OpenShift trust boundary]
        ROUTER[Ingress/router]
        subgraph OUDNS[oudns]
          PROXY[OUD Proxy]
          OUD[OUD DS replicas]
        end
        subgraph OUDSMNS[oudsmns]
          OUDSM[OUDSM]
        end
        SECRETS[Kubernetes Secrets and service accounts]
      end
      subgraph STORAGE[NFS storage boundary]
        NFS[NFS VM]
        BV[(Block Volume)]
      end
    end
    ADMIN --> LB --> ROUTER --> OUDSM
    LDAP --> LB --> PROXY --> OUD
    SECRETS --> PROXY
    SECRETS --> OUD
    SECRETS --> OUDSM
    BV --> NFS --> OUD
    NFS --> OUDSM
```
