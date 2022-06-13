resource "random_password" "rancher_admin" {
  length  = 12
  lower   = true
  number  = true
  special = true
  override_special = "!@#$%^&*"
}

resource "aws_secretsmanager_secret" "rancher_admin" {
  name = "Rancher2Administrator"
  description = "Rancher server admin user and password for ${var.rancher_server_dns}"
  recovery_window_in_days = 0
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "rancher_admin_contents" {
  secret_id = aws_secretsmanager_secret.rancher_admin.id
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
    helm_release.cert_manager
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

data "aws_secretsmanager_secret" "rancher_user_cli" {
  arn = "arn:aws:secretsmanager:us-east-1:476269685748:secret:rancher-user-cli-JXDtI1"
}

data "aws_secretsmanager_secret_version" "rancher_user_cli_contents" {
  secret_id = data.aws_secretsmanager_secret.rancher_user_cli.id
}

resource "rancher2_cloud_credential" "cloud_credential" {
  provider = rancher2.admin
  name = "rancher_cluster_credentials"
  description = "Credentials for local iam user rancher"
  amazonec2_credential_config {
    access_key = jsondecode(data.aws_secretsmanager_secret_version.rancher_user_cli_contents.secret_string)["access_key"]
    secret_key = jsondecode(data.aws_secretsmanager_secret_version.rancher_user_cli_contents.secret_string)["secret_key"]

    default_region = var.aws_region
  }
  depends_on = [
    rancher2_bootstrap.admin,
  ]
}
