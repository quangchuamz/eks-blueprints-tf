
################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  count = local.create_vpc ? 1 : 0

  cidr_block          = var.use_ipam_pool ? null : var.cidr
  ipv4_ipam_pool_id   = var.ipv4_ipam_pool_id
  ipv4_netmask_length = var.ipv4_netmask_length

  assign_generated_ipv6_cidr_block     = var.enable_ipv6 && !var.use_ipam_pool ? true : null
  ipv6_cidr_block                      = var.ipv6_cidr
  ipv6_ipam_pool_id                    = var.ipv6_ipam_pool_id
  ipv6_netmask_length                  = var.ipv6_netmask_length
  ipv6_cidr_block_network_border_group = var.ipv6_cidr_block_network_border_group

  instance_tenancy                     = var.instance_tenancy
  enable_dns_hostnames                 = var.enable_dns_hostnames
  enable_dns_support                   = var.enable_dns_support
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics

  tags = merge(
    { "Name" = var.name },
    var.tags,
    var.vpc_tags,
  )
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count = local.create_vpc && length(var.secondary_cidr_blocks) > 0 ? length(var.secondary_cidr_blocks) : 0

  # Do not turn this into `local.vpc_id`
  vpc_id = aws_vpc.this[0].id

  cidr_block = element(var.secondary_cidr_blocks, count.index)
}

################################################################################
# DHCP Options Set
################################################################################

resource "aws_vpc_dhcp_options" "this" {
  count = local.create_vpc && var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type

  tags = merge(
    { "Name" = var.name },
    var.tags,
    var.dhcp_options_tags,
  )
}

