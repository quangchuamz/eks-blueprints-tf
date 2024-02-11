variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
}

variable "private_subnet_ids" {
  description = "Private subnet ids for bastion with SSM."
  type        = list(string)
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC the EKS is to be deployed in; must have enable_dns_hostnames set to true."
}

variable "cluster_security_group" {
  type        = string
  description = "The Cluster Security Group is a unified security group that is used to control communications between the Kubernetes control plane and compute resources on the cluster."
}

variable "kubectl_version" {
  type        = string
  description = "Version of kubectl to download to bastion instance."
  default     = "1.18.6"
}

variable "ami_name" {
  type        = string
  description = "Name of the AMI to use for the bastion instance."
}

variable "bastion_count" {
  default     = 0
  description = "Number of bastion instances to provision within the private subnet to access eks cluster."
}

variable "asg_max_size" {
  default     = 1
  description = "Maximum size of the bastion autoscaling group."
}

variable "asg_min_size" {
  default     = 0
  description = "Minimum soze of the bastion autoscaling group."
}

