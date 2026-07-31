# Historical source note

> Sanitized working note. Treat commands and values as historical evidence, not a current production runbook.


# 📘 Documentation: Configuring `oud-oudsm-elk-cluster-openshift_apps_lb` in OCI

## 🔹 Purpose of `apps_lb`

* **Load balancer name:** `oud-oudsm-elk-cluster-openshift_apps_lb`
* **Type:** Private LB (IP 10.x.x.x inside cluster VCN).
* **Function:**

  * Routes all OpenShift **application traffic** (`*.apps.<cluster-domain>`) through the **Ingress Router pods**.
  * This includes:

    * OpenShift Web Console (`console-openshift-console.apps...`)
    * OAuth (`oauth-openshift.apps...`)
    * Monitoring (Grafana, Prometheus, Alertmanager routes)
    * Any user-deployed apps (`myapp.apps...`).
* **Backends:** Your **worker nodes**.

  * Router pods run on workers, so LB must forward HTTP/HTTPS traffic to worker IPs.

---

## 🔹 Initial Symptoms

1. **LB health status = Critical**

   * Many worker backends failed health checks (`Critical - Connection failed` or `Status code mismatch`).
   * Only 1–2 nodes ever showed `OK`.
2. **Ingress router pods unstable**

   * Most pods in `openshift-ingress` namespace had `ContainerStatusUnknown`.
   * Only a couple ran successfully on workers.

---

## 🔹 Troubleshooting Steps

### 1. Verified Router Pods

```bash
oc get pods -n openshift-ingress -o wide
```

* Saw router pods stuck in `ContainerStatusUnknown` or `Pending`.
* Found that routers were scheduled **unevenly** (most stuck on one node).

---

### 2. Fixed LB Health Checks

* OCI by default tested **TCP 80/443 only** → not enough for OpenShift routers.
* Correct config needed **HTTP/HTTPS probes** with router readiness endpoint.

✅ Updated **Backend Set Health Checks**:

* **For HTTP (port 80):**

  * Protocol: `HTTP`
  * Path: `/healthz/ready`
  * Interval: `10s`
  * Timeout: `5s`
  * Retries: `3`
* **For HTTPS (port 443):**

  * Protocol: `HTTPS`
  * Path: `/healthz/ready`
  * Interval: `10s`
  * Timeout: `5s`
  * Retries: `3`

👉 Result: LB could properly detect healthy routers instead of failing on blank TCP probes.

---

### 3. Adjusted Router Pod Replicas

Originally replicas were mismatched (some Pending).

* Scaled routers to **3 replicas** to match 3 worker nodes:

```bash
oc -n openshift-ingress-operator patch ingresscontroller default \
  --type=merge -p '{"spec":{"replicas":3}}'
```

---

### 4. Cleaned Pending Pods

* Deleted leftover Pending router pod:

```bash
oc -n openshift-ingress delete pod <pending-router-pod>
```

* Operator rescheduled correctly.

---

### 5. Verified Worker-Only Scheduling

* Confirmed router pods were only assigned to **workers**, not masters:

```bash
oc get pods -n openshift-ingress -o wide
```

Output showed routers distributed across 3 workers (`02-00-17-00-xx-xx`).

* None scheduled on master nodes → good practice since masters should run control plane only.

---

## 🔹 Final State

* **`apps_lb` backends:** All 3 worker nodes reporting `Healthy`.
* **Router pods:** 3 replicas, evenly spread across workers.
* **Masters:** No router pods, reserved for API/control plane only.
* **Console:** Accessible externally via LB → `console-openshift-console.apps...` works.

---

## 🔹 Key Lessons

1. `apps_lb` is critical for **all user + console traffic**; must point to workers.
2. OCI health checks must target `/healthz/ready` for OpenShift routers.
3. Router replicas should = number of worker nodes (for HA).
4. Avoid scheduling routers on masters — only use workers for Ingress.
5. Pending pods often mean replica count > schedulable nodes.

---

✅ With this setup, your **OpenShift Web Console, OAuth, and app routes** are stable, backed by a healthy OCI Load Balancer pointing only to worker nodes.



