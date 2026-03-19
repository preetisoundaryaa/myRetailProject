FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

ENV APP_ENV=prod
ENV LOG_LEVEL=INFO

# Old CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app.main:app"]
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT:-80} app.main:app --workers 4 --threads 2"]

# --- HEALTHCHECK using Python ---
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD python3 -c "import sys, requests; \
    sys.exit(0) if requests.get('http://localhost:8000/health').status_code == 200 else sys.exit(1)"
