# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# An empty, encrypted Aurora PostgreSQL global cluster in the provider's Region.
# Clusters join it later by naming it in their global_cluster_identifier.

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

variable "deletion_protection" {
  description = "Whether AWS refuses to delete the global cluster. Set it to false and apply before terraform destroy."
  type        = bool
  default     = true
}

module "global_cluster" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Basic Global Cluster"
    environment = "Development"
  }

  global_cluster_identifier = "example-basic"
  engine                    = "aurora-postgresql"
  deletion_protection       = var.deletion_protection
}

output "global_cluster" {
  description = "The global cluster's identifier, ARN, engine and version"
  value = {
    id             = module.global_cluster.metadata.global_cluster.id
    arn            = module.global_cluster.metadata.global_cluster.arn
    engine         = module.global_cluster.metadata.global_cluster.engine
    engine_version = module.global_cluster.metadata.global_cluster.engine_version
  }
}
