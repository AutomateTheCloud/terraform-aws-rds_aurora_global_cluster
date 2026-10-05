# Complete: a two-Region global database

An Aurora PostgreSQL global database across two Regions, with one AWS provider:

- The global cluster `example-complete`, encrypted, with a first database named `app`, deletion protection on, and RDS Extended Support turned off.
- A KMS key in each Region, for the clusters' storage.
- The primary cluster in `us-east-1`, with one `db.r6g.large` writer instance. The administrator password is passed to a write-only argument, so it is never saved in the Terraform state. Aurora cannot keep a global database's password in AWS Secrets Manager.
- A read-only secondary cluster in `us-west-2`, with one `db.r6g.large` instance, added once the primary has its writer.

Each resource names its Region with `region`, which needs AWS provider 6. Both clusters ignore `engine_version` changes: an upgrade is made through the global cluster's `engine_version` input. Nothing is publicly accessible.

You need a DB subnet group in each Region, with private subnets in at least two Availability Zones, and Terraform 1.11 or later. Creating it takes about 15 minutes.

**This example costs money**: two `db.r6g.large` instances, storage, data copied between Regions, and two KMS keys. See [Amazon Aurora pricing](https://aws.amazon.com/rds/aurora/pricing/). Destroy it when you are done.

## Run it

```shell
terraform init
export TF_VAR_master_password='choose-a-password'
terraform apply \
  -var primary_db_subnet_group_name=my-subnets-use1 \
  -var secondary_db_subnet_group_name=my-subnets-usw2
```

Deletion protection is on for the global cluster and both clusters. To remove everything, apply with `-var deletion_protection=false` first, then run `terraform destroy` with the same variables. Terraform deletes the instances and clusters before the global cluster; it takes about 25 minutes. The KMS keys are scheduled for deletion after 7 days.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.11)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_master_password"></a> [master_password](#input_master_password)

Description: The database administrator's password: at least 8 characters, without /, ", @ or spaces

Type: `string`

#### <a name="input_primary_db_subnet_group_name"></a> [primary_db_subnet_group_name](#input_primary_db_subnet_group_name)

Description: The name of a DB subnet group in us-east-1

Type: `string`

#### <a name="input_secondary_db_subnet_group_name"></a> [secondary_db_subnet_group_name](#input_secondary_db_subnet_group_name)

Description: The name of a DB subnet group in us-west-2

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_deletion_protection"></a> [deletion_protection](#input_deletion_protection)

Description: Whether AWS refuses to delete the global cluster and both clusters. Set it to false and apply before terraform destroy.

Type: `bool`

Default: `true`

### Outputs

The following outputs are exported:

#### <a name="output_global_database"></a> [global_database](#output_global_database)

Description: The global writer endpoint and each cluster's endpoints
<!-- END_TF_DOCS -->
