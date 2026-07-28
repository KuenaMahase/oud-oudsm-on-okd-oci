# Limitations and future work

## Current limitations

- The historical environment is not connected to this repository's CI.
- Exact OUD chart revision and live rendered manifest are not yet recovered.
- Exact OUDSM PVC capacity and final Route target remain unresolved.
- Final external LDAPS path is not promoted to verified.
- The NFS server is a single shared dependency in the recovered topology.
- Raw screenshots are not published because of sensitive identifiers.

## Prioritized future work

1. Recover `helm get values --all` and `helm get manifest` exports from the original releases.
2. Recover the final OUDSM Route and Service YAML.
3. Recover listener and NodePort evidence for LDAPS.
4. Replace broad SCC grants with reviewed custom SCCs where possible.
5. Add tested backup and restore procedures for OUD and OUDSM.
6. Add observability evidence only if the historical ELK deployment can be verified.
7. Re-run the sanitized reference deployment in a disposable lab and record new evidence separately from the historical evidence.


## Official references

- Oracle OUD Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/oudku/
- Oracle OUDSM Kubernetes documentation: https://docs.oracle.com/en/middleware/idm/unified-directory/14.1.2/osmku/
- Oracle `fmw-kubernetes`: https://github.com/oracle/fmw-kubernetes
- Red Hat/OpenShift documentation: https://docs.redhat.com/en/documentation/assisted_installer_for_openshift_container_platform/2026/html/installing_openshift_container_platform_with_the_assisted_installer/
- Kubernetes documentation: https://kubernetes.io/docs/concepts/storage/storage-classes/
- Kubernetes NFS CSI driver: https://github.com/kubernetes-csi/csi-driver-nfs
- OCI documentation: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm

