# Project overview

## Objective

Reconstruct and document the successful deployment of Oracle Unified Directory, OUD Proxy, and OUDSM on an OCI-hosted OKD/OpenShift cluster without exposing confidential infrastructure.

## Successful implementation

The retained evidence supports an OCI Resource Manager-based cluster foundation, a six-node cluster, OCI load balancers, a self-managed NFS server backed by a block volume, NFS CSI dynamic provisioning, OUD directory replicas, two OUD Proxy pods, and an OUDSM management layer.

## Portfolio value

The project demonstrates cloud networking, Kubernetes/OpenShift administration, stateful workloads, storage, identity infrastructure, load balancing, TLS, incident analysis, and evidence-led documentation.

## Boundary

This repository is not a claim that the original environment is still running. It distinguishes historical proof from current reference configuration and labels unresolved facts.


## Official references

- Oracle OUD Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudku/
- Oracle OUDSM Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/osmku/
- Oracle `fmw-kubernetes`: https://github.com/oracle/fmw-kubernetes
- Red Hat/OpenShift documentation: https://docs.redhat.com/en/documentation/assisted_installer_for_openshift_container_platform/2026/html/installing_openshift_container_platform_with_the_assisted_installer/
- Kubernetes documentation: https://kubernetes.io/docs/concepts/storage/storage-classes/
- Kubernetes NFS CSI driver: https://github.com/kubernetes-csi/csi-driver-nfs
- OCI documentation: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm

