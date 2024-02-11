/**
* AWS EBS Snapshots
* =================
*
* Description
* -----------
* A Terraform module that creates scheduled EBS snapshots for a target StatefulSet and its PVCs.
*
* Usage
* -----
*
* ```ts
* module "ebs_snapshot" {
*  version          = "1.0.1"
*  statefulset_name = "kafka"
*  volumes          = [
*    "datadir-kafka-0, kubernetes-dynamic-pvc-000",
*    "datadir-kafka-1, kubernetes-dynamic-pvc-001",
*    "datadir-kafka-2, kubernetes-dynamic-pvc-002",
*  ]
*  namespace        = "eng-dev"
*  interval         = 24
*  times            = ["23:45"]
*  retention        = 7
* }
* ```
*
* Deployment
* ----------
*
* Deploying this module will create the following resources:
*  - aws_iam_role
*  - aws_iam_role_policy
*  - aws_dlm_lifecycle_policy
*
*/

data "aws_iam_policy_document" "role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dlm_lifecycle_role" {
  name               = "${var.namespace}-${var.statefulset_name}-dlm-lifecycle-role"
  assume_role_policy = "${data.aws_iam_policy_document.role.json}"
}

data "aws_iam_policy_document" "role_policy" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*::snapshot/*"]
  }
}

resource "aws_iam_role_policy" "dlm_lifecycle" {
  name   = "${var.namespace}-${var.statefulset_name}-dlm-lifecycle-policy"
  role   = "${aws_iam_role.dlm_lifecycle_role.id}"
  policy = "${data.aws_iam_policy_document.role_policy.json}"
}

data "null_data_source" "volume" {
  count = "${length(var.volumes)}"

  inputs = {
    pvc_name = "${trimspace(element(split(",", var.volumes[count.index]), 0))}"
    name     = "${trimspace(element(split(",", var.volumes[count.index]), 1))}"
  }
}

resource "aws_dlm_lifecycle_policy" "ebs_snapshot" {
  description        = "Scheduled EBS snapshots of ${lookup(data.null_data_source.volume.*.outputs[count.index], "name")} for PVC ${lookup(data.null_data_source.volume.*.outputs[count.index], "pvc_name")} in namespace ${var.namespace}"
  execution_role_arn = "${aws_iam_role.dlm_lifecycle_role.arn}"
  state              = "ENABLED"
  count              = "${length(var.volumes)}"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "${lookup(data.null_data_source.volume.*.outputs[count.index], "name")} EBS snapshot schedule on ${var.namespace}"

      create_rule {
        interval      = var.interval
        interval_unit = "HOURS"
        times         = var.times
      }

      retain_rule {
        count = "${var.retention}"
      }

      tags_to_add = {
        Name                                      = "backup-${lookup(data.null_data_source.volume.*.outputs[count.index], "name")}"
        SnapshotCreator                           = "${var.statefulset_name}-DLM"
        "kubernetes.io/created-for/pvc/name"      = "${lookup(data.null_data_source.volume.*.outputs[count.index], "pvc_name")}"
        "kubernetes.io/created-for/pvc/namespace" = "${var.namespace}"
      }

      copy_tags = false
    }

    target_tags = {
      Name = "${lookup(data.null_data_source.volume.*.outputs[count.index], "name")}"
    }
  }
}
