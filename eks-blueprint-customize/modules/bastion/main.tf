/**
* AWS Bastion host
* ===========
*
* Description
* -----------
*
* This module creates an EC2 instance resource which can be used as bastion.
* Bastion hosts in your VPC environment enable you to securely connect to your Linux instances
* without exposing your environment to the Internet.
* After you set up your bastion hosts, you can access the other instances in your VPC through Secure Shell (SSH)
* connections on Linux. Bastion hosts are also configured with security groups to provide fine-grained ingress control.
*
* Usage
* -----
*
* ```ts
* module "bastion" {
*  source                 = "terraform.external.thoughtmachine.io/aux/bastion/aws"
*  version                = "2.0.1"
*  vpc_id                 = "my-vpc"
*  cluster_name           = "my_eks_cluster"
*  bastion_ssh_pub_key    = "ssh-rsa ... bastion@my-favourite-cluster"
*  public_subnet_ids      = "10.143.31.0/26"
*  cluster_security_group = "sg-0004445555"
*  cidr_blocks            = ["212.36.160.18/32", "10.0.0.0/8"]
*  ami_name               = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20200131"
* }
* ```
*
* Deployment
* ----------
*   * `aws_security_group.bastion_security_group`
*   * `aws_security_group_rule.bastion_access_rule``
*   * `aws_key_pair.deployer`
*   * `aws_instance.bastion`
**/

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_security_group" "bastion_security_group" {
  name        = "bastion-${var.cluster_name}"
  description = "Cluster communication bastion"
  vpc_id      = var.vpc_id
  tags = {
    "Name" = "bastion-${var.cluster_name}"
  }
}

resource "aws_security_group_rule" "bastion_access_rule" {
  description = "Access of outbound traffic and connect to k8s"
  type        = "ingress"

  from_port = 22
  to_port   = 22
  protocol  = "tcp"

  # Please restrict your ingress to only necessary IPs and ports.
  # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
  cidr_blocks = var.cidr_blocks

  security_group_id = aws_security_group.bastion_security_group.id
}

resource "aws_key_pair" "deployer" {
  key_name   = "bastion-${var.cluster_name}"
  public_key = var.bastion_ssh_pub_key
}

resource "aws_instance" "bastion" {
  ami = data.aws_ami.ubuntu.id

  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = "true"

  monitoring = "false"

  vpc_security_group_ids = [aws_security_group.bastion_security_group.id, var.cluster_security_group]

  root_block_device {
    volume_size = var.volume_size
  }

  iam_instance_profile = length(var.instance_profile_name) > 0 ? var.instance_profile_name : null

  tags = {
    Name = "tf-eks-bastion-${var.cluster_name}"
  }
}

