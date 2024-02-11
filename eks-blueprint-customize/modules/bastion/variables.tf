variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
}

variable "public_subnet_id" {
  description = "Public subnet to create bastion in."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC the EKS is to be deployed in; must have enable_dns_hostnames set to true."
}

variable "cidr_blocks" {
  type        = list(string)
  description = "A list of IP to allow access to bastion."
}

variable "bastion_ssh_pub_key" {
  type        = string
  description = "The public key for the bastion host user to accept."
}

variable "cluster_security_group" {
  type        = string
  description = "The Cluster Security Group is a unified security group that is used to control communications between the Kubernetes control plane and compute resources on the cluster."
}

variable "ami_name" {
  type        = string
  description = "Name of the AMI to use for the bastion instance."
}

variable "instance_type" {
  type        = string
  description = "AWS instance type of the bastion VM"
  default     = "t3.micro"
}

variable "volume_size" {
  type        = number
  description = "AWS bastion instance disk size in GiB"
  default     = 8
}

variable "instance_profile_name" {
  type        = string
  description = "AWS IAM instance profile name to be assumed by bastion"
  default     = null
}
