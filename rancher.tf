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

# # Rancher certificates
# data "kubernetes_secret" "rancher_cert" {
#   depends_on = [helm_release.rancher_server]

#   metadata {
#     name      = "tls-rancher-ingress"
#     namespace = "cattle-system"
#   }
# }

resource "rancher2_bootstrap" "admin" {
  password  = var.rancher_password
  depends_on = [
    helm_release.rancher_server
  ]
}