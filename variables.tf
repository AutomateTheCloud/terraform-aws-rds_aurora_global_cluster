# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "database_name" {
  description = <<-EOT
    The name of a database for Aurora to create in the primary cluster when it joins the global cluster, such as `app`. Defaults to `null`: no database is created, and you create databases yourself after connecting. Only with `engine`; a global cluster made from `source_db_cluster_identifier` keeps the source cluster's databases. Changing it replaces the global cluster.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.database_name == null || try(trimspace(var.database_name) != "", false)
    error_message = "database_name must not be empty. Leave it null for no database."
  }

  validation {
    condition     = var.database_name == null || var.source_db_cluster_identifier == null
    error_message = "database_name cannot be used with source_db_cluster_identifier: the global cluster keeps the source cluster's databases."
  }
}

variable "deletion_protection" {
  description = <<-EOT
    Whether AWS refuses to delete the global cluster. Defaults to `true`, so a plan that would destroy or replace it fails at apply. To delete the global cluster, set it to `false` and apply first. It protects only the global cluster: each member cluster has its own `deletion_protection`. Changed in place.
  EOT
  type        = bool
  default     = true
  nullable    = false
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "engine" {
  description = <<-EOT
    The database engine of a new global cluster: `aurora-postgresql` (Aurora PostgreSQL-Compatible Edition) or `aurora-mysql` (Aurora MySQL-Compatible Edition). The clusters you add to the global cluster must use the same engine. Exactly one of `engine` and `source_db_cluster_identifier` must be set. Changing it replaces the global cluster.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.engine == null || contains(["aurora-mysql", "aurora-postgresql"], coalesce(var.engine, "-"))
    error_message = "engine must be aurora-mysql or aurora-postgresql."
  }

  validation {
    condition     = (var.engine == null) != (var.source_db_cluster_identifier == null)
    error_message = "Set exactly one of engine (a new, empty global cluster) and source_db_cluster_identifier (a global cluster made from an existing Aurora cluster)."
  }
}

variable "engine_lifecycle_support" {
  description = <<-EOT
    What happens when the engine's major version reaches the end of standard support:

    - `open-source-rds-extended-support` - The global cluster stays on its version under [Amazon RDS Extended Support](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/extended-support.html), which AWS charges for.
    - `open-source-rds-extended-support-disabled` - AWS upgrades the major version itself after the end of standard support, so there is no Extended Support charge.

    Defaults to `null`, which AWS treats as `open-source-rds-extended-support`. AWS sets it only when the global cluster is created, so a later change has no effect: the module ignores it after creation.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.engine_lifecycle_support == null || contains(["open-source-rds-extended-support", "open-source-rds-extended-support-disabled"], coalesce(var.engine_lifecycle_support, "-"))
    error_message = "engine_lifecycle_support must be open-source-rds-extended-support or open-source-rds-extended-support-disabled."
  }
}

variable "engine_version" {
  description = <<-EOT
    The engine version, such as `16.6` for Aurora PostgreSQL or `8.0.mysql_aurora.3.08.2` for Aurora MySQL. Not every version supports global databases; `aws rds describe-db-engine-versions --engine aurora-postgresql --query "DBEngineVersions[?SupportsGlobalDatabases].EngineVersion"` lists those that do. Defaults to `null`: AWS chooses its default version for `engine`, or keeps the source cluster's.

    Changing it upgrades the global cluster and every member cluster in place; a new major version is allowed. Member clusters managed with `aws_rds_cluster` need `lifecycle { ignore_changes = [engine_version] }`, or the upgrade fails with "Provider produced inconsistent final plan". An upgrade needs a primary cluster: on a global cluster with no members, AWS refuses it and the provider retries until the `update` timeout. If the version changes outside Terraform, the next plan shows it changing back; set the input to the running version.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.engine_version == null || try(trimspace(var.engine_version) != "", false)
    error_message = "engine_version must not be empty. Leave it null for the default version."
  }
}

variable "force_destroy" {
  description = <<-EOT
    Whether destroying the global cluster first removes its member clusters from it. Defaults to `false`: AWS refuses to delete a global cluster that still has members, so remove them first. With `true`, the member clusters are not deleted; each one becomes a standalone cluster. Changed in place.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "global_cluster_identifier" {
  description = <<-EOT
    The global cluster's name, such as `orders`. It must be unique among the global clusters in the account, and be 1 to 63 lowercase letters, numbers and hyphens, starting with a letter, with no two hyphens in a row and no hyphen at the end. Changing it replaces the global cluster.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.global_cluster_identifier)) && !strcontains(var.global_cluster_identifier, "--") && !endswith(var.global_cluster_identifier, "-")
    error_message = "global_cluster_identifier must be 1 to 63 lowercase letters, numbers and hyphens, start with a letter, and have no two hyphens in a row and no hyphen at the end."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region to manage the global cluster from, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. A global cluster is not tied to one Region: its member clusters can be in any Region that supports global databases, and each one names the global cluster by its identifier. The primary cluster is often in this Region. Changing it replaces the global cluster.
  EOT
  type        = string
  default     = null
}

variable "source_db_cluster_identifier" {
  description = <<-EOT
    The ARN of an existing Aurora cluster to make the global cluster's primary cluster, such as `arn:aws:rds:us-east-1:123456789012:cluster:orders`. The global cluster takes its engine, version, encryption and databases from it. Exactly one of `engine` and `source_db_cluster_identifier` must be set.

    With this, `storage_encrypted` and `database_name` are not used, and `engine_version` is best left `null` until the global cluster exists. The module ignores later changes to this input, so the global cluster is never replaced because the source cluster's ARN changed. If the source cluster is managed with `aws_rds_cluster`, give it `lifecycle { ignore_changes = [global_cluster_identifier] }`.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.source_db_cluster_identifier == null || can(regex("^arn:[^:]+:rds:[^:]+:[0-9]{12}:cluster:[a-z][a-z0-9-]*$", coalesce(var.source_db_cluster_identifier, "-")))
    error_message = "source_db_cluster_identifier must be the ARN of an Aurora cluster, such as arn:aws:rds:us-east-1:123456789012:cluster:orders."
  }
}

variable "storage_encrypted" {
  description = <<-EOT
    Whether the global cluster's storage is encrypted. Defaults to `true`; AWS's own default is `false`. Every cluster added to an encrypted global cluster must be encrypted too, with a KMS key in its own Region (`kms_key_id` in `aws_rds_cluster`). Not used with `source_db_cluster_identifier`: the global cluster has the source cluster's encryption. Changing it replaces the global cluster.
  EOT
  type        = bool
  default     = true
  nullable    = false
}

variable "timeouts" {
  description = <<-EOT
    How long Terraform waits for each operation before failing:

    - `create` - (Optional) Defaults to `180m`. With `source_db_cluster_identifier`, it includes making the source cluster the primary.
    - `update` - (Optional) Defaults to `120m`. An engine upgrade upgrades every member cluster.
    - `delete` - (Optional) Defaults to `120m`.
  EOT
  type = object({
    create = optional(string, "180m")
    update = optional(string, "120m")
    delete = optional(string, "120m")
  })
  default  = {}
  nullable = false
}
