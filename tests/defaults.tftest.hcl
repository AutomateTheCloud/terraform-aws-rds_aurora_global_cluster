# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_rds_global_cluster" {
    defaults = {
      arn                        = "arn:aws:rds::111111111111:global-cluster:test-global"
      global_cluster_resource_id = "cluster-0123456789abcdef"
      engine_version_actual      = "16.6"
    }
  }
}

variables {
  details                   = { scope = "Test", purpose = "Defaults", environment = "test" }
  global_cluster_identifier = "test-global"
  engine                    = "aurora-postgresql"
}

# With only the required inputs, the global cluster is encrypted, protected from
# deletion, keeps its members on destroy, and is tagged.
# Regression: the old module left storage_encrypted unset (AWS's default is false),
# turned deletion protection off, and never applied the details tags.
run "defaults_plan" {
  command = plan

  assert {
    condition = alltrue([
      aws_rds_global_cluster.this.global_cluster_identifier == "test-global",
      aws_rds_global_cluster.this.engine == "aurora-postgresql",
      aws_rds_global_cluster.this.storage_encrypted == true,
      aws_rds_global_cluster.this.deletion_protection == true,
      aws_rds_global_cluster.this.force_destroy == false,
      aws_rds_global_cluster.this.tags == tomap({ Scope = "Test", Purpose = "Defaults", Environment = "test" }),
    ])
    error_message = "Unexpected configuration with only the required inputs."
  }
}

# Regression: a partial timeouts map failed with "Unsupported attribute".
run "timeouts_defaults_and_partial" {
  command = plan
  variables { timeouts = { create = "60m" } }
  assert {
    condition = alltrue([
      aws_rds_global_cluster.this.timeouts.create == "60m",
      aws_rds_global_cluster.this.timeouts.update == "120m",
      aws_rds_global_cluster.this.timeouts.delete == "120m",
    ])
    error_message = "Unexpected timeouts."
  }
}

run "defaults_apply" {
  command = apply

  assert {
    condition = alltrue([
      output.metadata.global_cluster.global_cluster_identifier == "test-global",
      output.metadata.global_cluster.arn == "arn:aws:rds::111111111111:global-cluster:test-global",
      output.metadata.global_cluster.global_cluster_resource_id == "cluster-0123456789abcdef",
      output.metadata.global_cluster.storage_encrypted == true,
      output.metadata.aws.region.name == "us-east-1",
      output.metadata.aws.region.abbr == "use1",
      output.metadata.aws.account.id == "111111111111",
      output.metadata.details.tags["Scope"] == "Test",
    ])
    error_message = "Unexpected metadata output."
  }
}

# Regression: the old module's ignore_changes on engine_version hid every upgrade.
# An upgrade is now an in-place update of the global cluster.
run "engine_version_upgrade_in_place" {
  command = plan
  variables { engine_version = "17.4" }
  assert {
    condition     = aws_rds_global_cluster.this.engine_version == "17.4"
    error_message = "An engine_version change was not planned."
  }
}

# AWS sets the lifecycle support only at creation (ModifyGlobalCluster has no such
# parameter), so a later change is ignored instead of planned as an update that does
# nothing.
run "engine_lifecycle_support_change_ignored" {
  command = plan
  variables { engine_lifecycle_support = "open-source-rds-extended-support-disabled" }
  assert {
    condition     = aws_rds_global_cluster.this.engine_lifecycle_support != "open-source-rds-extended-support-disabled"
    error_message = "A lifecycle support change would reach the global cluster."
  }
}

run "additional_tags" {
  command = plan
  variables {
    details = { scope = "Test", purpose = "Defaults", environment = "test", additional_tags = { CostCenter = "1234" } }
  }
  assert {
    condition = aws_rds_global_cluster.this.tags == tomap({
      Scope       = "Test"
      Purpose     = "Defaults"
      Environment = "test"
      CostCenter  = "1234"
    })
    error_message = "Unexpected tags."
  }
}

# Regression: an empty abbreviation override used to replace the generated one with "".
run "abbreviation_override" {
  command = plan
  variables {
    details = { scope = "Automate the Cloud", scope_abbr = "atc-org", purpose = "Orders Database", purpose_abbr = "", environment = "Production" }
  }
  assert {
    condition = alltrue([
      output.metadata.details.scope.abbr == "atc-org",
      output.metadata.details.scope.machine == "atcorg",
      output.metadata.details.purpose.abbr == "orders_database",
      output.metadata.details.purpose.machine == "ordersdatabase",
      output.metadata.details.environment.abbr == "production",
    ])
    error_message = "Unexpected abbreviations."
  }
}
