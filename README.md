# Retail Shelf Manager

Small Flask app for shelf item management. It shows items, lets you buy one, and updates stock in memory.

I built this as an interview project to show backend + frontend + Azure deployment basics without adding extra moving parts.

## Stack

- Python 3.11
- Flask backend
- Vanilla JS frontend
- Docker
- Azure App Service + Azure Container Registry
- Azure Pipelines + optional GitHub Actions CI

## Features

- `GET /api/items` list shelf items
- `POST /api/purchase` buy item (`item_id`, `qty`, qty must be positive int)
- `POST /api/restock` add stock (no auth in demo)
- `GET /health` basic health check
- Basic app logging

## Run locally

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m app.main
```

Open http://localhost:8000

### With Docker Compose

```bash
docker compose up --build
```

## Tests

```bash
pytest -q
```

The tests are intentionally basic; they focus on the inventory logic and a couple of endpoints I cared about first.

## Azure deployment

### 1) Provision infrastructure

```bash
az group create --name rg-retail-shelf --location eastus
az deployment group create \
  --resource-group rg-retail-shelf \
  --template-file azure/bicep/main.bicep \
  --parameters appName=retail-shelf-webapp
```

This creates:
- Linux App Service Plan
- Web App for containers
- Azure Container Registry
- Storage account

### 2) Push image manually (one-time sanity check)

```bash
az acr login --name <acrName>
docker build -t <acrLoginServer>/retail-shelf-app:latest .
docker push <acrLoginServer>/retail-shelf-app:latest
```

### 3) Wire up pipeline service connections

In Azure DevOps project settings, create:
- `ACR-Service-Connection`
- `Azure-Subscription-Service-Connection`

Then the `azure/azure-pipelines.yml` pipeline can build and deploy on `main` pushes.

App Service settings can be applied from `azure/appsettings.json` if you want to script config updates.

## Config

Copy `.env.example` to `.env` for local overrides.

Main values:
- `APP_ENV=dev|prod`
- `DEBUG=true|false`
- `LOG_LEVEL=DEBUG|INFO|WARNING`

## Suggested git history

This is how I would have split commits while building it for real:

1. `init flask app skeleton and health endpoint`
2. `add in-memory shelf store and purchase flow`
3. `hook up plain js frontend for item listing + buy action`
4. `add tests for store math and api validation`
5. `containerize app and add compose for local dev`
6. `add azure bicep infra + devops pipeline`
7. `add github actions ci and clean up readme`

## Notes

- Inventory is in-memory so restarts reset stock.
- TODO: move store to Cosmos DB or Postgres if this becomes a real shared app.
- The restock route should require auth in any real environment.
