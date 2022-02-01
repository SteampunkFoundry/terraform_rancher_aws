# General AWS variables
aws_region    = "us-east-1"
profile       = "Webmod-Admin"
tags = {
  Terraform   = "true"
  Team        = "Webmod"
  Environment = "dev"
}

name          = "webmod"
instance_type = "t3a.medium"

# Rancher variables
docker_version       = "20.10"
k3s_version          = "v1.21.5+k3s1"
cert_manager_version = "v1.6.1"
rancher_version      = "v2.5.3"
rancher_server_dns   = "rancher.webmod.private"

# ssh variables
instance_username = "ubuntu"
#ssh_key_path = ""
null_resource_interpreter = ["bash", "-c"]
#kubeconfig_path = ""
