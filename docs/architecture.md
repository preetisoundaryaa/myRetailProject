# Architecture Overview

## End-to-end request and monitoring flow

```text
User
  |
  v
Kubernetes Service (retail-app:80)
  |
  v
Retail App Pods (Flask on 0.0.0.0:8000)
  |
  |-- /health (liveness/readiness)
  |-- /metrics (Prometheus exporter)
  v
Prometheus (scrapes retail-app metrics via Kubernetes service discovery)
  |
  v
Grafana (uses Prometheus datasource for dashboards)
```

## Components

- **Retail App (Flask)**
  - Exposes APIs for items, purchase, restock, and health.
  - Exposes metrics via `prometheus_flask_exporter` and custom counters.
- **Prometheus**
  - Discovers scrape targets from Kubernetes endpoints.
  - Scrapes only `retail-app` endpoints.
  - Uses `prometheus-sa` with `ClusterRole` + `ClusterRoleBinding` for discovery.
- **Grafana**
  - Uses a pre-provisioned Prometheus datasource.
  - Ready for dashboard import and alert visualization.
- **Argo CD**
  - Deploys and continuously reconciles `helm/retail-app` from Git.
  - Auto-sync, prune, and self-heal are enabled.

## GitOps lifecycle

1. Developer updates chart/app configuration in Git.
2. Changes are merged to `main`.
3. Argo CD detects drift from `main` and applies updates.
4. Kubernetes state converges to Git-defined desired state.
5. Prometheus/Grafana continuously observe runtime behavior.
