################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  # count = local.create_public_subnets && var.create_igw ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    { "Name" = var.name },
    var.tags,
    var.igw_tags,
  )
}

################################################################################
# IPv6
################################################################################

#resource "aws_egress_only_internet_gateway" "this" {
#  count = local.vpc_id != "" && var.create_egress_only_igw && var.enable_ipv6 && local.max_subnet_length > 0 ? 1 : 0
#
#  vpc_id = local.vpc_id
#
#  tags = merge(
#    { "Name" = var.name },
#    var.tags,
#    var.igw_tags,
#  )
#}

#resource "aws_route" "private_ipv6_egress" {
#  count = local.create_vpc && var.create_egress_only_igw && var.enable_ipv6 ? local.len_private_subnets : 0
#
#  route_table_id              = element(aws_route_table.private[*].id, count.index)
#  destination_ipv6_cidr_block = "::/0"
#  egress_only_gateway_id      = element(aws_egress_only_internet_gateway.this[*].id, 0)
#}
