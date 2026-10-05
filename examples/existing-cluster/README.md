# Global cluster from an existing cluster

A global cluster named `example-existing-cluster`, made from an Aurora cluster you already have. That cluster becomes the global cluster's primary, keeping its data, engine, version and encryption. Add secondary clusters in other Regions afterward, as the [complete example](https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/tree/main/examples/complete) does.

The cluster's administrator password must not be managed by Aurora in AWS Secrets Manager: AWS refuses to make a global cluster from such a cluster ("MasterUserPassword for the specified source DB cluster is managed by RDS").

If the cluster is managed by Terraform, add this to its `aws_rds_cluster` resource, because AWS sets its `global_cluster_identifier`:

```hcl
lifecycle {
  ignore_changes = [global_cluster_identifier]
}
```

`force_destroy = true` means destroying the global cluster takes the cluster back out of it first. The cluster is not deleted; it becomes a standalone cluster again, with its data.

## Run it

```shell
terraform init
terraform apply -var source_cluster_arn=arn:aws:rds:us-east-1:123456789012:cluster:orders
```

Deletion protection is on. To remove the global cluster, apply with `-var deletion_protection=false` first, then run `terraform destroy` with the same variables.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_source_cluster_arn"></a> [source_cluster_arn](#input_source_cluster_arn)

Description: The ARN of the existing Aurora cluster, such as arn:aws:rds:us-east-1:123456789012:cluster:orders

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_deletion_protection"></a> [deletion_protection](#input_deletion_protection)

Description: Whether AWS refuses to delete the global cluster. Set it to false and apply before terraform destroy.

Type: `bool`

Default: `true`

### Outputs

The following outputs are exported:

#### <a name="output_global_cluster"></a> [global_cluster](#output_global_cluster)

Description: The global cluster's identifier and the engine and version it took from the cluster
<!-- END_TF_DOCS -->
