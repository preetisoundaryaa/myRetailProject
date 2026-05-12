variable "kubeconfig_path" {
  description = "Path to the kubeconfig used for Docker Desktop Kubernetes."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context for local Docker Desktop."
  type        = string
  default     = "docker-desktop"
}

variable "argocd_namespace" {
  description = "Namespace for Argo CD."
  type        = string
  default     = "argocd"
}

variable "monitoring_namespace" {
  description = "Namespace for Prometheus and Grafana."
  type        = string
  default     = "monitoring"
}

variable "ingress_namespace" {
  description = "Namespace for ingress-nginx."
  type        = string
  default     = "ingress-nginx"
}

variable "retail_namespace" {
  description = "Namespace for the myRetail application."
  type        = string
  default     = "retail"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version."
  type        = string
  default     = "7.4.1"
}

variable "kube_prometheus_stack_chart_version" {
  description = "kube-prometheus-stack Helm chart version."
  type        = string
  default     = "61.7.2"
}

variable "ingress_nginx_chart_version" {
  description = "ingress-nginx Helm chart version."
  type        = string
  default     = "4.11.2"
}

variable "grafana_admin_password" {
  description = "Local Grafana admin password."
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "local_ingress_host" {
  description = "Local hostname routed through ingress-nginx."
  type        = string
  default     = "myretail.local"
}
