terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.36.0"
    }
    random = {
      version = ">= 3"
    }
  }
}
