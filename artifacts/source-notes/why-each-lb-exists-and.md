# Historical source note

> Sanitized working note. Treat commands and values as historical evidence, not a current production runbook.

Why each LB exists (and how it’s configured)

Apps/Ingress LB (<apps-lb-private-ip>, private)
Fronts *.apps.<cluster> (console, OAuth, user apps).
Listeners: TCP 80/443 (L4 passthrough).
Backends: only the workers that run router pods.
Health checks:

HTTP → port 80, path /healthz/ready, 10s/5s/3

TCP → port 443 (reliable for TLS passthrough)

API LB (<api-lb-private-ip>, private)
External/admin access to Kubernetes API :6443.
Backends: masters only.
HC: TCP 6443.

API Internal LB (<api-int-lb-private-ip>, private)
Internal node↔control-plane (:6443 API, :22623 MCS) for bootstrap and ongoing node ops.
Backends: masters only.
HC: TCP 6443/22623.

OUD Proxy LB (<public-ldap-lb-ip>, public)
Separate public entry for OUD/OUDSM proxy traffic (e.g., :8443).
Not related to OpenShift ingress.

Why routers run on workers (not masters)

Masters host control-plane components (API, etcd, scheduler); keep them isolated.

Ingress routers are application-plane and scale with workers.

You set replicas: 3 on the IngressController so each worker runs one router pod; the apps LB backends now match exactly those three worker IPs.

| Component / Operator              | Namespace                                        | Default Replicas      | Purpose                                                               | Notes / Scaling Guidance                                                        |
| --------------------------------- | ------------------------------------------------ | --------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **Ingress Router**                | `openshift-ingress`                              | **2**                 | Exposes cluster routes (`*.apps.<cluster>`). Runs HA pair by default. | Scale to match number of workers if you want 1 per worker (`spec.replicas`).    |
| **Console** (Web UI)              | `openshift-console`                              | **2**                 | OpenShift Web Console.                                                | 2 gives HA for UI; can scale to 3 if 3 workers.                                 |
| **OAuth (Authentication pods)**   | `openshift-authentication`                       | **2**                 | Handles OAuth logins (via console, CLI, etc.).                        | Always keep >=2 for login HA.                                                   |
| **OAuth-Proxy (console-backend)** | `openshift-console` + `openshift-authentication` | **2**                 | Sits in front of console to enforce OAuth login.                      | Mirrors console pods.                                                           |
| **Monitoring stack**              | `openshift-monitoring`                           | varies (mostly **2**) | Prometheus, Alertmanager, Grafana.                                    | Prometheus has 2 replicas; Alertmanager 3; Grafana 2. Scaled for HA by default. |
| **API Server** (`kube-apiserver`) | `openshift-kube-apiserver`                       | **3** (1 per master)  | Kubernetes API (6443).                                                | Runs on *each master node*, not worker. Always 3 in HA control plane.           |
| **Controller Manager**            | `openshift-kube-controller-manager`              | **3** (1 per master)  | Manages workloads, deployments, etc.                                  | Also runs on masters by design.                                                 |
| **Scheduler**                     | `openshift-kube-scheduler`                       | **3** (1 per master)  | Schedules pods onto nodes.                                            | 3 copies for HA, leader-election used.                                          |

🔹 Key Takeaways

Routers, console, OAuth: default 2 replicas, can be scaled to match workers if you want N+1 HA.

API, controllers, schedulers: tied to masters, always 3 (1 per master node).

Monitoring: slightly mixed, but all core pieces are at least 2–3 pods by default.

Best practice: At least 2 of everything critical; match workers if you want resilience against a full worker outage.

⚡ So in your cluster with 3 masters + 3 workers:

You already scaled routers to 3 → good, one per worker.

Console & OAuth are still 2 by default → optional to scale to 3.

API / control plane are 3 by design → nothing to do there.




