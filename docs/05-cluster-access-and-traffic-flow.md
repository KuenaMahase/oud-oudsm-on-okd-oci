# Cluster access and traffic flow

## Observed paths

### Kubernetes API

```text
oc client -> OCI TCP 6443 listener -> control-plane backends -> kube-apiserver
```

### OpenShift console and application ingress

```text
browser -> OCI TCP 443 listener -> worker nodes -> router pods -> OpenShift Route -> Service -> Pod
```

### LDAP

```text
LDAP client -> OCI TCP 389 listener -> worker NodePort 30089
-> oud-proxy-ldap-public -> OUD Proxy pod -> selected OUD directory server
```

The LDAP flow is supported by retained OCI and `oc get svc` screenshots. The external LDAPS path remains `VERIFY`.

## Useful commands

```bash
# API and route inventory
oc get routes -A
oc get routes -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOST:.spec.host,SERVICE:.spec.to.name,TERMINATION:.spec.tls.termination

# Services, ports and endpoint slices
oc get svc -A
oc get endpointslices.discovery.k8s.io -A
oc describe svc -n oudns oud-proxy-ldap-public

# Router placement and ingress configuration
oc get pods -n openshift-ingress -o wide
oc get ingresscontroller/default -n openshift-ingress-operator -o yaml
oc get route -n openshift-console console -o yaml

# Network troubleshooting from inside the cluster
oc run netcheck --rm -it --restart=Never   --image=registry.access.redhat.com/ubi9/ubi-minimal -- sh
```

## Official references

- OpenShift Routes: https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/ingress_and_load_balancing/routes
- Kubernetes Services and NodePort: https://kubernetes.io/docs/concepts/services-networking/service/
- OCI load balancers: https://docs.oracle.com/en-us/iaas/Content/Balance/Tasks/managingloadbalancer.htm
