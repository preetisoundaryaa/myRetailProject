FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies first to maximize Docker layer caching.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Create a non-root user and group.
RUN groupadd --system app && useradd --system --gid app --create-home app

# Copy application source.
COPY . .

# Ensure the non-root user can read app files.
RUN chown -R app:app /app

USER app

EXPOSE 8000

ENV APP_ENV=prod \
    LOG_LEVEL=INFO

# Gunicorn serves Flask app with 4 workers and 2 threads on port 8000.
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "2", "app.main:app"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request,sys;\
resp=urllib.request.urlopen('http://localhost:8000/health', timeout=3);\
sys.exit(0 if resp.getcode()==200 else 1)"
