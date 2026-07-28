# Problem and objectives

## Problem

Traditional directory deployments are commonly tied to long-lived hosts, manual storage preparation, and tightly coupled administration paths. The project explored how Oracle directory services could be deployed on a container platform while retaining persistent state, replication, controlled external access, and recoverable operations.

## Objectives

- Deploy OKD/OpenShift on OCI using the Assisted Installer and OCI Resource Manager integration.
- Operate OUD as a replicated stateful workload.
- Place OUD Proxy in front of the directory servers for request routing.
- Provide OUDSM as a browser-based management interface.
- Use dynamically provisioned NFS-backed PVCs.
- Validate API, UI, LDAP, storage, and recovery paths.
- Record the final successful path rather than combining every attempted approach.


## Official references

- Oracle OUD Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudku/
- Oracle OUDSM Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/osmku/
- Oracle `fmw-kubernetes`: https://github.com/oracle/fmw-kubernetes
- Red Hat/OpenShift documentation: https://docs.redhat.com/en/documentation/assisted_installer_for_openshift_container_platform/2026/html/installing_openshift_container_platform_with_the_assisted_installer/
- Kubernetes documentation: https://kubernetes.io/docs/concepts/storage/storage-classes/
- Kubernetes NFS CSI driver: https://github.com/kubernetes-csi/csi-driver-nfs
- OCI documentation: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm

