variable "statefulset_name" {
  type        = string
  description = "Name of the StatefulSet for which EBS snapshots will be taken."
}

variable "volumes" {
  type        = list
  description = "List of EBS Volume details, in the format of 'pvc_name, volume_name'."
}

variable "namespace" {
  type        = string
  description = "The namespace that the volumes are used in."
}

variable "interval" {
  description = "The snapshot schedule interval in hours. 2,3,4,6,8,12,24 are the only accepted values."
  default     = 24
}

variable "times" {
  type        = list
  description = "List of times at which to take EBS snapshots."
  default     = ["23:45"]
}

variable "retention" {
  description = "The number of EBS snapshots to retain."
  default     = 7
}
