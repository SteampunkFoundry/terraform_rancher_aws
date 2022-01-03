terraform {
  backend "s3" {
    bucket = "webmod-tfstate"
    key    = "infra/rancher"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "rancher2" {
  api_url = "https://${var.rancher_server_dns}"
  bootstrap = true
  insecure = true
}