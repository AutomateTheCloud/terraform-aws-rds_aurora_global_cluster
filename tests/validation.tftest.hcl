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
  details                   = { scope = "Test", purpose = "Validation", environment = "test" }
  global_cluster_identifier = "test-global"
  engine                    = "aurora-postgresql"
}

run "details_scope_required" {
  command = plan
  variables { details = { scope = " ", purpose = "Validation", environment = "test" } }
  expect_failures = [var.details]
}

run "details_purpose_required" {
  command = plan
  variables { details = { scope = "Test", purpose = "", environment = "test" } }
  expect_failures = [var.details]
}

run "details_environment_required" {
  command = plan
  variables { details = { scope = "Test", purpose = "Validation", environment = "" } }
  expect_failures = [var.details]
}

# Regression: the identifier defaulted to null and failed only in the provider.
# It is now required and not nullable; null fails with "Required variable not set"
# before any validation, which expect_failures cannot catch, so the empty value is
# tested here.
run "identifier_required" {
  command = plan
  variables { global_cluster_identifier = "" }
  expect_failures = [var.global_cluster_identifier]
}

run "identifier_63_characters_accepted" {
  command = plan
  variables { global_cluster_identifier = join("", ["g", join("", [for i in range(62) : "1"])]) }
}

# AWS rejects 64 characters (checked with the AWS CLI).
run "identifier_too_long" {
  command = plan
  variables { global_cluster_identifier = join("", ["g", join("", [for i in range(63) : "1"])]) }
  expect_failures = [var.global_cluster_identifier]
}

run "identifier_uppercase" {
  command = plan
  variables { global_cluster_identifier = "Test-global" }
  expect_failures = [var.global_cluster_identifier]
}

run "identifier_starts_with_digit" {
  command = plan
  variables { global_cluster_identifier = "1global" }
  expect_failures = [var.global_cluster_identifier]
}

run "identifier_double_hyphen" {
  command = plan
  variables { global_cluster_identifier = "test--global" }
  expect_failures = [var.global_cluster_identifier]
}

run "identifier_trailing_hyphen" {
  command = plan
  variables { global_cluster_identifier = "test-global-" }
  expect_failures = [var.global_cluster_identifier]
}

# AWS no longer creates global clusters with the old aurora (MySQL 5.6) engine
# (checked with the AWS CLI), and the provider defaults to it when no engine is sent.
run "engine_aurora_rejected" {
  command = plan
  variables { engine = "aurora" }
  expect_failures = [var.engine]
}

run "engine_or_source_required" {
  command = plan
  variables { engine = null }
  expect_failures = [var.engine]
}

run "engine_and_source_rejected" {
  command = plan
  variables {
    source_db_cluster_identifier = "arn:aws:rds:us-east-1:111111111111:cluster:orders"
  }
  expect_failures = [var.engine]
}

run "source_not_an_arn" {
  command = plan
  variables {
    engine                       = null
    source_db_cluster_identifier = "orders"
  }
  expect_failures = [var.source_db_cluster_identifier]
}

run "database_name_with_source_rejected" {
  command = plan
  variables {
    engine                       = null
    source_db_cluster_identifier = "arn:aws:rds:us-east-1:111111111111:cluster:orders"
    database_name                = "app"
  }
  expect_failures = [var.database_name]
}

run "database_name_empty" {
  command = plan
  variables { database_name = " " }
  expect_failures = [var.database_name]
}

run "engine_version_empty" {
  command = plan
  variables { engine_version = "" }
  expect_failures = [var.engine_version]
}

run "engine_lifecycle_support_invalid" {
  command = plan
  variables { engine_lifecycle_support = "disabled" }
  expect_failures = [var.engine_lifecycle_support]
}
