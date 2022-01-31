# Webmod's Single Node Rancher Server
This branch contains terraform code to provision a single node Rancher server. This Rancher server is used by Webmod to create a development Kubernetes cluster.

**This infrastructure has already been deployed.** The EC2 instance ssh key and Rancher administrator password are stored in AWS Secrets Manager.
### Prerequisites
1. Active Wireguard configuration to Webmod AWS environment
2. Active AWS CLI credential profile via SSO with admin access
3. Set the s3 backend:
```terraform
terraform {
  backend "s3" {
    bucket = "webmod-tfstate"
    key    = "infra/rancher"
    region = "us-east-1"
    profile = "Webmod-Admin"
  }
}
```
4. Review terraform.tfvars file and set variables (defaults already pre-populated)  
   Note: Two (2) variables were left out of terraform.tfvars file due to sensitivity and require input on command line (shown in Deploy Section)  
      1. `kubeconfig_path`
      2. `ssh_key_path`<br>
### Deploy
```console
terraform init -var kubeconfig_path=</path/to/kubeconfig> -var ssh_key_path=</path/to/rancher/ec2/private/key>
terraform apply -var kubeconfig_path=</path/to/kubeconfig> -var ssh_key_path=</path/to/rancher/ec2/private/key>
```
Another option is to set the variables as environment variables:  
```console
export TF_VAR_kubeconfig_path=</path/to/kubeconfig>
export TF_VAR_ssh_key_path=</path/to/rancher/ec2/private/key>
terraform init
terraform apply
```
Note: Default kubeconfig path is typically located `~/.kube/config`  

After provisioning is complete
```terraform
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.
```
 Access to Rancher server will be available using the rancher_server_dns endpoint variable:  https://rancher.webmod.private

### Removal
```console
terraform refresh -var kubeconfig_path=</path/to/kubeconfig> -var ssh_key_path=</path/to/rancher/ec2/private/key>
terraform destroy -var kubeconfig_path=</path/to/kubeconfig> -var ssh_key_path=</path/to/rancher/ec2/private/key>
```
After destroy is complete
```terraform
Destroy complete! Resources: 25 destroyed.
```

## IN-PROGRESS
Addition of code to provision networking (VPC,subnet,NAT gateway, etc.) and DNS (Route53 - private hosted zone) infrastructure.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.63 |
| <a name="requirement_rancher2"></a> [rancher2](#requirement\_rancher2) | >= 1.22.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.74.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.4.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.0 |
| <a name="provider_rancher2.admin"></a> [rancher2.admin](#provider\_rancher2.admin) | 1.22.2 |
| <a name="provider_rancher2.bootstrap"></a> [rancher2.bootstrap](#provider\_rancher2.bootstrap) | 1.22.2 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_role_child_clusters"></a> [iam\_role\_child\_clusters](#module\_iam\_role\_child\_clusters) | terraform-aws-modules/iam/aws//modules/iam-assumable-role | ~> 4.0 |
| <a name="module_rancher_server_sg"></a> [rancher\_server\_sg](#module\_rancher\_server\_sg) | terraform-aws-modules/security-group/aws | ~> 4.7.0 |
| <a name="module_rancher_user"></a> [rancher\_user](#module\_rancher\_user) | terraform-aws-modules/iam/aws//modules/iam-user | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.child_cluster_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_user_policy.rancher_user_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |
| [aws_instance.rancher_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_secretsmanager_secret.rancher](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.secret_contents](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.rancher_server](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.get_rancher_kubeconfig](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_for_cloudinit](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [rancher2_bootstrap.admin](https://registry.terraform.io/providers/rancher/rancher2/latest/docs/resources/bootstrap) | resource |
| [rancher2_cloud_credential.cloud_credential](https://registry.terraform.io/providers/rancher/rancher2/latest/docs/resources/cloud_credential) | resource |
| [rancher2_global_dns_provider.route53](https://registry.terraform.io/providers/rancher/rancher2/latest/docs/resources/global_dns_provider) | resource |
| [rancher2_node_template.node_template](https://registry.terraform.io/providers/rancher/rancher2/latest/docs/resources/node_template) | resource |
| [random_password.rancher_admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_ami.ubuntu_20_04](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.ec2_trust_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_instance.rancher_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instance) | data source |
| [aws_kms_alias.ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |
| [aws_route53_zone.dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_vpc.eks-rancher](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region used for all resources | `string` | n/a | yes |
| <a name="input_cert_manager_version"></a> [cert\_manager\_version](#input\_cert\_manager\_version) | cert-manager version used to create Rancher ssl cert for UI access (format: vX.Y.Z) | `string` | n/a | yes |
| <a name="input_docker_version"></a> [docker\_version](#input\_docker\_version) | Docker version to install on Rancher server | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | ec2 instance type for both Rancher server and for child clusters created via Terraformed Node Template | `string` | n/a | yes |
| <a name="input_instance_username"></a> [instance\_username](#input\_instance\_username) | username for ssh login | `string` | n/a | yes |
| <a name="input_k3s_version"></a> [k3s\_version](#input\_k3s\_version) | k3s Kubernetes version in which to install Rancher server (format: vX.Y.Z+k3s1) see https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/rancher-v2-6-2/ for details | `string` | n/a | yes |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | ssh keypair name | `string` | n/a | yes |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | location of kubeconfig on local device executing Terraform. Kubeconfig is used to access the rancher server via kubectl. Note: if default path (~/.kube/config) is used, Terraform will overwrite any existing config. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | name prefix used for all resources | `string` | n/a | yes |
| <a name="input_null_resource_interpreter"></a> [null\_resource\_interpreter](#input\_null\_resource\_interpreter) | Bash interpreter used to execute local commands. For Windows: ['bash', '-c']  For Linux ['/bin/bash','-c'] | `list(string)` | n/a | yes |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | private ip used for single-node rancher server | `string` | n/a | yes |
| <a name="input_profile"></a> [profile](#input\_profile) | AWS profile to used to perform CLI commands | `string` | n/a | yes |
| <a name="input_rancher_server_dns"></a> [rancher\_server\_dns](#input\_rancher\_server\_dns) | DNS host name of the Rancher server | `string` | n/a | yes |
| <a name="input_rancher_version"></a> [rancher\_version](#input\_rancher\_version) | Rancher server version (format: vX.Y.Z) | `string` | n/a | yes |
| <a name="input_ssh_key_path"></a> [ssh\_key\_path](#input\_ssh\_key\_path) | location of the private key on local device executing terraform to access the rancher server | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet id used to deploy Rancher resources | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources | `map(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC id used for all resources | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
