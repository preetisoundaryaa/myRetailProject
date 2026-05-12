# myRetail DevOps Platform

myRetail is a Flask demo application packaged as a production-style DevOps portfolio project. The application is containerized with Docker, deployed with Helm through Argo CD, and supported by Terraform-managed local platform services on Docker Desktop Kubernetes.

## Architecture

```text
Developer / GitHub
      |
      | push to main
      v
GitHub Actions
  - test Flask app
  - lint/validate Terraform
  - lint/render Helm
  - build and push Docker image
  - update Helm image tag
      |
      v
Docker Hub image
      |
      v
GitOps repository state
      |
      v
Argo CD
      |
      v
retail namespace
  - myRetail Deployment
  - ClusterIP Service
  - Ingress myretail.local
  - ServiceMonitor
  - Grafana dashboard ConfigMap

Terraform provisions platform namespaces and Helm releases:
  - argocd namespace: Argo CD
  - ingress-nginx namespace: NGINX Ingress Controller
  - monitoring namespace: kube-prometheus-stack
  - retail namespace: application target namespace
```

## Technology Stack

- Python Flask application with Prometheus metrics
- Gunicorn production WSGI server
- Docker image running as a non-root user
- Kubernetes on Docker Desktop
- Helm application chart in `helm/myretail`
- Argo CD GitOps application in `argocd/application.yaml`
- Terraform with Kubernetes and Helm providers
- ingress-nginx for local ingress
- kube-prometheus-stack for Prometheus and Grafana
- GitHub Actions CI/CD

## Project Structure

```text
myRetailProject/
├── app/
├── static/
├── tests/
├── Dockerfile
├── requirements.txt
├── helm/
│   └── myretail/
├── terraform/
├── argocd/
├── k8s/
│   └── ingress/
├── monitoring/
├── scripts/
├── .github/
│   └── workflows/
│       └── cicd.yaml
└── README.md
```

## Local Prerequisites

- Docker Desktop with Kubernetes enabled
- `kubectl`
- `helm`
- `terraform`
- Docker Hub account

Confirm the cluster context:

```bash
kubectl config use-context docker-desktop
kubectl get nodes
```

## Run the App Locally with Docker

```bash
docker build -t myretail-app:local .
docker run --rm -p 8000:8000 myretail-app:local
```

Open:

```text
http://localhost:8000
```

Health check:

```bash
curl http://localhost:8000/health
```

## Provision Platform with Terraform

Terraform installs platform components only. It does not deploy the myRetail application chart directly; Argo CD owns the application deployment.

```bash
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform apply
```

Terraform creates:

- `argocd`
- `monitoring`
- `ingress-nginx`
- `retail`

Terraform installs:

- Argo CD via Helm
- kube-prometheus-stack via Helm
- ingress-nginx via Helm

Useful outputs include port-forward commands for Argo CD and Grafana.

## Deploy with Argo CD

After Terraform finishes, apply the Argo CD application:

```bash
kubectl apply -f argocd/application.yaml
```

Argo CD watches this repository on `main` and syncs the Helm chart from:

```text
helm/myretail
```

The application is deployed into the `retail` namespace.

Check sync status:

```bash
kubectl -n argocd get applications.argoproj.io
kubectl -n retail get pods,svc,ingress
```

Open the Argo CD UI:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:80
```

Then browse to `http://localhost:8080`.

## Local Ingress

The Helm chart creates an ingress for:

```text
myretail.local
```

Add this line to `/etc/hosts` on macOS/Linux, or to `C:\Windows\System32\drivers\etc\hosts` on Windows:

```text
127.0.0.1 myretail.local
```

Open:

```text
http://myretail.local
```

TLS is intentionally not configured for the local demo. In production, use cert-manager with a real DNS name and an issuer such as Let's Encrypt.

## Helm Deployment

For direct local testing without Argo CD:

```bash
helm lint helm/myretail
helm template myretail helm/myretail --namespace retail
helm upgrade --install myretail helm/myretail --namespace retail --create-namespace
```

Argo CD is still the intended deployment path for the portfolio workflow.

## Monitoring

kube-prometheus-stack runs in the `monitoring` namespace. The app chart creates:

- `ServiceMonitor` for `/metrics`
- Grafana dashboard ConfigMap labeled for the Grafana sidecar

Open Grafana:

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

Default local credentials:

```text
admin / admin
```

Open:

```text
http://localhost:3000
```

## CI/CD

The workflow in `.github/workflows/cicd.yaml` runs on pushes to `main`.

It performs:

- Python dependency install and tests
- Terraform format check, init, and validate
- Helm lint and manifest rendering
- Docker image build and push
- Docker tags for commit SHA and `latest`
- Safe Helm image tag update committed back to the repository

The image tag update commit uses `[skip ci]` to avoid a workflow loop.

## Required GitHub Secrets

Set these repository secrets in GitHub:

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD` or `DOCKER_TOKEN`

`DOCKER_TOKEN` is recommended for production-style usage.

## Helper Scripts

Scripts are provided for local convenience:

```bash
./scripts/terraform-init.sh
./scripts/start.sh
./scripts/port-forward.sh app
./scripts/port-forward.sh argocd
./scripts/port-forward.sh grafana
./scripts/cleanup.sh
```

## Screenshots

Add screenshots here after a local run:

- myRetail app via `http://myretail.local`
- Argo CD application sync view
- Grafana myRetail dashboard
- GitHub Actions workflow run

## Troubleshooting

If `myretail.local` does not load, confirm the host entry exists and ingress-nginx has an external address:

```bash
kubectl -n ingress-nginx get svc
kubectl -n retail get ingress
```

If Argo CD does not sync, check the application and repo path:

```bash
kubectl -n argocd describe application myretail
```

If Prometheus does not scrape the app, confirm the ServiceMonitor exists:

```bash
kubectl -n retail get servicemonitor
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

If Docker image pulls fail, verify the image repository and tag in `helm/myretail/values.yaml`.

## Future Improvements

- Add cert-manager and TLS for a real domain
- Add external secrets for production credentials
- Add image vulnerability scanning in CI
- Add Kubernetes policy checks with Conftest or Kyverno
- Split Terraform into reusable modules when targeting a cloud cluster
