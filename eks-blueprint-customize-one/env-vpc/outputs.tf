output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
#  value       = compact(aws_subnet.private[*].cidr_block)
  value = compact(module.vpc.private_subnets_cidr_blocks)
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}
