terraform {
  backend "s3" {
    bucket = "webmod-tfstate"
    key    = "infra/rancher2"
    region = "us-east-1"
    profile = "webmod-admin"
  }
}
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = "webmod-tfstate"
    key     = "infra/network"
    region  = "us-east-1"
    profile = var.profile
  }
}
data "terraform_remote_state" "route53" {
  backend = "s3"
  config = {
    bucket  = "webmod-tfstate"
    key     = "infra/route53"
    region  = "us-east-1"
    profile = var.profile
  }
}
provider "aws" {
  region = var.aws_region
  profile = var.profile
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "rancher2" {
  alias = "bootstrap"
  api_url = "https://${var.rancher_server_dns}"
  bootstrap = true
  insecure = true
}

provider "rancher2" {
  alias = "admin"
  api_url = "https://${var.rancher_server_dns}"
  token_key = rancher2_bootstrap.admin.token
  insecure = true
}
