# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  details                   = { scope = "Test", purpose = "Options", environment = "test" }
  global_cluster_identifier = "test-global"
  engine                    = "aurora-mysql"
}

# Regression: the old module built the engine from db_type and ignored its own
# engine input; with db_type unset the plan failed on a null template value.
run "every_option_set" {
  command = plan
  variables {
    engine                   = "aurora-mysql"
    engine_version           = "8.0.mysql_aurora.3.08.2"
    engine_lifecycle_support = "open-source-rds-extended-support-disabled"
    database_name            = "app"
    deletion_protection      = false
    force_destroy            = true
    storage_encrypted        = false
  }
  assert {
    condition = alltrue([
      aws_rds_global_cluster.this.engine == "aurora-mysql",
      aws_rds_global_cluster.this.engine_version == "8.0.mysql_aurora.3.08.2",
      aws_rds_global_cluster.this.engine_lifecycle_support == "open-source-rds-extended-support-disabled",
      aws_rds_global_cluster.this.database_name == "app",
      aws_rds_global_cluster.this.deletion_protection == false,
      aws_rds_global_cluster.this.force_destroy == true,
      aws_rds_global_cluster.this.storage_encrypted == false,
    ])
    error_message = "An option did not reach the global cluster."
  }
}

# From an existing cluster: no engine, encryption or database is sent, and
# force_destroy is always configured (the provider requires it with a source cluster).
run "from_source_cluster" {
  command = plan
  variables {
    engine                       = null
    source_db_cluster_identifier = "arn:aws:rds:us-east-1:111111111111:cluster:orders"
    engine_version               = "16.6"
  }
  assert {
    condition = alltrue([
      aws_rds_global_cluster.this.source_db_cluster_identifier == "arn:aws:rds:us-east-1:111111111111:cluster:orders",
      aws_rds_global_cluster.this.force_destroy == false,
      aws_rds_global_cluster.this.engine_version == "16.6",
    ])
    error_message = "Unexpected configuration from a source cluster."
  }
}

run "from_source_cluster_apply" {
  command = apply
  variables {
    engine                       = null
    source_db_cluster_identifier = "arn:aws:rds:us-east-1:111111111111:cluster:orders"
  }
}

# A changed source ARN (for example, the source cluster was replaced) must not replace
# the global cluster.
run "source_change_ignored" {
  command = plan
  variables {
    engine                       = null
    source_db_cluster_identifier = "arn:aws:rds:us-east-1:111111111111:cluster:orders-new"
  }
  assert {
    condition     = aws_rds_global_cluster.this.source_db_cluster_identifier == "arn:aws:rds:us-east-1:111111111111:cluster:orders"
    error_message = "A source change would reach the global cluster."
  }
}

# Partitions other than aws are accepted.
run "source_cluster_govcloud_arn" {
  command = plan
  variables {
    engine                       = null
    source_db_cluster_identifier = "arn:aws-us-gov:rds:us-gov-west-1:111111111111:cluster:orders"
  }
}
