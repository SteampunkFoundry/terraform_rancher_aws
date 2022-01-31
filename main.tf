terraform {
  backend "s3" {
    bucket = "webmod-tfstate"
    key    = "infra/test-rancher"
    region = "us-east-1"
    profile = "Webmod-Admin"
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
