# myRetailProject

Production-ready retail inventory application with a DevOps-first setup:
- Flask API + static frontend
- Dockerized runtime
- Kubernetes deployment via Helm
- Prometheus + Grafana monitoring
- Argo CD GitOps delivery

## Repository structure

```text
myRetailProject/
├── app/                     # Flask app
├── helm/
│   └── retail-app/          # Helm chart for app + monitoring stack
├── argocd/
│   └── application.yaml     # Argo CD application manifest
├── docs/
│   └── architecture.md
├── Dockerfile
└── README.md
```

## Architecture (text diagram)

```text
User -> retail-app Service -> retail-app Pod(s)
                               |\
                               | \-> /health
                               |
                               \--> /metrics -> Prometheus -> Grafana dashboards
```

See `docs/architecture.md` for the full flow.

## Application endpoints

- `GET /api/items`
- `POST /api/purchase`
- `POST /api/restock`
- `GET /health`
- `GET /metrics` (provided by Prometheus Flask exporter)

## Local run

### 1) Python

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m app.main
```

Open http://localhost:8000

### 2) Docker build and run

```bash
docker build -t retail-app:local .
docker run --rm -p 8000:8000 retail-app:local
```

## Helm deployment

Install into current Kubernetes context:

```bash
helm install retail-release ./helm/retail-app
```

Optional custom values:

```bash
helm install retail-release ./helm/retail-app \
  --set image.repository=preetisoundaryaa/myretail-app \
  --set image.tag=<git-commit-sha> \
  --set replicaCount=3 \
  --set service.type=LoadBalancer
```

### Ingress for local development (Docker Desktop Kubernetes)

1. Install NGINX Ingress Controller (one-time per cluster):

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

2. Add a local host entry:

```text
127.0.0.1 myretail.local
```

3. Access the app:

```text
http://myretail.local
```

Notes:
- The chart enables an `Ingress` using `ingressClassName: nginx` and routes `/` to the app service.
- TLS is intentionally not configured here (demo/local use only).
- In production, add TLS using `cert-manager` with an issuer/cluster-issuer and Ingress TLS settings.

## CI/CD Pipeline

This repository uses a GitOps CI/CD flow with GitHub Actions and Argo CD:

1. Code is pushed to `main`.
2. GitHub Actions runs tests, builds the Docker image, and tags it with the commit SHA (`github.sha`).
3. The workflow pushes `preetisoundaryaa/myretail-app:<commit-sha>` to Docker Hub.
4. The workflow updates `helm/retail-app/values.yaml` with that exact SHA tag and commits the change back to the repository.
5. Argo CD detects the `values.yaml` change in Git and automatically syncs the cluster.

Flow diagram:

```text
Code push -> GitHub Actions -> Build & Push Image -> Update Helm -> Argo CD Sync -> Deploy
```

This removes manual Docker image tagging and manual Helm image tag updates from the deployment workflow.

## Argo CD GitOps deployment

1. Apply Argo CD application:

```bash
kubectl apply -f argocd/application.yaml
```

2. Argo CD sync behavior:
- Uses chart path: `helm/retail-app`
- `automated` sync enabled
- `prune: true`
- `selfHeal: true`

## Monitoring details

### Prometheus

- Runs in-cluster from Helm chart.
- Scrapes `retail-app` using Kubernetes endpoint discovery.
- Uses `prometheus-sa` + `ClusterRole` + `ClusterRoleBinding` for pod/service discovery.

### Grafana

- Runs in-cluster from Helm chart.
- Starts with Prometheus datasource provisioned.
- Default credentials are configurable in Helm values.

## GitOps workflow summary

1. Edit app/chart in Git.
2. Push changes and merge to `main`.
3. Argo CD detects repository delta.
4. Argo CD syncs cluster to desired state.
5. Prometheus and Grafana validate service health/metrics.

## Notes

- Flask service binds to `0.0.0.0:8000`.
- Production container uses gunicorn on port `8000`.
- Inventory store is in-memory (stateless demo behavior).
