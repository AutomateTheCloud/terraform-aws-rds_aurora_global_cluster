terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: RDS - Aurora
module "rds-aurora_global_cluster" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope               = "Demo"
    purpose             = "RDS - Aurora Global Cluster"
    environment         = "dev"
    additional_tags = {
      "Project"         = "Project Name"
      "ProjectID"       = "123456789"
      "Contact"         = "David Singer - david.singer@example.com"
    }
  }

  db_name             = "demo"
  db_type             = "postgresql"
  deletion_protection = false

  engine_version = "13.6"

  force_destroy  = true
  global_cluster_identifier = "test-global-cluster-aurora"

  # source_db_cluster_identifier = ""
  # storage_encrypted = true
}

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value = module.rds-aurora_global_cluster.metadata
}
