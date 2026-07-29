# OKD/OpenShift Assisted Installer

## Objective

Use the Red Hat Assisted Installer workflow with OCI infrastructure to create the cluster control plane and worker nodes.

## Successful implementation

Retained evidence shows three Ready control-plane nodes and three Ready worker nodes. Earlier evidence also shows a smaller two-worker state; the final six-node observation takes precedence for the documented topology.

## Smooth-deployment commands

```bash
# Confirm CLI and API compatibility
oc version
oc whoami
oc whoami --show-server

# Verify node readiness, roles, addresses, OS and container runtime
oc get nodes
oc get nodes -o wide
oc describe node <node-name>

# Surface cluster operators that are not available or degraded
oc get clusteroperators
oc get clusteroperators -o custom-columns=NAME:.metadata.name,AVAILABLE:.status.conditions[?\(@.type=="Available"\)].status,DEGRADED:.status.conditions[?\(@.type=="Degraded"\)].status

# Check machine configuration and certificates
oc get machineconfigpools
oc get csr

# Confirm DNS from a disposable pod
oc run dns-check --rm -it --restart=Never   --image=registry.access.redhat.com/ubi9/ubi-minimal   -- getent hosts kubernetes.default.svc
```

## Final corrective lessons

- Validate DNS, API, and route names before deploying Oracle workloads.
- Keep the cluster installation evidence separate from the later workload deployment evidence.
- Avoid keeping bootstrap credentials in notes or repositories.

## Official references

- Assisted Installer: <https://docs.redhat.com/en/documentation/assisted_installer_for_openshift_container_platform/2026/html/installing_openshift_container_platform_with_the_assisted_installer/>
- OpenShift installation overview: <https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/installation_overview/ocp-installation-overview>
