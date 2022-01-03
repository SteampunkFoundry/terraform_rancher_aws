terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = ">= 1.22.1"
    }
  }
}
