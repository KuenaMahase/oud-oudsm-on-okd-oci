# Decisions and trade-offs

## Self-managed NFS VM over a managed filesystem

The successful environment used a self-managed NFS VM backed by a block volume. This gave direct control and worked with NFS CSI dynamic subdirectories. The trade-off was responsibility for mount ordering, exports, operating-system patching, capacity, and availability.

## Dynamic NFS CSI over static PVs

Dynamic provisioning reduced manual PV management and created separate `pvc-*` directories. A single StorageClass served multiple namespaces. The downside is that the NFS server remains a shared dependency.

## OUD replication plus persistent volumes

Replication and storage solve different problems. OUD replication synchronizes directory data; PVCs preserve each replica's local database across pod replacement.

## NodePort for LDAP

The observed LDAP path used a NodePort behind an OCI listener. This matches Kubernetes guidance that non-HTTP protocols commonly use NodePort or LoadBalancer rather than HTTP Ingress. The trade-off is explicit management of listener, security, health checks, and worker-node reachability.

## One OUDSM replica for initialization

A single initial replica prevented competing first-domain initialization against shared storage. Scaling occurred after readiness.


## Official references

- Oracle OUD Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudku/
- Oracle OUDSM Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/osmku/
- Oracle `fmw-kubernetes`: https://github.com/oracle/fmw-kubernetes
- Red Hat/OpenShift documentation: https://docs.redhat.com/en/documentation/assisted_installer_for_openshift_container_platform/2026/html/installing_openshift_container_platform_with_the_assisted_installer/
- Kubernetes documentation: https://kubernetes.io/docs/concepts/storage/storage-classes/
- Kubernetes NFS CSI driver: https://github.com/kubernetes-csi/csi-driver-nfs
- OCI documentation: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm

