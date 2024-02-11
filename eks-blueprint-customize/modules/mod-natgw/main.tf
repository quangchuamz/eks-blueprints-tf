################################################################################
# NAT Gateway
################################################################################

locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? length(var.azs) : 0 #length(var.azs)
  nat_gateway_ips   = var.reuse_nat_ips ? var.external_nat_ip_ids : try(aws_eip.nat_ip[*].id, [])
}

resource "aws_eip" "nat_ip" {
  count = var.enable_nat_gateway && !var.reuse_nat_ips ? local.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(
    {
      "Name" = format(
        "${var.vpc_name}-%s",
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.tags,
    var.nat_eip_tags,
  )
}

resource "aws_nat_gateway" "natgw" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = element(
    local.nat_gateway_ips,
    var.single_nat_gateway ? 0 : count.index,
  )
  subnet_id = element(
#    aws_subnet.public[*].id,
    var.nat_subnet,
    var.single_nat_gateway ? 0 : count.index,
  )

  tags = merge(
    {
      "Name" = format(
        "${var.vpc_name}-%s",
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.tags,
    var.nat_gateway_tags,
  )

}

#resource "aws_route" "private_nat_gateway" {
#  count = var.enable_nat_gateway ? local.nat_gateway_count : 0
#
##  route_table_id         = element(aws_route_table.private[*].id, count.index)
#  route_table_id         = element(var.private_route_table_ids, count.index)
#  destination_cidr_block = var.nat_gateway_destination_cidr_block
#  nat_gateway_id         = element(aws_nat_gateway.natgw[*].id, count.index)
#
#  timeouts {
#    create = "5m"
#  }
#}

#resource "aws_route" "private_dns64_nat_gateway" {
#  count = local.create_vpc && var.enable_nat_gateway && var.enable_ipv6 && var.private_subnet_enable_dns64 ? local.nat_gateway_count : 0
#
#  route_table_id              = element(aws_route_table.private[*].id, count.index)
#  destination_ipv6_cidr_block = "64:ff9b::/96"
#  nat_gateway_id              = element(aws_nat_gateway.this[*].id, count.index)
#
#  timeouts {
#    create = "5m"
#  }
#}
