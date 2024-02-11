#!/bin/bash

# Create the empty files
touch locals.tf main.tf outputs.tf variables.tf

# Populate versions.tf with the specified content
cat <<EOF > versions.tf
terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}
EOF

echo "Files created successfully."
