# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A two-Region Aurora PostgreSQL global database: the global cluster, a primary
# cluster with one instance in us-east-1, and a read-only secondary cluster with one
# instance in us-west-2. One provider: each resource names its Region with `region`.
#
# It needs a DB subnet group in each Region, with private subnets in at least two
# Availability Zones. Nothing is publicly accessible. Terraform 1.11 or later: the
# password is passed to a write-only argument and never saved in the state.

terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "primary_db_subnet_group_name" {
  description = "The name of a DB subnet group in us-east-1"
  type        = string
}

variable "secondary_db_subnet_group_name" {
  description = "The name of a DB subnet group in us-west-2"
  type        = string
}

variable "master_password" {
  description = "The database administrator's password: at least 8 characters, without /, \", @ or spaces"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "deletion_protection" {
  description = "Whether AWS refuses to delete the global cluster and both clusters. Set it to false and apply before terraform destroy."
  type        = bool
  default     = true
}

locals {
  primary_region   = "us-east-1"
  secondary_region = "us-west-2"
  instance_class   = "db.r6g.large" # the smallest class that supports global databases

  details = {
    scope       = "Example"
    purpose     = "Global Database"
    environment = "Development"
  }
}

module "global_cluster" {
  source = "../../"

  details = local.details
  region  = local.primary_region

  global_cluster_identifier = "example-complete"
  engine                    = "aurora-postgresql"
  database_name             = "app"
  deletion_protection       = var.deletion_protection

  # Leave Extended Support off: AWS upgrades the major version after the end of
  # standard support instead of charging for Extended Support.
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
}

# The global cluster is encrypted, so each cluster needs a KMS key in its own Region.
resource "aws_kms_key" "rds" {
  for_each = toset([local.primary_region, local.secondary_region])

  region                  = each.key
  description             = "Example global database storage in ${each.key}"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = module.global_cluster.metadata.details.tags
}

resource "aws_rds_cluster" "primary" {
  region                    = local.primary_region
  cluster_identifier        = "example-complete-primary"
  global_cluster_identifier = module.global_cluster.metadata.global_cluster.id
  engine                    = module.global_cluster.metadata.global_cluster.engine
  engine_version            = module.global_cluster.metadata.global_cluster.engine_version
  database_name             = module.global_cluster.metadata.global_cluster.database_name
  db_subnet_group_name      = var.primary_db_subnet_group_name

  # Aurora cannot keep the password of a global database's cluster in AWS Secrets
  # Manager (manage_master_user_password), so it is passed in. A write-only argument
  # keeps it out of the state; to change it, increase master_password_wo_version.
  master_username            = "app_admin"
  master_password_wo         = var.master_password
  master_password_wo_version = 1

  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds[local.primary_region].arn
  backup_retention_period = 7
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = true # an example; keep a final snapshot for real data
  tags                    = module.global_cluster.metadata.details.tags

  lifecycle {
    # An engine upgrade is made through the global cluster (its engine_version input).
    ignore_changes = [engine_version]
  }
}

resource "aws_rds_cluster_instance" "primary" {
  region               = local.primary_region
  identifier           = "example-complete-primary-1"
  cluster_identifier   = aws_rds_cluster.primary.id
  engine               = aws_rds_cluster.primary.engine
  instance_class       = local.instance_class
  db_subnet_group_name = var.primary_db_subnet_group_name
  publicly_accessible  = false
  tags                 = module.global_cluster.metadata.details.tags
}

resource "aws_rds_cluster" "secondary" {
  region                    = local.secondary_region
  cluster_identifier        = "example-complete-secondary"
  global_cluster_identifier = module.global_cluster.metadata.global_cluster.id
  engine                    = module.global_cluster.metadata.global_cluster.engine
  engine_version            = module.global_cluster.metadata.global_cluster.engine_version
  db_subnet_group_name      = var.secondary_db_subnet_group_name

  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds[local.secondary_region].arn
  backup_retention_period = 7
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = true
  tags                    = module.global_cluster.metadata.details.tags

  lifecycle {
    # AWS sets these when the cluster joins as a secondary.
    ignore_changes = [engine_version, replication_source_identifier]
  }

  # Add the secondary after the primary has its writer instance.
  depends_on = [aws_rds_cluster_instance.primary]
}

resource "aws_rds_cluster_instance" "secondary" {
  region               = local.secondary_region
  identifier           = "example-complete-secondary-1"
  cluster_identifier   = aws_rds_cluster.secondary.id
  engine               = aws_rds_cluster.secondary.engine
  instance_class       = local.instance_class
  db_subnet_group_name = var.secondary_db_subnet_group_name
  publicly_accessible  = false
  tags                 = module.global_cluster.metadata.details.tags
}

output "global_database" {
  description = "The global writer endpoint and each cluster's endpoints"
  value = {
    global_writer_endpoint = module.global_cluster.metadata.global_cluster.endpoint
    primary_endpoint       = aws_rds_cluster.primary.endpoint
    primary_reader         = aws_rds_cluster.primary.reader_endpoint
    secondary_reader       = aws_rds_cluster.secondary.reader_endpoint
  }
}
