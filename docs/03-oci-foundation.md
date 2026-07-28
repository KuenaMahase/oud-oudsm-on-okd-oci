# OCI foundation

## Objective

Provision the OCI networking, compute, DNS, load-balancing, image, and tagging resources required by the OKD/OpenShift installation.

## Successful implementation

The retained OCI Resource Manager log shows successful Terraform initialization with the OCI provider, followed by reads and refreshes of availability domains, fault domains, VCN, gateways, security lists, network security groups, cluster images, and related resources. The supplied `oci-openshift-1.2.1` archive is treated as the upstream stack source used by Resource Manager, not as code authored in this repository.

## Useful evidence-recovery commands

```bash
# Get Resource Manager job metadata
oci resource-manager job get --job-id "$JOB_OCID"

# Download raw job logs
oci resource-manager job get-job-logs-content   --job-id "$JOB_OCID"   --file resource-manager-job.log

# List Terraform outputs retained by the job
oci resource-manager job-output-summary list-job-outputs   --job-id "$JOB_OCID" --all
```

## Useful OCI load-balancer inspection commands

```bash
oci lb backend-set list --load-balancer-id "$LB_OCID" --all
oci lb backend-set-health get   --load-balancer-id "$LB_OCID"   --backend-set-name "$BACKEND_SET"
oci lb health-checker get   --load-balancer-id "$LB_OCID"   --backend-set-name "$BACKEND_SET"
```

These commands are operational helpers from official OCI tooling. Their presence here is not proof that every command was used during the original deployment.

## Validation

- Resource Manager job status completed successfully.
- Job logs show provider initialization.
- Cluster compute and networking resources are visible in OCI evidence.
- No OCIDs are retained in the public repository.

## Official references

- OCI Resource Manager: <https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm>
- Resource Manager job logs: <https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/get-job-logs-content.htm>
- OCI load balancers: <https://docs.oracle.com/en-us/iaas/Content/Balance/Tasks/managingloadbalancer.htm>
- OCI load-balancer health policies: <https://docs.oracle.com/iaas/Content/Balance/Tasks/load_balancer_health_management.htm>
