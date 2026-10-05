# Basic global cluster

An empty, encrypted Aurora PostgreSQL global cluster named `example-basic`, managed from `us-east-1`, with deletion protection on. AWS chooses the engine version. The output shows its identifier, ARN, engine and version.

Clusters join it later by naming it in `global_cluster_identifier`, with the same engine and version. The [complete example](https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/tree/main/examples/complete) shows how.

Charges come from the clusters and instances that join, not from this example on its own. See [Amazon Aurora pricing](https://aws.amazon.com/rds/aurora/pricing/).

## Run it

```shell
terraform init
terraform apply
```

Deletion protection is on, so remove it in two steps:

```shell
terraform apply -var deletion_protection=false
terraform destroy -var deletion_protection=false
```

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_deletion_protection"></a> [deletion_protection](#input_deletion_protection)

Description: Whether AWS refuses to delete the global cluster. Set it to false and apply before terraform destroy.

Type: `bool`

Default: `true`

### Outputs

The following outputs are exported:

#### <a name="output_global_cluster"></a> [global_cluster](#output_global_cluster)

Description: The global cluster's identifier, ARN, engine and version
<!-- END_TF_DOCS -->
