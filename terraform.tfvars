# General AWS variables
aws_region    = "us-east-1"
instance_type = "t3a.medium"
key_name      = "webmod-rancher"
name          = "webmod-rancher"
tags = {
  Terraform   = "true"
}

# VPC variables
vpc_id          = "vpc-03dc11277661baafb"
subnet_id       = "subnet-09dee7714b308cd9a" // Private subnet 1
private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
public_subnets  = ["10.0.100.0/19"]

# RDS variables
#db_instance_type = "db.t3.medium"
#db_storage       = "20"
#db_password      = ""
#db_name          = "datastore"

# Rancher variables
private_ip           = "10.0.0.25"
docker_version       = "20.10"
k3s_version          = "v1.21.5+k3s1"
cert_manager_version = "v1.6.1"
rancher_version      = "v2.6.3"
rancher_server_dns   = "rancher.webmod.private"
#rancher_password     = ""

# ssh variables
instance_username = "ubuntu"
#ssh_key_path = ""
null_resource_interpreter = ["bash", "-c"]
#kubeconfig_path = ""
