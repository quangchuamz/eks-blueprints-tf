data "aws_vpc" "vpc_id" {
  id = var.vpc_id
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc_id.id]
  }

  filter {
    name   = "cidr-block"
    values = var.subnet_cidrs
  }
}

# Fetch the details of each subnet to get the availability zone
data "aws_subnet" "details" {
  for_each = toset(data.aws_subnets.selected.ids)

  id = each.value
}

resource "aws_ec2_tag" "update" {
  for_each = data.aws_subnet.details

  resource_id = each.value.id
  key         = "Name"
  value       = "${var.base_name}-${var.specific_name}-${each.value.availability_zone}"
}
