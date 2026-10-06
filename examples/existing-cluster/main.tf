# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A global cluster made from an Aurora cluster you already have. The existing cluster
# becomes the global cluster's primary, with its data, engine, version and encryption.

terraform {
  required_version = ">= 1.9"
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

variable "source_cluster_arn" {
  description = "The ARN of the existing Aurora cluster, such as arn:aws:rds:us-east-1:123456789012:cluster:orders"
  type        = string
}

variable "deletion_protection" {
  description = "Whether AWS refuses to delete the global cluster. Set it to false and apply before terraform destroy."
  type        = bool
  default     = true
}

module "global_cluster" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Existing Cluster"
    environment = "Development"
  }

  global_cluster_identifier    = "example-existing-cluster"
  source_db_cluster_identifier = var.source_cluster_arn
  deletion_protection          = var.deletion_protection

  # On destroy, take the cluster back out of the global cluster instead of failing.
  # The cluster itself is never deleted.
  force_destroy = true
}

output "global_cluster" {
  description = "The global cluster's identifier and the engine and version it took from the cluster"
  value = {
    id             = module.global_cluster.metadata.global_cluster.id
    engine         = module.global_cluster.metadata.global_cluster.engine
    engine_version = module.global_cluster.metadata.global_cluster.engine_version
    encrypted      = module.global_cluster.metadata.global_cluster.storage_encrypted
  }
}
