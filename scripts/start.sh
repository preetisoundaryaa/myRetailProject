#!/usr/bin/env bash
set -euo pipefail

terraform -chdir=terraform init
terraform -chdir=terraform apply
kubectl apply -f argocd/application.yaml

echo "Add '127.0.0.1 myretail.local' to /etc/hosts, then open http://myretail.local"
