resource "random_password" "rancher_admin" {
  length  = 12
  lower   = true
  number  = true
  special = true
  override_special = "!@#$%^&*"
}

resource "aws_secretsmanager_secret" "rancher" {
  name = "RancherAdminTest2"
  description = "Rancher server admin user and password for ${var.rancher_server_dns}"
  recovery_window_in_days = 0
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "secret_contents" {
  secret_id = aws_secretsmanager_secret.rancher.id
  secret_string = <<EOF
   {
    "username": "admin",
    "password": "${random_password.rancher_admin.result}"
   }
  EOF
}

resource "helm_release" "cert_manager" {
  repository       = "https://charts.jetstack.io"
  name             = "cert-manager"
  chart            = "cert-manager"
  version          = var.cert_manager_version
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true

  set {
    name  = "installCRDs"
    value = "true"
  }
  depends_on = [
    null_resource.get_rancher_kubeconfig
  ]
}

resource "helm_release" "rancher_server" {
  repository       = "https://releases.rancher.com/server-charts/stable"
  name             = "rancher"
  chart            = "rancher"
  version          = var.rancher_version
  namespace        = "cattle-system"
  create_namespace = true
  wait             = true

  set {
    name  = "hostname"
    value = var.rancher_server_dns
  }
  set {
    name  = "replicas"
    value = "1"
  }
  set {
    name  = "bootstrapPassword"
    value = "admin"
  }
  depends_on = [
    helm_release.cert_manager,
    random_password.rancher_admin
  ]
}

resource "rancher2_bootstrap" "admin" {
  provider = rancher2.bootstrap
  initial_password = "admin"
  password  = random_password.rancher_admin.result
  depends_on = [
    helm_release.rancher_server,
    random_password.rancher_admin
  ]
}

resource "rancher2_cloud_credential" "cloud_credential" {
  provider = rancher2.admin
  name = "rancher_cluster_credentials"
  description = "Credentials for user ${module.rancher_user.iam_user_name}"
  amazonec2_credential_config {
    access_key = module.rancher_user.iam_access_key_id
    secret_key = module.rancher_user.iam_access_key_secret
    default_region = var.aws_region
  }
  depends_on = [
    rancher2_bootstrap.admin,
    module.rancher_user
  ]
}

resource "rancher2_node_template" "node_template" {
  provider = rancher2.admin
  name = "wedbmod template"
  description = "Template used to provision WebMod cluster"
  engine_install_url = "https://releases.rancher.com/install-docker/${var.docker_version}.sh"
  amazonec2_config {
    access_key = rancher2_cloud_credential.cloud_credential.amazonec2_credential_config[0].access_key
    secret_key = rancher2_cloud_credential.cloud_credential.amazonec2_credential_config[0].secret_key
    ami =  data.aws_ami.ubuntu_20_04.id
    region = var.aws_region
    security_group = ["rancher nodes"]
    subnet_id = var.subnet_id
    vpc_id = var.vpc_id
    zone = trimprefix(data.aws_instance.rancher_instance.availability_zone, var.aws_region)
    encrypt_ebs_volume = true
    iam_instance_profile = module.iam_role_child_clusters.iam_role_name
    instance_type = var.instance_type
    kms_key = data.aws_kms_alias.ebs.target_key_id
    private_address_only = true
    volume_type = "gp3"
    tags = "Rancher Provisioned,true"
  }
}
