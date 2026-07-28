# Recovered deployment contract

This is the governing contract for every document and diagram.

## Successful-deployment-only rule

Only a configuration directly supported by retained evidence is described as successfully deployed. Official documentation can explain behavior but cannot prove historical presence.

## Confirmed or strongly observed

- OCI Resource Manager executed Terraform with the OCI provider and managed VCN, gateway, NSG, image, and cluster resources.
- Three control-plane and three worker nodes were observed Ready.
- An OCI load balancer had listeners for TCP 6443, TCP 443, and TCP 389.
- A NodePort Service named `oud-proxy-ldap-public` exposed service port 389 on node port 30089.
- Two OUD Proxy pods were observed Running.
- The NFS server used an attached 1 TB block volume and exported `/scratch/shared/oud_user_projects`.
- NFS CSI dynamic provisioning passed a write/read test.
- One cluster-scoped StorageClass named `nfs-rwx` is the final storage model.
- Three OUD LDAP extensions and proportional routes were configured on an OUD Proxy instance.

## Verify before promoting

- Exact final OUD Helm chart revision and image digest.
- Exact final OUDSM PVC capacity and Route target port.
- Completed network-group-to-workflow mapping output on both OUD Proxy pods.
- Final external LDAPS listener and node-port path.
- ELK runtime status; it is excluded from the final core architecture unless proof is added.


## Official references

- Oracle OUD Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudku/
- Oracle OUDSM Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/osmku/
- Oracle `fmw-kubernetes`: https://github.com/oracle/fmw-kubernetes
- Red Hat/OpenShift documentation: https://docs.redhat.com/en/documentation/assisted_installer_for_openshift_container_platform/2026/html/installing_openshift_container_platform_with_the_assisted_installer/
- Kubernetes documentation: https://kubernetes.io/docs/concepts/storage/storage-classes/
- Kubernetes NFS CSI driver: https://github.com/kubernetes-csi/csi-driver-nfs
- OCI documentation: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm

