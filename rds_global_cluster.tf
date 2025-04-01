resource "aws_rds_global_cluster" "this" {
  global_cluster_identifier    = var.global_cluster_identifier
  database_name                = try(var.source_db_cluster_identifier, null) == null ? var.db_name : null
  deletion_protection          = var.deletion_protection
  engine                       = try(var.source_db_cluster_identifier, null) == null ? "aurora-${var.db_type}" : null
  engine_version               = try(var.source_db_cluster_identifier, null) == null ? var.engine_version : null
  force_destroy                = var.force_destroy
  source_db_cluster_identifier = var.source_db_cluster_identifier
  storage_encrypted            = try(var.source_db_cluster_identifier, null) == null ? var.storage_encrypted : null

  lifecycle {
    ignore_changes = [
      database_name,
      engine,
      engine_version,
      source_db_cluster_identifier,
      storage_encrypted
    ]
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  provider = aws.this
}
