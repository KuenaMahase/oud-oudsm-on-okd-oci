# Personal contribution

## What I implemented

- Investigated and documented the OCI/OpenShift architecture.
- Used the Assisted Installer and OCI Resource Manager workflow to establish the cluster.
- Validated cluster access and node health.
- Provisioned and repaired NFS-backed persistent storage.
- Installed and validated the NFS CSI driver.
- Prepared Oracle registry access and Helm values.
- Deployed OUD and worked with its services, persistence, and replication.
- Deployed two OUD Proxy instances and configured extensions, workflow elements, and proportional routes.
- Deployed OUDSM and worked through persistence, initialization, routing, and scaling concerns.
- Diagnosed load-balancer, ingress, storage, SCC, YAML, naming, and workflow issues.

## What the platforms provided

- Oracle provided OUD/OUDSM images, product behavior, and Helm charts.
- Red Hat/OpenShift provided the cluster, routing, SCC, service, and operational abstractions.
- Kubernetes provided StatefulSets, Services, PVCs, StorageClasses, and CSI integration.
- OCI provided compute, VCN, block volumes, DNS, load balancers, and Resource Manager.

## AI assistance disclosure

AI assisted with searching historical conversations, comparing conflicting notes, designing sanitized diagrams, drafting scripts, and structuring documentation. Claims remain classified according to retained evidence rather than being accepted because an AI generated them.


## Official references

- Oracle OUD Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudku/
- Oracle OUDSM Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/osmku/
- Oracle `fmw-kubernetes`: https://github.com/oracle/fmw-kubernetes
- Red Hat/OpenShift documentation: https://docs.redhat.com/en/documentation/assisted_installer_for_openshift_container_platform/2026/html/installing_openshift_container_platform_with_the_assisted_installer/
- Kubernetes documentation: https://kubernetes.io/docs/concepts/storage/storage-classes/
- Kubernetes NFS CSI driver: https://github.com/kubernetes-csi/csi-driver-nfs
- OCI documentation: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm

