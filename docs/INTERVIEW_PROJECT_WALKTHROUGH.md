# Retail Shelf App – Interview Walkthrough

This document explains the project file-by-file as if I am walking an interviewer through the repo in a screen-share.

Companion plain-text files in this repo:
- `docs/INTERVIEW_PROJECT_WALKTHROUGH.md`
- `docs/INTERVIEW_PROJECT_WALKTHROUGH.txt`

## 1) Runtime request flow (real-time file access order)

If the app is running through `python -m app.main` or `gunicorn app.main:app`, this is the practical order files are touched:

1. **`app/main.py`** imports and builds the Flask app, registers routes, and starts server logic (`app = build_app()`).
2. **`app/config.py`** is imported by `main.py` to load env-based settings (`APP_ENV`, `LOG_LEVEL`, `DEBUG`).
3. **`app/store.py`** is imported by `main.py` to load the shared in-memory `store` singleton.
4. **HTTP request: `GET /`** returns **`static/index.html`**.
5. Browser then fetches **`static/styles.css`** and **`static/app.js`**.
6. Frontend script (`static/app.js`) calls **`GET /api/items`**.
7. API route in `app/main.py` calls `store.list_items()` from `app/store.py` and returns JSON.
8. On buy action, frontend calls **`POST /api/purchase`**, backend decrements qty in `app/store.py`, logs event, and returns the result.
9. Health probes call **`GET /health`** (used by platform checks and manual monitoring).

For local container runs, the runtime is started by **`Dockerfile`** (`gunicorn`) or **`docker-compose.yml`** (development command).

---

## 2) File-by-file explanation with code line references

### Root and environment files

#### `.env.example`
- Template for runtime env values and Azure deployment variables.
- Important for separating local and deployed config (`APP_ENV`, `LOG_LEVEL`).
- References: `.env.example:L1-L8`.

#### `.gitignore`
- Prevents committing virtualenvs, caches, IDE artifacts, and local `.env` files.
- Keeps repository clean and avoids secret leakage.
- References: `.gitignore:L1-L29`.

#### `requirements.txt`
- Pins Python dependencies (`Flask`, `gunicorn`, `pytest`) for reproducible installs.
- References: `requirements.txt:L1-L3`.

#### `README.md`
- Operational guide covering local setup, tests, Azure deployment commands, and suggested git history.
- Useful for onboarding and interview context because it narrates project evolution.
- References: `README.md:L1-L110`.

#### `Dockerfile`
- Builds production image from `python:3.11-slim`.
- Installs requirements, copies project, exposes port `8000`, and runs gunicorn.
- References: `Dockerfile:L1-L15`.

#### `docker-compose.yml`
- Local-dev runtime wrapper.
- Builds from current source, maps `8000:8000`, mounts code volume for live edits, starts with `python -m app.main`.
- References: `docker-compose.yml:L1-L15`.

#### `.gitkeep`
- Empty placeholder file to keep initial repo tracking intact.
- References: `.gitkeep:L1`.

---

### Application backend (`app/`)

#### `app/__init__.py`
- Package marker with minimal content and no side effects.
- Avoids forcing Flask imports just from package import.
- References: `app/__init__.py:L1`.

#### `app/config.py`
- Central settings loader using environment variables.
- Defines `settings` object consumed by API startup and runtime logging.
- References: `app/config.py:L1-L14`.

#### `app/store.py`
- In-memory inventory model and business logic.
- Uses thread lock to avoid race conditions when buying/restocking concurrently.
- `list_items()` deep-copies each item to avoid caller mutation.
- `buy_item()` validates quantity, checks stock, decrements, and returns total.
- `restock_item()` validates input and increments quantity.
- Exposes singleton `store` used by API routes.
- References: `app/store.py:L1-L53`.

#### `app/main.py`
- Flask app entrypoint and route registration.
- `_parse_positive_int` handles numeric input validation from JSON payloads.
- Routes:
  - `/` serves frontend page.
  - `/api/items` returns item list.
  - `/api/purchase` validates inputs, performs purchase, logs outcomes.
  - `/api/restock` validates inputs and restocks inventory.
  - `/health` returns service status and environment.
- Configures logging format and level from env.
- References: `app/main.py:L1-L88`.

---

### Frontend (`static/`)

#### `static/index.html`
- Basic single-page layout: title, message area, and shelf container.
- Loads CSS and JS in a simple, interview-friendly structure.
- References: `static/index.html:L1-L18`.

#### `static/styles.css`
- Minimal styling for cards, layout grid, and button states.
- Keeps UI readable while staying lightweight.
- References: `static/styles.css:L1-L55`.

#### `static/app.js`
- Handles all browser-side behavior:
  - fetch item list (`fetchItems`)
  - display messages (`setMessage`)
  - purchase call (`buyItem`)
  - card rendering (`itemCard`)
  - initial + refresh rendering (`renderShelf`)
- Frontend intentionally plain JS for lower debugging overhead during interviews.
- References: `static/app.js:L1-L61`.

---

### Tests (`tests/`)

#### `tests/conftest.py`
- Prepends repo root to `sys.path` so tests can import `app.*` without packaging install.
- References: `tests/conftest.py:L1-L6`.

#### `tests/test_store.py`
- Verifies inventory math and stock-failure path:
  - purchase decreases quantity and returns expected total
  - out-of-stock request returns failure
- References: `tests/test_store.py:L1-L20`.

#### `tests/test_api.py`
- Verifies API guardrails and health endpoint:
  - `/health` returns 200 + `status=ok`
  - `/api/purchase` rejects missing `item_id`
  - `/api/purchase` rejects invalid qty type
- References: `tests/test_api.py:L1-L33`.

---

### CI/CD and Azure infra

#### `.github/workflows/ci.yml`
- Optional GitHub Actions CI path.
- Runs on push/PR; installs deps and executes `pytest`.
- References: `.github/workflows/ci.yml:L1-L21`.

#### `azure/azure-pipelines.yml`
- Azure DevOps pipeline with three stages:
  1. **Test** (install deps + run tests)
  2. **BuildAndPush** (Docker build + push to ACR)
  3. **Deploy** (deploy container image to Azure App Service)
- Uses variables for app name and registry for easier environment reuse.
- References: `azure/azure-pipelines.yml:L1-L62`.

#### `azure/appsettings.json`
- App Service environment settings (`APP_ENV`, `LOG_LEVEL`, `WEBSITES_PORT`, `DATA_BACKEND`).
- Helps keep deployment config explicit and scriptable.
- References: `azure/appsettings.json:L1-L22`.

#### `azure/bicep/main.bicep`
- Infrastructure as Code for Azure resources:
  - Linux App Service plan
  - Storage account
  - Azure Container Registry
  - Linux container Web App with settings
- Outputs default web app URL and ACR login server.
- References: `azure/bicep/main.bicep:L1-L67`.

---

## 3) What I would highlight verbally in an interview

1. **Separation of concerns:** API routes in `main.py`, business logic in `store.py`, UI in `static/`.
2. **Operational readiness:** health endpoint + logs + env-based config + Docker packaging.
3. **DevOps maturity:** both GitHub Actions and Azure Pipelines, plus Bicep provisioning.
4. **Known tradeoff:** inventory is intentionally in-memory for demo simplicity; persistence is next step.

## 4) Suggested “next iteration” improvements

- Add auth/role checks for `/api/restock`.
- Replace in-memory store with database persistence.
- Add integration test for end-to-end purchase flow.
- Add pipeline gate for linting/security scan.

** e-commerce application components:** 

**Compute:** VMs for legacy services, App Services for web front-end, Azure Functions for event processing
**Containers:** AKS clusters hosting microservices, Azure Container Instances for batch jobs
**Data stores:** Azure SQL Database for transactions, Cosmos DB for product catalog, Redis Cache for sessions
**Messaging:** Event Hubs for event streaming, Service Bus for reliable messaging, Event Grid for event routing
**Storage:** Blob Storage for images and documents, Queue Storage for background tasks
**Security:** Key Vault for secrets and certificates
**Networking:** Application Gateway for load balancing, Front Door for global distribution
