# Terraform module for Amazon Aurora global clusters

Creates an Amazon Aurora global cluster: the container that links Aurora clusters in several AWS Regions into one global database. One primary cluster takes writes, and read-only secondary clusters in other Regions receive a copy of its data. If the primary Region fails, a secondary cluster can take over. See [Using Amazon Aurora global databases](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html).

The module creates the global cluster only. The clusters and their instances are created with `aws_rds_cluster` and `aws_rds_cluster_instance` (or another module), each naming the global cluster; the [complete example](https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/tree/main/examples/complete) shows a two-Region database. The global cluster can also be made from an Aurora cluster you already have.

A global cluster created with only the required inputs is encrypted and protected from deletion.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Engine | Required: Aurora PostgreSQL or Aurora MySQL, or taken from an existing cluster | `engine`, `source_db_cluster_identifier` |
| Engine version | AWS's default version for the engine | `engine_version` |
| Storage encryption | On (AWS's default is off) | `storage_encrypted` |
| Deletion protection | On | `deletion_protection` |
| Member clusters on destroy | Destroy fails while clusters are members | `force_destroy` |
| RDS Extended Support | AWS's default: on, and charged after the end of standard support | `engine_lifecycle_support` |
| First database | None | `database_name` |

## Usage

```hcl
module "global_cluster" {
  source  = "AutomateTheCloud/rds_aurora_global_cluster/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Orders Database"
    environment = "Production"
  }

  global_cluster_identifier = "orders"
  engine                    = "aurora-postgresql"
}

resource "aws_rds_cluster" "primary" {
  cluster_identifier        = "orders-use1"
  global_cluster_identifier = module.global_cluster.metadata.global_cluster.id
  engine                    = module.global_cluster.metadata.global_cluster.engine
  engine_version            = module.global_cluster.metadata.global_cluster.engine_version
  storage_encrypted         = true
  # ... subnet group, password, instances

  lifecycle {
    ignore_changes = [engine_version]
  }
}
```

`details`, `global_cluster_identifier`, and one of `engine` and `source_db_cluster_identifier` are the required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags.

The module uses your default `aws` provider and manages the global cluster from that provider's Region. To use another Region without configuring another provider, set `region`:

```hcl
module "global_cluster" {
  source  = "AutomateTheCloud/rds_aurora_global_cluster/aws"
  version = "~> 1.0"

  region                    = "us-west-2"
  details                   = { scope = "Automate the Cloud", purpose = "Orders Database", environment = "Production" }
  global_cluster_identifier = "orders"
  engine                    = "aurora-postgresql"
}
```

The member clusters can be in any Region that supports global databases, whatever `region` is. With AWS provider 6, each `aws_rds_cluster` can set its own `region` too, so one provider is enough for a whole global database, as the complete example shows.

To use a provider configured for another account, pass it explicitly with `providers = { aws = aws.other_account }`.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the global cluster belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Web Site"           # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a global cluster in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the global cluster, its member clusters, their VPCs and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Web Site"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "global_cluster" {
  source  = "AutomateTheCloud/rds_aurora_global_cluster/aws"
  version = "~> 1.0"

  details                   = local.details
  global_cluster_identifier = "web-site"
  engine                    = "aurora-postgresql"
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Web Site` becomes `web_site`), and `machine`, lowercase letters and numbers only (`website`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.global_cluster.metadata.global_cluster.id` for the global cluster's identifier, or `module.global_cluster.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration. Run it with `terraform init` and `terraform apply`; its README lists the variables it needs.

- [Basic global cluster](https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/tree/main/examples/basic): an empty, encrypted Aurora PostgreSQL global cluster, ready for clusters to join.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/tree/main/examples/complete): a two-Region global database, with a primary cluster in us-east-1, a secondary cluster in us-west-2, a KMS key and an instance in each, and one provider.
- [From an existing cluster](https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/tree/main/examples/existing-cluster): a global cluster made from an Aurora cluster you already have.

## Things to know

### Joining clusters to the global cluster

A cluster joins by naming the global cluster in `global_cluster_identifier`, with the same `engine` and `engine_version`. The first cluster to join is the primary and needs a master user name and password; clusters that join later are read-only secondaries and copy everything from the primary. Add secondaries after the primary has its writer instance, as the complete example does with `depends_on`. Instances must be of a class that supports global databases; `aws rds describe-orderable-db-instance-options --engine aurora-postgresql --query "OrderableDBInstanceOptions[?SupportsGlobalDatabases].DBInstanceClass"` lists them.

Aurora cannot keep the password of a global database's cluster in AWS Secrets Manager: AWS refuses `manage_master_user_password = true` on a cluster that joins a global cluster, and refuses to make a global cluster from a cluster that has it. Pass the password to `master_password_wo`, a write-only argument that Terraform 1.11 and later never save in the state, as the complete example does.

The `metadata` output does not list the member clusters, because they join after the global cluster is created. Take their details from your `aws_rds_cluster` resources.

### Encryption

The module encrypts the global cluster by default; without it, AWS creates an unencrypted one. Every cluster that joins must match: AWS refuses an unencrypted cluster in an encrypted global cluster. Set `storage_encrypted = true` in each `aws_rds_cluster`, and `kms_key_id` to a KMS key in that cluster's own Region, as the complete example does. Encryption cannot be changed later: changing `storage_encrypted` replaces the global cluster.

### Engine upgrades

Change `engine_version` to upgrade the global cluster and every member cluster in place, to a new minor or major version. Give each member `aws_rds_cluster` `lifecycle { ignore_changes = [engine_version] }`, so Terraform does not try to upgrade it a second time; without it, the AWS provider documentation says the upgrade fails with "Provider produced inconsistent final plan".

An upgrade needs a primary cluster. On a global cluster with no members, AWS refuses it ("In order to be upgraded, the global cluster must have a Primary cluster"), and the AWS provider keeps retrying until the `update` timeout, two hours by default, before it fails. Choose the version when the global cluster is created instead, or add the primary cluster first.

### RDS Extended Support

When a major version reaches the end of standard support, AWS by default keeps the global cluster on it under [RDS Extended Support](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/extended-support.html) and charges for it. Set `engine_lifecycle_support = "open-source-rds-extended-support-disabled"` to have AWS upgrade the major version instead. AWS sets this only when the global cluster is created; the module ignores later changes to it, because AWS would keep the old value.

### Deleting the global cluster

Deletion protection is on by default. `terraform destroy`, and any change that replaces the global cluster, fails with "Cannot delete protected Global Cluster" until you set `deletion_protection = false` and apply.

AWS also refuses to delete a global cluster that still has member clusters. When your configuration destroys the member clusters too, Terraform deletes them first. Otherwise, set `force_destroy = true`: the module then takes each member out of the global cluster before deleting it, and the members remain as standalone clusters, with their data.

Changing `global_cluster_identifier`, `engine`, `storage_encrypted`, `database_name` or `region` replaces the global cluster.

### From an existing cluster

With `source_db_cluster_identifier`, the global cluster is made from an Aurora cluster you already have, which becomes its primary cluster with its data, engine, version and encryption. Its password must not be managed by Aurora in Secrets Manager (see above). If that cluster is managed by Terraform, add `lifecycle { ignore_changes = [global_cluster_identifier] }` to it: AWS sets the cluster's `global_cluster_identifier`, and naming the global cluster there instead would be a dependency cycle. The module ignores later changes to `source_db_cluster_identifier`, so the global cluster is not replaced when the source cluster's ARN changes.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_global_cluster_identifier"></a> [global_cluster_identifier](#input_global_cluster_identifier)

Description: The global cluster's name, such as `orders`. It must be unique among the global clusters in the account, and be 1 to 63 lowercase letters, numbers and hyphens, starting with a letter, with no two hyphens in a row and no hyphen at the end. Changing it replaces the global cluster.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_database_name"></a> [database_name](#input_database_name)

Description: The name of a database for Aurora to create in the primary cluster when it joins the global cluster, such as `app`. Defaults to `null`: no database is created, and you create databases yourself after connecting. Only with `engine`; a global cluster made from `source_db_cluster_identifier` keeps the source cluster's databases. Changing it replaces the global cluster.

Type: `string`

Default: `null`

#### <a name="input_deletion_protection"></a> [deletion_protection](#input_deletion_protection)

Description: Whether AWS refuses to delete the global cluster. Defaults to `true`, so a plan that would destroy or replace it fails at apply. To delete the global cluster, set it to `false` and apply first. It protects only the global cluster: each member cluster has its own `deletion_protection`. Changed in place.

Type: `bool`

Default: `true`

#### <a name="input_engine"></a> [engine](#input_engine)

Description: The database engine of a new global cluster: `aurora-postgresql` (Aurora PostgreSQL-Compatible Edition) or `aurora-mysql` (Aurora MySQL-Compatible Edition). The clusters you add to the global cluster must use the same engine. Exactly one of `engine` and `source_db_cluster_identifier` must be set. Changing it replaces the global cluster.

Type: `string`

Default: `null`

#### <a name="input_engine_lifecycle_support"></a> [engine_lifecycle_support](#input_engine_lifecycle_support)

Description: What happens when the engine's major version reaches the end of standard support:

- `open-source-rds-extended-support` - The global cluster stays on its version under [Amazon RDS Extended Support](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/extended-support.html), which AWS charges for.
- `open-source-rds-extended-support-disabled` - AWS upgrades the major version itself after the end of standard support, so there is no Extended Support charge.

Defaults to `null`, which AWS treats as `open-source-rds-extended-support`. AWS sets it only when the global cluster is created, so a later change has no effect: the module ignores it after creation.

Type: `string`

Default: `null`

#### <a name="input_engine_version"></a> [engine_version](#input_engine_version)

Description: The engine version, such as `16.6` for Aurora PostgreSQL or `8.0.mysql_aurora.3.08.2` for Aurora MySQL. Not every version supports global databases; `aws rds describe-db-engine-versions --engine aurora-postgresql --query "DBEngineVersions[?SupportsGlobalDatabases].EngineVersion"` lists those that do. Defaults to `null`: AWS chooses its default version for `engine`, or keeps the source cluster's.

Changing it upgrades the global cluster and every member cluster in place; a new major version is allowed. Member clusters managed with `aws_rds_cluster` need `lifecycle { ignore_changes = [engine_version] }`, or the upgrade fails with "Provider produced inconsistent final plan". An upgrade needs a primary cluster: on a global cluster with no members, AWS refuses it and the provider retries until the `update` timeout. If the version changes outside Terraform, the next plan shows it changing back; set the input to the running version.

Type: `string`

Default: `null`

#### <a name="input_force_destroy"></a> [force_destroy](#input_force_destroy)

Description: Whether destroying the global cluster first removes its member clusters from it. Defaults to `false`: AWS refuses to delete a global cluster that still has members, so remove them first. With `true`, the member clusters are not deleted; each one becomes a standalone cluster. Changed in place.

Type: `bool`

Default: `false`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to manage the global cluster from, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. A global cluster is not tied to one Region: its member clusters can be in any Region that supports global databases, and each one names the global cluster by its identifier. The primary cluster is often in this Region. Changing it replaces the global cluster.

Type: `string`

Default: `null`

#### <a name="input_source_db_cluster_identifier"></a> [source_db_cluster_identifier](#input_source_db_cluster_identifier)

Description: The ARN of an existing Aurora cluster to make the global cluster's primary cluster, such as `arn:aws:rds:us-east-1:123456789012:cluster:orders`. The global cluster takes its engine, version, encryption and databases from it. Exactly one of `engine` and `source_db_cluster_identifier` must be set.

With this, `storage_encrypted` and `database_name` are not used, and `engine_version` is best left `null` until the global cluster exists. The module ignores later changes to this input, so the global cluster is never replaced because the source cluster's ARN changed. If the source cluster is managed with `aws_rds_cluster`, give it `lifecycle { ignore_changes = [global_cluster_identifier] }`.

Type: `string`

Default: `null`

#### <a name="input_storage_encrypted"></a> [storage_encrypted](#input_storage_encrypted)

Description: Whether the global cluster's storage is encrypted. Defaults to `true`; AWS's own default is `false`. Every cluster added to an encrypted global cluster must be encrypted too, with a KMS key in its own Region (`kms_key_id` in `aws_rds_cluster`). Not used with `source_db_cluster_identifier`: the global cluster has the source cluster's encryption. Changing it replaces the global cluster.

Type: `bool`

Default: `true`

#### <a name="input_timeouts"></a> [timeouts](#input_timeouts)

Description: How long Terraform waits for each operation before failing:

- `create` - (Optional) Defaults to `180m`. With `source_db_cluster_identifier`, it includes making the source cluster the primary.
- `update` - (Optional) Defaults to `120m`. An engine upgrade upgrades every member cluster.
- `delete` - (Optional) Defaults to `120m`.

Type:

```hcl
object({
    create = optional(string, "180m")
    update = optional(string, "120m")
    delete = optional(string, "120m")
  })
```

Default: `{}`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
- `global_cluster` - The global cluster:

  - `id` and `global_cluster_identifier` - The global cluster's name. Pass it to `global_cluster_identifier` in each `aws_rds_cluster` that joins the global cluster.
  - `arn` - The global cluster's ARN.
  - `global_cluster_resource_id` - An identifier that never changes, which AWS CloudTrail shows when a member cluster uses its KMS key.
  - `endpoint` - The global writer endpoint: a DNS name that always points to the writer instance in the current primary cluster.
  - `engine`, `engine_version` and `engine_version_actual` - The engine, the version as configured, and the version running.
  - `engine_lifecycle_support`, `storage_encrypted`, `database_name`, `deletion_protection` and `force_destroy` - The settings the global cluster has.
  - `source_db_cluster_identifier` - The source cluster's ARN, as passed in; `null` without one.
  - `region`, `tags` and `tags_all`.

It does not list the member clusters: they join after the global cluster is created, so the list would change on the next plan. Read them from the clusters themselves, or with `aws rds describe-global-clusters`.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
