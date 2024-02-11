/**
 * AWS Postgres instance
 * ================
 *
 * Description
 * -----------
 *
 * This module creates a AWS Postgres instance resource in the given network.
 *
 * ::: warning
 * The password created by this module will be written in plaintext to the state file. They may also be displayed
 * when running plan or apply. It is strongly recommended that the password is changed after this terraform module is applied.
 * :::
 * Also make sure your subnets have SubnetType tag set to Private (i.e SubnetType = "Private") so that
 * database instance gets created only within private subnet.
 *
 * Usage
 * -----
 *
 * Database and DNS record are in the same account.
 *
 * ```ts
 * provider "aws" {
 *   profile = "my-profile"
 *   region  = "eu-west-2"
 * }
 *
 * module "rds" {
 *   source  = "terraform.external.thoughtmachine.io/aux/database/aws"
 *
 *   vpc_id                  = "vpc-123"
 *   allocated_storage       = "20"
 *   max_allocated_storage   = "100"
 *   backup_retention_period = "3"
 *   backup_window           = "09:46-10:16"
 *   maintenance_window      = "Mon:00:00-Mon:03:00"
 *   postgres_version        = "9.6"
 *   name                    = "SomeDatabase"
 *   cidr_range              = ["192.168.0.0/16"]
 *   postgres_version        = "11.6"
 *   family                  = "postgres11"
 *
 *   parameter = [
 *     {
 *       name  = "character_set_server"
 *       value = "utf8"
 *     },
 *     {
 *       name = "log_statement"
 *       value = "ddl"
 *     }
 *   ]
 *
 *   providers = {
 *     aws.dns = "aws"
 *   }
 * }
 * ```
 *
 * Database and DNS record are in different accounts.
 *
 * ```ts
 * provider "aws" {
 *   profile = "my-profile"
 *   region  = "eu-west-2"
 * }
 *
 * provider "aws" {
 *   alias   = "root"
 *   profile = "root"
 *   region  = "eu-west-1"
 * }
 *
 * module "rds" {
 *   source  = "terraform.external.thoughtmachine.io/aux/database/aws"
 *
 *   vpc_id                  = "vpc-123"
 *   allocated_storage       = "20"
 *   max_allocated_storage   = "100"
 *   backup_retention_period = "3"
 *   backup_window           = "09:46-10:16"
 *   maintenance_window      = "Mon:00:00-Mon:03:00"
 *   postgres_version        = "9.6"
 *   name                    = "SomeDatabase"
 *   cidr_range              = ["192.168.0.0/16"]
 *   postgres_version        = "11.6"
 *   family                  = "postgres11"
 *
 *   parameter = [
 *     {
 *       name  = "character_set_server"
 *       value = "utf8"
 *     },
 *     {
 *       name = "log_statement"
 *       value = "ddl"
 *     }
 *   ]
 *
 *   providers = {
 *     aws.dns = "aws.root"
 *   }
 * }
 * ```
**/

provider "aws" {
  alias = "dns"
}

resource "aws_security_group" "sg" {
  description = "Security group for the ${var.name} RDS instance"
  name        = "nsg-${var.env_tags["region_prefix"]}-${var.env_tags["env_code_prefix"]}-${var.env_tags["account_prefix"]}-database"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.port
    to_port     = var.port
    cidr_blocks = var.cidr_range
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = merge(var.tags, {Name = "nsg-${var.env_tags["region_prefix"]}-${var.env_tags["env_code_prefix"]}-${var.env_tags["account_prefix"]}-database"})
}

