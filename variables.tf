variable "db_name" {
  description = "Database Name"
  type        = string
  default     = null
}

variable "db_type" {
  description = "Database Type (mysql, postgresql)"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Deletion Protection"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Engine (aurora, aurora-mysql, aurora-postgresql)"
  type        = string
  default     = null
}

variable "engine_version" {
  # aws rds describe-db-engine-versions --engine aurora-mysql --query "DBEngineVersions[].EngineVersion"
  # aws rds describe-db-engine-versions --engine aurora-postgresql --query "DBEngineVersions[].EngineVersion"
  description = "Engine Version"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Force Destroy"
  type        = bool
  default     = false
}

variable "global_cluster_identifier" {
  description = "Global Cluster Identifier"
  type        = string
  default     = null
}

variable "source_db_cluster_identifier" {
  description = "Source DB Cluster Identifier (ARN)"
  type        = string
  default     = null
}

variable "storage_encrypted" {
  description = "Storage Encrypted"
  type        = bool
  default     = null
}

variable "timeouts" {
  description = "Timeouts"
  type        = any
  default = {
    create = "180m"
    delete = "120m"
    update = "120m"
  }
}