# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  from_source = var.source_db_cluster_identifier != null
}

resource "aws_rds_global_cluster" "this" {
  region                    = var.region
  global_cluster_identifier = var.global_cluster_identifier
  deletion_protection       = var.deletion_protection
  force_destroy             = var.force_destroy
  engine_version            = var.engine_version
  engine_lifecycle_support  = var.engine_lifecycle_support

  # A new global cluster: its engine, encryption and first database.
  engine            = local.from_source ? null : var.engine
  storage_encrypted = local.from_source ? null : var.storage_encrypted
  database_name     = local.from_source ? null : var.database_name

  # A global cluster made from an existing cluster takes those from it.
  source_db_cluster_identifier = var.source_db_cluster_identifier

  tags = local.tags

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    # AWS cannot read back the source cluster, and a change to it would replace the
    # global cluster. AWS sets the lifecycle support only at creation; a change would
    # be planned as an update that does nothing.
    ignore_changes = [
      source_db_cluster_identifier,
      engine_lifecycle_support,
    ]
  }
}
