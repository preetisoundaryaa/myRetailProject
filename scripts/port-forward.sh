#!/usr/bin/env bash
set -euo pipefail

case "${1:-app}" in
  app)
    kubectl -n retail port-forward svc/myretail 8000:80
    ;;
  argocd)
    kubectl -n argocd port-forward svc/argocd-server 8080:80
    ;;
  grafana)
    kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
    ;;
  prometheus)
    kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
    ;;
  *)
    echo "Usage: $0 [app|argocd|grafana|prometheus]"
    exit 1
    ;;
esac
