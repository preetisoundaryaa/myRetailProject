locals {
  namespaces = toset([
    var.argocd_namespace,
    var.ingress_namespace,
    var.monitoring_namespace,
    var.retail_namespace,
  ])
}

resource "kubernetes_namespace_v1" "this" {
  for_each = local.namespaces

  metadata {
    name = each.value

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "myretail.io/scope"            = each.value
    }
  }
}
