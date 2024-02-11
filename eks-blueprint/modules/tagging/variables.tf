variable "subnet_cidrs" {
  description = "A list of subnet CIDR blocks to update tags for"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC where the subnets are located"
  type        = string
}

variable "specific_name" {
  description = "A specific name to be included in the subnet's Name tag"
  type        = string
}

variable "base_name" {
  description = "Base name to be prefixed in the subnet's Name tag"
  type        = string
}
