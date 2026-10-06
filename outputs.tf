# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

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
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    # One entry per resource.
    global_cluster = local.output_resources.global_cluster
  }
}

locals {
  # Each resource's attributes are listed one by one. Referencing a whole resource
  # would also reference any attribute the provider deprecates later, and every
  # caller's plan would print deprecation warnings. global_cluster_members is left
  # out: member clusters join after the global cluster is created, so it changes on
  # the next refresh.
  output_resources = {
    global_cluster = {
      arn                          = aws_rds_global_cluster.this.arn
      database_name                = aws_rds_global_cluster.this.database_name
      deletion_protection          = aws_rds_global_cluster.this.deletion_protection
      endpoint                     = aws_rds_global_cluster.this.endpoint
      engine                       = aws_rds_global_cluster.this.engine
      engine_lifecycle_support     = aws_rds_global_cluster.this.engine_lifecycle_support
      engine_version               = aws_rds_global_cluster.this.engine_version
      engine_version_actual        = aws_rds_global_cluster.this.engine_version_actual
      force_destroy                = aws_rds_global_cluster.this.force_destroy
      global_cluster_identifier    = aws_rds_global_cluster.this.global_cluster_identifier
      global_cluster_resource_id   = aws_rds_global_cluster.this.global_cluster_resource_id
      id                           = aws_rds_global_cluster.this.id
      region                       = aws_rds_global_cluster.this.region
      source_db_cluster_identifier = aws_rds_global_cluster.this.source_db_cluster_identifier
      storage_encrypted            = aws_rds_global_cluster.this.storage_encrypted
      tags                         = aws_rds_global_cluster.this.tags
      tags_all                     = aws_rds_global_cluster.this.tags_all
    }
  }
}
