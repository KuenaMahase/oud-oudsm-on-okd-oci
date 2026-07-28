# Terraform reference

The historical OCI cluster was provisioned through an OCI Resource Manager stack based on an Oracle/Red Hat OCI OpenShift distribution. The separately uploaded local `oud-oci.zip` contains mostly empty Terraform files and is not presented as the working historical configuration.

Any future Terraform added here must begin with:

> **REFERENCE RECONSTRUCTION — NOT THE ORIGINAL HISTORICAL TERRAFORM**

Do not claim `terraform plan` or `terraform apply` success unless it was actually executed against a disposable lab.
