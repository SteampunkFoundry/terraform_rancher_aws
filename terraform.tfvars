# General AWS variables
aws_region    = "us-east-1"
profile       = "Webmod-Admin"
name          = "TEST-webmod-rancher"
instance_type = "t3a.medium"
key_name      = "webmod-rancher"
tags = {
  Terraform   = "true"
  Team        = "Webmod"
  Environment = "dev"
}

# VPC variables
vpc_id          = "vpc-03dc11277661baafb"
subnet_id       = "subnet-09dee7714b308cd9a" // Private subnet 1

# Rancher variables
private_ip           = "10.0.0.100"
docker_version       = "20.10"
k3s_version          = "v1.21.5+k3s1"
cert_manager_version = "v1.6.1"
rancher_version      = "v2.5.3"
rancher_server_dns   = "test.webmod.private"

# ssh variables
instance_username = "ubuntu"
#ssh_key_path = ""
null_resource_interpreter = ["bash", "-c"]
#kubeconfig_path = ""
