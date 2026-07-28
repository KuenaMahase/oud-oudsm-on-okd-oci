# Routing, load balancing, and TLS

## Load-balancer responsibilities

| Entry point | Observed listener | Backends | Purpose |
| --- | ---: | --- | --- |
| API | TCP 6443 | Control-plane nodes | `oc` and Kubernetes API |
| Applications | TCP 443 | Worker nodes running router pods | OpenShift console and application Routes, including OUDSM |
| LDAP | TCP 389 | Worker nodes | NodePort 30089 to OUD Proxy |
| LDAPS | `VERIFY` | Worker nodes | Remembered NodePort path requires final listener evidence |

## Router health recovery

The applications load balancer initially reported unhealthy backends while router pods were uneven or unavailable. The final approach used worker-only router placement, three router replicas, and a readiness-aware health check.

```bash
oc get pods -n openshift-ingress -o wide
oc patch ingresscontroller/default -n openshift-ingress-operator   --type=merge -p '{"spec":{"replicas":3}}'
oc rollout status deployment/router-default -n openshift-ingress --timeout=10m
```

Do not hard-code three router replicas for every cluster. It matched the observed three-worker environment.

## OCI health inspection

```bash
oci lb backend-set-health get   --load-balancer-id "$LB_OCID"   --backend-set-name "$BACKEND_SET"
oci lb health-checker get   --load-balancer-id "$LB_OCID"   --backend-set-name "$BACKEND_SET"
```

OCI supports TCP and HTTP-level health checks. Use application-level readiness where it is supported and proven by the target component.

## TLS

OUDSM notes indicate a re-encrypt Route, preserving TLS between the router and backend. Confirm the live `spec.tls.termination`, `spec.port.targetPort`, and destination CA before reproducing.

## Official references

- OCI load-balancer health management: <https://docs.oracle.com/iaas/Content/Balance/Tasks/load_balancer_health_management.htm>
- OpenShift secured Routes: <https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/ingress_and_load_balancing/routes>
- Kubernetes non-HTTP exposure guidance: <https://kubernetes.io/docs/concepts/services-networking/ingress/>
