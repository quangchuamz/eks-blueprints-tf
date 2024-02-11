locals {
  len_private_subnets     = max(length(var.private_subnets), length(var.private_subnet_ipv6_prefixes))
}
