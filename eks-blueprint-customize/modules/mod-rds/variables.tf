variable "backup_retention_period" {
  description = "Number of days to retain backups. Must be between 0 and 35. Must be greater than 0 if the database is used as a source for a Read Replica."
}

variable "backup_window" {
  description = "Time frame in UTC to perform backups (hh:mm-hh:mm)"
}

variable "instance_class" {
  description = "AWS instance class for database hosts."
  default     = "db.m5.xlarge"
}

variable "maintenance_window" {
  description = "Time frame to perform maintenance (ddd:hh:mm-ddd:hh:mm)"
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted."
  default     = "true"
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window."
  default     = "true"
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ."
  default     = true
}

variable "name" {
  description = "Name of the Postgres instance."
}

variable "port" {
  description = "Port number to serve on."
  default     = "5432"
}

variable "postgres_version" {
  description = "Version of Postgres to run."
}

variable "use_aurora" {
  type        = bool
  description = "Use AWS Aurora instead of regular RDS instances. Defaults to false."
  default     = false
}

variable "aurora_type" {
  type        = string
  description = "What flavour of AWS Aurora to use. Accepted values are 'provisioned' and 'serverless'. Defaults to 'serverless'."
  default     = "serverless"
}

variable "serverless_auto_pause" {
  type        = bool
  description = "Whether to enable automatic pause. A DB cluster can be paused only when it's idle (it has no connections). If a DB cluster is paused for more than seven days, the DB cluster might be backed up with a snapshot. In this case, the DB cluster is restored when there is a request to connect to it. Defaults to true."
  default     = null
}

variable "serverless_seconds_until_auto_pause" {
  type        = number
  description = "The time, in seconds, before an Aurora DB cluster in serverless mode is paused. Valid values: 300 to 86400. Defaults to 300."
  default     = null
}

variable "serverless_min_capacity" {
  type        = number
  description = "The minimum capacity for an Aurora DB cluster in Aurora Capacity Units (1 ACU = 0.25 CPU, 2 GiB memory). Valid values: 2 to 384. Defaults to 1."
  default     = null
}

variable "serverless_max_capacity" {
  type        = number
  description = "The maximum capacity for an Aurora DB cluster in Aurora Capacity Units (1 ACU = 0.25 CPU, 2 GiB memory). Valid values: 2 to 384. Defaults to 16."
  default     = null
}

variable "allocated_storage" {
  description = "Size in GB for allocated storage."
}

variable "max_allocated_storage" {
  description = "When configured, the upper limit to which Amazon RDS can automatically scale the storage of the DB instance."
}

variable "storage_type" {
  description = "Type of storage device; see AWS docs for list of options."
  default     = "gp2"
}

variable "username" {
  description = "Username of the database admin account."
  default     = "postgres"
}

variable "vpc_id" {
  description = "ID of the VPC in which to create database instance."
}

variable "route53_zone_id" {
  description = "ID of the private route53 zone to create the CNAME record for the db in."
}

variable "cidr_range" {
  type        = list(string)
  description = "CIDR range of IPs allowed to connect to the database."
}

variable "family" {
  description = "The family of the DB parameter group."
  type        = string
}

variable "parameter" {
  type = list(map(string))

  default = [
    {
      name         = "log_statement"
      value        = "ddl"
      apply_method = "pending-reboot"
    },
    {
      name         = "log_min_duration_statement"
      value        = "4000"
      apply_method = "pending-reboot"
    },
    {
      name         = "rds.force_ssl"
      value        = "1"
      apply_method = "pending-reboot"
    },
  ]

  description = "Database parameters to be added to parameter group"
}

variable "replicate_source_db" {
  description = "Specifies that this resource is a Replicate database, and to use this value as the source database. This correlates to the identifier of another Amazon RDS Database to replicate (if replicating within a single region) or ARN of the Amazon RDS Database to replicate (if replicating cross-region)."
  default     = ""
  type        = string
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN."
  default     = ""
  type        = string
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true."
  default     = "false"
  type        = string
}

variable "iops" {
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of `io1`."
  default     = "0"
}

variable "enable_performance_insights" {
  description = "Enable/disable performance insights"
  default     = false
  type        = bool
}

variable "performance_insights_kms_key_id" {
  description = "The KMS key id used to encrypt performance insights"
  default     = ""
  type        = string
}

variable "performance_insights_retention_period" {
  description = "Retention period for the performance insights"
  default     = 7
  type        = number
}

variable "auto_minor_version_upgrade" {
  description = "Determines if the RDS database instance will automatically upgrade to the latest minor version."
  default     = true
}

variable "proxy_host" {
  type        = string
  description = "If set, the hostname setup for the DB will be pointing to the proxy host instead of the RDS host. Useful for RDS proxies and Aurora."
  default     = ""
}

variable "override_cluster_name" {
  type        = string
  description = "Override the cluster name logic with this value. This is useful to import db cluster resources that were not created with this module."
  default     = ""
}

variable "override_instance_name" {
  type        = string
  description = "Override the instance name logic with this value. This is useful to import db instance resources that were not created with this module."
  default     = ""
}

variable "skip_db" {
  type        = bool
  description = "If true, do not create a default database named var.name in the RDS instance."
  default     = false
}

variable "instance_parameters" {
  description = "Parameter for the database instance; used when database engine is provisioned Aurora."
  default     = {}
}

variable "cluster_parameters" {
  description = "Parameter for the database cluster; used when database engine is provisioned Aurora."
  default     = {}
}

variable "allow_major_version_upgrade" {
  description = "Determines if the database instance can upgrade between major versions of the database engine."
  default     = false
}

variable "env_tags" {
  description = "Environment tags configured for all provisioned resources."
  default     = {}
  type        = map(string)
}

variable "tags" {
  description = "Map of key/values to apply to the database instance/cluster."
  default     = {}
}

variable "db_subnet_group" {
  type        = list(string)
}

variable "performance_insights_enabled" {
  default     = false
}

