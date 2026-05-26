terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 1.5"
    }
  }

  required_version = ">= 1.1"
}

provider "aws" {
  region = var.region
}
