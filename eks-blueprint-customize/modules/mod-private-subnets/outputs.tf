################################################################################
# Private Subnets
################################################################################

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private_subnets[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private_subnets[*].arn
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = compact(aws_subnet.private_subnets[*].cidr_block)
}

#output "private_subnets_ipv6_cidr_blocks" {
#  description = "List of IPv6 cidr_blocks of private subnets in an IPv6 enabled VPC"
#  value       = compact(aws_subnet.private_subnets[*].ipv6_cidr_block)
#}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private_rtb[*].id
}

#output "private_nat_gateway_route_ids" {
#  description = "List of IDs of the private nat gateway route"
#  value       = aws_route.private_nat_gateway[*].id
#}

#output "private_ipv6_egress_route_ids" {
#  description = "List of IDs of the ipv6 egress route"
#  value       = aws_route.private_ipv6_egress[*].id
#}


output "private_route_table_association_ids" {
  description = "List of IDs of the private route table association"
  value       = aws_route_table_association.private_rtb_association[*].id
}

output "private_network_acl_id" {
  description = "ID of the private network ACL"
  value       = try(aws_network_acl.private[0].id, null)
}

output "private_network_acl_arn" {
  description = "ARN of the private network ACL"
  value       = try(aws_network_acl.private[0].arn, null)
}