resource "aws_db_subnet_group" "subnet_group" {
  description = "subnet group for ${var.name}"
  name        = "subnet-group-${var.env_tags["region_prefix"]}-pri-${var.env_tags["env_code_prefix"]}-${var.env_tags["account_prefix"]}-database"
  subnet_ids  = var.db_subnet_group

#  tags = {
#    db_instance = var.name
#  }
  tags                    = merge({db_instance = var.name}, var.tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_string" "password" {
  length  = 32
  special = false
}

resource "random_id" "instance_name_suffix" {
  byte_length = 8
}

resource "aws_db_instance" "instance" {
  count = var.use_aurora ? 0 : 1

  allocated_storage                     = var.allocated_storage
  allow_major_version_upgrade           = var.allow_major_version_upgrade
  apply_immediately                     = var.apply_immediately
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  backup_retention_period               = var.backup_retention_period
  backup_window                         = var.backup_window
  db_subnet_group_name                  = aws_db_subnet_group.subnet_group.id
  deletion_protection                   = var.deletion_protection
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  engine                                = "postgres"
  engine_version                        = var.postgres_version
  identifier                            = coalesce(var.override_instance_name, "${lower(var.name)}-${lower(random_id.instance_name_suffix.hex)}")
  instance_class                        = var.instance_class
  iops                                  = var.iops
  kms_key_id                            = var.kms_key_id
  maintenance_window                    = var.maintenance_window
  max_allocated_storage                 = var.max_allocated_storage
  multi_az                              = var.multi_az
  db_name                               = var.skip_db ? "" : replace(var.name, "-", "_")
  parameter_group_name                  = aws_db_parameter_group.parameter_group[0].id
  password                              = random_string.password.result
  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.enable_performance_insights ? var.performance_insights_retention_period : 0
  port                                  = var.port
  publicly_accessible                   = false
#  replicate_source_db                   = var.replicate_source_db
  skip_final_snapshot                   = var.skip_final_snapshot
  storage_encrypted                     = true
  storage_type                          = var.storage_type
  tags                                  = var.tags
  username                              = var.username

  vpc_security_group_ids = [
    aws_security_group.sg.id,
  ]

  lifecycle {
    ignore_changes = [
      username,
      password,
    ]
  }
}

resource "aws_rds_cluster" "cluster" {
  count = var.use_aurora ? 1 : 0

  apply_immediately               = var.apply_immediately
  cluster_identifier              = coalesce(var.override_cluster_name, "${var.name}-cluster-${lower(random_id.instance_name_suffix.hex)}")
  database_name                   = var.skip_db ? "" : var.name
  db_subnet_group_name            = aws_db_subnet_group.subnet_group.id
  engine                          = "aurora-postgresql"
  engine_mode                     = var.aurora_type
  engine_version                  = var.postgres_version
  master_username                 = var.username
  master_password                 = random_string.password.result
  deletion_protection             = var.deletion_protection
  enabled_cloudwatch_logs_exports = var.aurora_type == "serverless" ? null : ["postgresql"]
  port                            = var.port
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.aurora_type == "serverless" ? null : var.backup_window
  preferred_maintenance_window    = var.aurora_type == "serverless" ? null : var.maintenance_window
  skip_final_snapshot             = var.skip_final_snapshot
  storage_encrypted               = true
  kms_key_id                      = var.kms_key_id
  db_cluster_parameter_group_name = length(aws_rds_cluster_parameter_group.cluster) == 1 ? aws_rds_cluster_parameter_group.cluster[0].id : ""

  vpc_security_group_ids = [
    aws_security_group.sg.id,
  ]

  dynamic "scaling_configuration" {
    # Only add scaling configuration if `aurora_type` is `serverless`
    for_each = var.aurora_type == "serverless" ? [1] : []

    content {
      auto_pause               = var.serverless_auto_pause
      seconds_until_auto_pause = var.serverless_seconds_until_auto_pause
      min_capacity             = var.serverless_min_capacity
      max_capacity             = var.serverless_max_capacity
    }
  }
}

resource "aws_rds_cluster_instance" "instance" {
  count = var.use_aurora && var.aurora_type == "provisioned" ? 1 : 0

  identifier                      = coalesce(var.override_instance_name, "${var.name}-${lower(random_id.instance_name_suffix.hex)}")
  cluster_identifier              = aws_rds_cluster.cluster[0].id
  instance_class                  = var.instance_class
  db_subnet_group_name            = aws_db_subnet_group.subnet_group.id
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  db_parameter_group_name         = aws_db_parameter_group.instance[0].id
  performance_insights_enabled    = var.enable_performance_insights
  performance_insights_kms_key_id = var.performance_insights_kms_key_id
  engine                          = aws_rds_cluster.cluster[0].engine
  engine_version                  = aws_rds_cluster.cluster[0].engine_version

  lifecycle {
    ignore_changes = [
      engine_version
    ]
  }
}

resource "aws_db_parameter_group" "parameter_group" {
  count = var.use_aurora && var.aurora_type == "provisioned" ? 0 : 1

  description = "Database parameter group for ${var.name}"
  family      = var.family
  dynamic "parameter" {
    for_each = var.parameter
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_parameter_group" "cluster" {
  count = var.use_aurora && var.aurora_type == "provisioned" ? 1 : 0

  description = "Database cluster parameter group for ${var.name}"
  family      = var.family

  dynamic "parameter" {
    for_each = var.cluster_parameters

    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "instance" {
  count = var.use_aurora && var.aurora_type == "provisioned" ? 1 : 0

  description = "Database instance parameter group for ${var.name}"
  family      = var.family

  dynamic "parameter" {
    for_each = var.instance_parameters

    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "db_record" {
  provider = aws.dns

  zone_id = var.route53_zone_id
  name    = "db"
  type    = "CNAME"
  ttl     = 300
  records = [coalesce(
    var.proxy_host,
    var.use_aurora ? aws_rds_cluster.cluster[0].endpoint : aws_db_instance.instance[0].address,
  )]
}
