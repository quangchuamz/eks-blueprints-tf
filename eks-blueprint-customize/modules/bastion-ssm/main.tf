/**
* AWS Bastion host - SSM Enabled
* ===========
*
* Description
* -----------
*
* This module creates an AutoScaling Group for bastion instances with SSM enabled without the need of a public IP address.
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
*  source                 = "terraform.external.thoughtmachine.io/aux/bastion-ssm/aws"
*  version                = "4.0.0"
*  vpc_id                 = "my-vpc"
*  cluster_name           = "my_eks_cluster"
*  kubectl_version        = "1.14.10"
*  private_subnet_ids     = ["subnet-07299209"]
*  cluster_security_group = module.vpc.default_security_group_id
*  ami_name               = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20200131"
* }
* ```
*
* Deployment
* ----------
*   * `aws_iam_role.bastion_role`
*   * `aws_iam_role_policy_attachment.bastion`
*   * `aws_iam_instance_profile.bastion`
*   * `aws_launch_configuration.bastion`
*   * `aws_autoscaling_group.bastion`
*   * `aws_instance.bastion`
**/

locals {
  kubectl_version = "1.19.16"
  kubectl_sha512  = "9524a026af932ac9ca1895563060f7fb3b89f1387016e69a1a73cf7ce0f9baa54775b00c886557a97bae9b6dbc1b49c045da5dcea9ca2c1452c18c5c45fefd55"
  user_data       = <<-EOT
#!/bin/bash

if ! snap list amazon-ssm-agent &>/dev/null 2>&1
then
  echo "install amazon ssm agent"
  sudo snap install amazon-ssm-agent
else
  echo "no need to install amazon ssm agent, refreshing instead"
  sudo snap refresh amazon-ssm-agent
fi

if [ "$(systemctl is-enabled snap.amazon-ssm-agent.amazon-ssm-agent)" == "disabled" ]
then
  echo "amazon ssm agent service is not enabled. enabling now"
  sudo systemctl enable /etc/systemd/system/snap.amazon-ssm-agent.amazon-ssm-agent.service
else
  echo "amazon ssm agent service is enabled"
fi

if [ "$(systemctl is-active snap.amazon-ssm-agent.amazon-ssm-agent)" == "inactive" ]
then
  echo "amazon ssm agent service is inactive. activating now"
  sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent
else
  echo "amazon ssm agent service is active"
fi

curl -LO https://storage.googleapis.com/kubernetes-release/release/v${local.kubectl_version}/bin/linux/amd64/kubectl
chmod +x ./kubectl

if [ "$(sha512sum ./kubectl | awk '{print $1}')" != "${local.kubectl_sha512}" ]
then
  echo "I downloaded a kubectl with an invalid SHA512 sum. Not proceeding"
  rm ./kubectl
else
  sudo mv ./kubectl /bin/kubectl
  mkdir -p ~/.kube && sudo mkdir -p /root/.kube
fi

EOT
}

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

resource "aws_iam_instance_profile" "bastion" {
  name = "bastion-${var.cluster_name}-profile"
  role = aws_iam_role.bastion_role.name
}

resource "aws_iam_role" "bastion_role" {
  name = "bastion-${var.cluster_name}-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "bastion" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_launch_template" "bastion" {
  name_prefix            = "ssm-bastion-${var.cluster_name}-lt"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = "t3.xlarge"
  user_data              = base64encode(local.user_data)
  vpc_security_group_ids = [var.cluster_security_group]
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.bastion.name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name     = "bastion-${var.cluster_name}-asg"
  max_size = var.asg_max_size
  min_size = var.asg_min_size

  force_delete        = true
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.bastion.id
    version = "$Latest"
  }

#  tags = [
#    {
#      "key"                 = "Name"
#      "value"               = "bastion-${var.cluster_name}"
#      "propagate_at_launch" = true
#    },
#  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [min_size]
  }
}

