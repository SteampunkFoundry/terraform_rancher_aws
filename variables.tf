variable "aws_region" {
  description = "AWS region used for all resources"
  type        = string
}
variable "profile" {
  description = "AWS profile to used to perform CLI commands"
  type        = string
}
variable "name" {
  description = "name prefix used for all resources"
  type        = string
}
variable "vpc_id" {
  description = "VPC id used for all resources"
  type        = string
}
variable "subnet_id" {
  description = "Subnet id used to deploy Rancher resources"
  type        = string
}
variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
}
# Rancher server instance variables
variable "instance_type" {
  description = "ec2 instance type for both Rancher server and for child clusters created via Terraformed Node Template"
  type        = string
}
variable "instance_username" {
  description = "username for ssh login"
  type        = string
}
variable "key_name" {
  description = "ssh keypair name"
  type        = string
}
variable "private_ip" {
  description = "private ip used for single-node rancher server"
  type        = string
}
variable "docker_version" {
  type        = string
  description = "Docker version to install on Rancher server"
}

variable "k3s_version" {
  type        = string
  description = "k3s Kubernetes version in which to install Rancher server (format: vX.Y.Z+k3s1) see https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/rancher-v2-6-2/ for details"
}
variable "cert_manager_version" {
  type        = string
  description = "cert-manager version used to create Rancher ssl cert for UI access (format: vX.Y.Z)"
}
variable "rancher_version" {
  type        = string
  description = "Rancher server version (format: vX.Y.Z)"
}
variable "rancher_server_dns" {
  type        = string
  description = "DNS host name of the Rancher server"
}
# Local variables
variable "ssh_key_path" {
  description = "location of the private key on local device executing terraform to access the rancher server"
  type        = string
  sensitive   = true
}
variable "kubeconfig_path" {
  description = "location of kubeconfig on local device executing Terraform. Kubeconfig is used to access the rancher server via kubectl. Note: if default path (~/.kube/config) is used, Terraform will overwrite any existing config."
  type        = string
  sensitive   = true
}
variable "null_resource_interpreter" {
  description = "Bash interpreter used to execute local commands. For Windows: ['bash', '-c']  For Linux ['/bin/bash','-c']"
  type        = list(string)
}
