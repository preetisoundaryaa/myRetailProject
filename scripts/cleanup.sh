#!/usr/bin/env bash
set -euo pipefail

kubectl delete -f argocd/application.yaml --ignore-not-found=true
terraform -chdir=terraform destroy
