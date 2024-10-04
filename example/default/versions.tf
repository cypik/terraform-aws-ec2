# Terraform version
terraform {
  required_version = ">= 1.9.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.67.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 2.0.0"
    }
  }
}