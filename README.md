# Webmod's Single Node Rancher Server
This branch contains terraform code to provision a single node Rancher server. This Rancher server is used by Webmod to create a development Kubernetes cluster.

**This infrastructure has already been deployed.** The EC2 instance ssh key and Rancher administrator password are stored in AWS Secrets Manager.
### Prerequisites
1. Active Wireguard configuration to Webmod AWS environment
2. AWS CLI credentials with ec2 and security group creation access
3. Review terraform.tfvars file and ensure variables are set properly (defaults already filled)<br>
   **Note: Three (3) variables were left out of terraform.tfvars file due to sensitivity and require input on command line (shown in step 3)**<br>
   These variables are:
      1. `kubeconfig_path`
      2. `ssh_key_path`
      3. `rancher_password`<br>
### Deploy
1. Run `terraform init -var kubeconfig_path=</path/to/kubeconfig> -var ssh_key_path=</path/to/rancher/ec2/private/key> -var rancher_password=<SuperStrongPassword>`<br>
2. Run `terraform apply -var kubeconfig_path=</path/to/kubeconfig> -var ssh_key_path=</path/to/rancher/ec2/private/key> -var rancher_password=<SuperStrongPassword>`<br>
   **Note: Default kubeconfig path is typically `~/.kube/config` <br>
3. After provisioning, access to Rancher server will be available (https://rancher.webmod.private)
### Removal
1. Run `terraform destroy -var kubeconfig_path=</path/to/kubeconfig> -var ssh_key_path=</path/to/rancher/ec2/private/key> -var rancher_password=<SuperStrongPassword>`<br>

## IN-PROGRESS
Add networking (VPC,subnet,NAT gateway, etc.) and Route53 (webmod.private private hosted zone) infrastructure  
