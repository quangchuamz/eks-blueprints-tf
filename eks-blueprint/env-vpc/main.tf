provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name   = var.environment_name
  region = var.aws_region

  vpc_cidr       = "10.227.96.0/19" #var.vpc_cidr
  private_subnets = ["10.227.96.32/27", "10.227.97.32/27", "10.227.98.32/27"]
  public_subnets = ["10.227.99.192/26","10.227.100.192/26","10.227.101.192/26"]
  secondary_cidr = ["10.96.0.0/16", "10.97.0.0/16", "10.98.0.0/16"]
  pod_subnets = ["10.96.0.0/16", "10.97.0.0/16", "10.98.0.0/16"]
  new_private_subnets = concat(local.private_subnets,local.pod_subnets)

  num_of_subnets = min(length(data.aws_availability_zones.available.names), 3)
  azs            = slice(data.aws_availability_zones.available.names, 0, local.num_of_subnets)

  argocd_secret_manager_name = var.argocd_secret_manager_name_suffix

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

######### OUR VPC #####################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5.1"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
#  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 6, k)]
  public_subnets = local.public_subnets
#  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 6, k + 10)]
  private_subnets = local.new_private_subnets


  secondary_cidr_blocks = ["10.96.0.0/16", "10.97.0.0/16", "10.98.0.0/16"]

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true

  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags

}

######### ADDITIONAL RESOURCES #####################
#---------------------------------------------------------------
# ArgoCD Admin Password credentials with Secrets Manager
# Login to AWS Secrets manager with the same role as Terraform to extract the ArgoCD admin password with the secret name as "argocd"
#---------------------------------------------------------------
resource "random_password" "argocd" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "argocd" {
  name                    = "${local.argocd_secret_manager_name}.${local.name}"
  recovery_window_in_days = 0 # Set to zero for this example to force delete during Terraform destroy
}

resource "aws_secretsmanager_secret_version" "argocd" {
  secret_id     = aws_secretsmanager_secret.argocd.id
  secret_string = random_password.argocd.result
}

######### TAGGING #####################
#---------------------------------------------------------------
# terraform destroy -target=module.vpc -auto-approve
#---------------------------------------------------------------

module "aws_subnet_tagging" {
  source       = "../modules/tagging"
  vpc_id = module.vpc.vpc_id
  base_name = local.name
  subnet_cidrs = ["10.96.0.0/16", "10.97.0.0/16", "10.98.0.0/16"]
  specific_name = "pod"
  depends_on = [module.vpc]
}

