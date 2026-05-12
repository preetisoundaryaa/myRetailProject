resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace_v1.this[var.ingress_namespace].metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_chart_version

  values = [
    yamlencode({
      controller = {
        ingressClass = "nginx"
        ingressClassResource = {
          enabled = true
          name    = "nginx"
          default = true
        }
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]
}