resource "aws_vpc_dhcp_options_association" "this" {
  count = local.create_vpc && var.enable_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.this[0].id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

#
#################################################################################
## Default VPC
#################################################################################
#
#resource "aws_default_vpc" "this" {
#  count = var.manage_default_vpc ? 1 : 0
#
#  enable_dns_support   = var.default_vpc_enable_dns_support
#  enable_dns_hostnames = var.default_vpc_enable_dns_hostnames
#
#  tags = merge(
#    { "Name" = coalesce(var.default_vpc_name, "default") },
#    var.tags,
#    var.default_vpc_tags,
#  )
#}
#
#resource "aws_default_security_group" "this" {
#  count = local.create_vpc && var.manage_default_security_group ? 1 : 0
#
#  vpc_id = aws_vpc.this[0].id
#
#  dynamic "ingress" {
#    for_each = var.default_security_group_ingress
#    content {
#      self             = lookup(ingress.value, "self", null)
#      cidr_blocks      = compact(split(",", lookup(ingress.value, "cidr_blocks", "")))
#      ipv6_cidr_blocks = compact(split(",", lookup(ingress.value, "ipv6_cidr_blocks", "")))
#      prefix_list_ids  = compact(split(",", lookup(ingress.value, "prefix_list_ids", "")))
#      security_groups  = compact(split(",", lookup(ingress.value, "security_groups", "")))
#      description      = lookup(ingress.value, "description", null)
#      from_port        = lookup(ingress.value, "from_port", 0)
#      to_port          = lookup(ingress.value, "to_port", 0)
#      protocol         = lookup(ingress.value, "protocol", "-1")
#    }
#  }
#
#  dynamic "egress" {
#    for_each = var.default_security_group_egress
#    content {
#      self             = lookup(egress.value, "self", null)
#      cidr_blocks      = compact(split(",", lookup(egress.value, "cidr_blocks", "")))
#      ipv6_cidr_blocks = compact(split(",", lookup(egress.value, "ipv6_cidr_blocks", "")))
#      prefix_list_ids  = compact(split(",", lookup(egress.value, "prefix_list_ids", "")))
#      security_groups  = compact(split(",", lookup(egress.value, "security_groups", "")))
#      description      = lookup(egress.value, "description", null)
#      from_port        = lookup(egress.value, "from_port", 0)
#      to_port          = lookup(egress.value, "to_port", 0)
#      protocol         = lookup(egress.value, "protocol", "-1")
#    }
#  }
#
#  tags = merge(
#    { "Name" = coalesce(var.default_security_group_name, "${var.name}-default") },
#    var.tags,
#    var.default_security_group_tags,
#  )
#}
#
#################################################################################
## Default Network ACLs
#################################################################################
#
#resource "aws_default_network_acl" "this" {
#  count = local.create_vpc && var.manage_default_network_acl ? 1 : 0
#
#  default_network_acl_id = aws_vpc.this[0].default_network_acl_id
#
#  # subnet_ids is using lifecycle ignore_changes, so it is not necessary to list
#  # any explicitly. See https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/736
#  subnet_ids = null
#
#  dynamic "ingress" {
#    for_each = var.default_network_acl_ingress
#    content {
#      action          = ingress.value.action
#      cidr_block      = lookup(ingress.value, "cidr_block", null)
#      from_port       = ingress.value.from_port
#      icmp_code       = lookup(ingress.value, "icmp_code", null)
#      icmp_type       = lookup(ingress.value, "icmp_type", null)
#      ipv6_cidr_block = lookup(ingress.value, "ipv6_cidr_block", null)
#      protocol        = ingress.value.protocol
#      rule_no         = ingress.value.rule_no
#      to_port         = ingress.value.to_port
#    }
#  }
#  dynamic "egress" {
#    for_each = var.default_network_acl_egress
#    content {
#      action          = egress.value.action
#      cidr_block      = lookup(egress.value, "cidr_block", null)
#      from_port       = egress.value.from_port
#      icmp_code       = lookup(egress.value, "icmp_code", null)
#      icmp_type       = lookup(egress.value, "icmp_type", null)
#      ipv6_cidr_block = lookup(egress.value, "ipv6_cidr_block", null)
#      protocol        = egress.value.protocol
#      rule_no         = egress.value.rule_no
#      to_port         = egress.value.to_port
#    }
#  }
#
#  tags = merge(
#    { "Name" = coalesce(var.default_network_acl_name, "${var.name}-default") },
#    var.tags,
#    var.default_network_acl_tags,
#  )
#
#  lifecycle {
#    ignore_changes = [subnet_ids]
#  }
#}
#
#################################################################################
## Default Route
#################################################################################
#
#resource "aws_default_route_table" "default" {
#  count = local.create_vpc && var.manage_default_route_table ? 1 : 0
#
#  default_route_table_id = aws_vpc.this[0].default_route_table_id
#  propagating_vgws       = var.default_route_table_propagating_vgws
#
#  dynamic "route" {
#    for_each = var.default_route_table_routes
#    content {
#      # One of the following destinations must be provided
#      cidr_block      = route.value.cidr_block
#      ipv6_cidr_block = lookup(route.value, "ipv6_cidr_block", null)
#
#      # One of the following targets must be provided
#      egress_only_gateway_id    = lookup(route.value, "egress_only_gateway_id", null)
#      gateway_id                = lookup(route.value, "gateway_id", null)
#      instance_id               = lookup(route.value, "instance_id", null)
#      nat_gateway_id            = lookup(route.value, "nat_gateway_id", null)
#      network_interface_id      = lookup(route.value, "network_interface_id", null)
#      transit_gateway_id        = lookup(route.value, "transit_gateway_id", null)
#      vpc_endpoint_id           = lookup(route.value, "vpc_endpoint_id", null)
#      vpc_peering_connection_id = lookup(route.value, "vpc_peering_connection_id", null)
#    }
#  }
#
#  timeouts {
#    create = "5m"
#    update = "5m"
#  }
#
#  tags = merge(
#    { "Name" = coalesce(var.default_route_table_name, "${var.name}-default") },
#    var.tags,
#    var.default_route_table_tags,
#  )
#}
