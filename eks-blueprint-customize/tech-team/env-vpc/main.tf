locals {
  create_vpc            = true
  putin_khuylo          = true
  name                  = "eks-vnm"
  cidr                  = "10.227.96.0/19"
  private_subnets       = ["10.227.96.32/27", "10.227.97.32/27", "10.227.98.32/27"]
  public_subnets        = ["10.227.99.192/26","10.227.100.192/26","10.227.101.192/26"]
  secondary_cidr_blocks = ["10.96.0.0/16", "10.97.0.0/16", "10.98.0.0/16"]
  pod_subnets           = local.secondary_cidr_blocks
  num_of_subnets        = min(length(data.aws_availability_zones.available.names), 3)
  azs                   = slice(data.aws_availability_zones.available.names, 0, local.num_of_subnets)
  single_nat_gateway    = true
  enable_nat_gateway    = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames  = true


  public_dedicated_network_acl = true
  public_dedicated_security_group = true
  default_security_group_name = "public-security-group"
  default_security_group_ingress = [
    {
      from_port: 22
      to_port: 22
      protocol: "tcp"
      cidr_blocks: "0.0.0.0/0"
    },
    {
      from_port: 80
      to_port: 80
      protocol: "tcp"
      cidr_blocks: "0.0.0.0/0"
    },
  ]
  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

data "aws_availability_zones" "available" {}

#################################################
###  VPC PROFILE
#################################################
module "vpc" {
  source                = "../../modules/mod-vpc"
  name                  = local.name
  cidr                  = local.cidr
  azs                   = local.azs
  secondary_cidr_blocks = local.secondary_cidr_blocks
  enable_dns_hostnames  = local.enable_dns_hostnames

  #default vpc
  #  manage_default_network_acl    = true
  #  default_network_acl_tags      = { Name = "${local.name}-default" }
  #  manage_default_route_table    = true
  #  default_route_table_tags      = { Name = "${local.name}-default" }
  #  manage_default_security_group = true
  #  default_security_group_tags   = { Name = "${local.name}-default" }

  tags = local.tags
}

#################################################
### INTERNET GATEWAY PROFILE
#################################################

module "igw" {
  source = "../../modules/mod-igw"
  create_igw =  true
  vpc_id = module.vpc.vpc_id
  name = local.name
  depends_on = [module.vpc]
  tags = local.tags
#  igw_tags = {
#    igw: "igw_tags"
#  }
}

#################################################
### DEFAULT VPC PROFILE
#################################################
#module "default_vpc" {
#  source = "../modules/mod-default-vpc"
#  name = local.name
#  vpc_id = module.vpc.vpc_id
#  manage_default_network_acl    = true
#  default_network_acl_tags      = { Name = "${local.name}-default" }
#  manage_default_route_table    = true
#  default_route_table_tags      = { Name = "${local.name}-default" }
#  manage_default_security_group = true
#  default_security_group_tags   = { Name = "${local.name}-default" }
#  depends_on = [module.vpc]
#}


################################################
## PUBLIC SUBNET
################################################
module "public_subnets" {
  source = "../../modules/mod-public-subnets"
  igw_id = module.igw.igw_id
  vpc_id = module.vpc.vpc_id
  azs = local.azs
  name = local.name
  public_dedicated_network_acl = local.public_dedicated_network_acl
  public_subnets = local.public_subnets
  depends_on = [module.vpc, module.igw]
  tags = local.tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  #Security group
  public_dedicated_security_group = local.public_dedicated_security_group
  default_security_group_name = local.default_security_group_name
  default_security_group_ingress = local.default_security_group_ingress

}

#################################################
### NAT GATEWAY
#################################################
module "nat_gatway" {
  source = "../../modules/mod-natgw"
  azs = local.azs
  vpc_name = local.name
  enable_nat_gateway = local.enable_nat_gateway
  single_nat_gateway = local.single_nat_gateway
  one_nat_gateway_per_az = local.one_nat_gateway_per_az
  nat_subnet = module.public_subnets.public_subnets
  depends_on = [module.igw]
}

###################################################
##### PRIVATE SUBNET
###################################################
#
##module "private_subnets" {
##  source = "../../modules/mod-private-subnets"
##  azs = local.azs
##  vpc_id = module.vpc.vpc_id
##  vpc_name = local.name
##  nat_gw_count = local.single_nat_gateway ? 1 : length(local.azs)
##  private_subnets = local.private_subnets
###  default_route_table_routes = [
###    {
###      nat_gateway_id: "${module.nat_gatway.natgw_ids[0]}"
###      cidr_block: "0.0.0.0/0"
###    }
###  ]
##  private_subnet_tags = {
##    "kubernetes.io/role/internal-elb" = 1
##  }
##  depends_on = [module.nat_gatway]
##}
#
module "private_subnets_test" {
  source = "../../modules/mod-private-subnets-test"
  vpc_id = module.vpc.vpc_id
  single_nat_gateway = local.single_nat_gateway
  azs = local.azs
  name = local.name
  private_subnets = local.private_subnets
  private_subnet_suffix = "private"
  default_route_table_routes = [
    {
      nat_gateway_id: "${module.nat_gatway.natgw_ids[0]}"
      cidr_block: "0.0.0.0/0"
    },
  ]
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

}

module "pod_subnets" {
  source = "../../modules/mod-private-subnets-test"
  vpc_id = module.vpc.vpc_id
  single_nat_gateway = local.single_nat_gateway
  azs = local.azs
  name = local.name
  private_subnets = local.pod_subnets
  private_subnet_suffix = "pod"
  default_route_table_routes = [
    {
      nat_gateway_id: "${module.nat_gatway.natgw_ids[0]}"
      cidr_block: "0.0.0.0/0"
    },
  ]
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

}

#################################################
### SECRET MANAGER
#################################################
module "eks_sm" {
  source = "../../modules/mod-sm"
  environment_name = local.name
}

