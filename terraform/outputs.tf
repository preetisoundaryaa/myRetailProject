output "argocd_namespace" {
  description = "Namespace where Argo CD is installed."
  value       = var.argocd_namespace
}

output "retail_namespace" {
  description = "Namespace where Argo CD deploys the myRetail app."
  value       = var.retail_namespace
}

output "monitoring_namespace" {
  description = "Namespace where kube-prometheus-stack is installed."
  value       = var.monitoring_namespace
}

output "ingress_namespace" {
  description = "Namespace where ingress-nginx is installed."
  value       = var.ingress_namespace
}

output "argocd_port_forward" {
  description = "Command to open the Argo CD UI locally."
  value       = "kubectl -n ${var.argocd_namespace} port-forward svc/argocd-server 8080:80"
}

output "grafana_port_forward" {
  description = "Command to open Grafana locally."
  value       = "kubectl -n ${var.monitoring_namespace} port-forward svc/kube-prometheus-stack-grafana 3000:80"
}

output "myretail_url" {
  description = "Local ingress URL after adding the host entry."
  value       = "http://${var.local_ingress_host}"
}
