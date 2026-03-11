import logging
from threading import Lock

from flask import Flask, Response, jsonify, request, send_from_directory

from app.config import settings
from app.store import store

_metrics_lock = Lock()
_purchase_success_total = 0
_purchase_failed_total = 0
_restock_success_total = 0
_restock_failed_total = 0


def _parse_positive_int(value):
    try:
        parsed = int(value)
    except (TypeError, ValueError):
        return None
    return parsed if parsed > 0 else None


def _inc_metric(name: str):
    global _purchase_success_total, _purchase_failed_total, _restock_success_total, _restock_failed_total
    with _metrics_lock:
        if name == "purchase_success":
            _purchase_success_total += 1
        elif name == "purchase_failed":
            _purchase_failed_total += 1
        elif name == "restock_success":
            _restock_success_total += 1
        elif name == "restock_failed":
            _restock_failed_total += 1


def _prometheus_metrics_payload() -> str:
    with _metrics_lock:
        purchase_success = _purchase_success_total
        purchase_failed = _purchase_failed_total
        restock_success = _restock_success_total
        restock_failed = _restock_failed_total

    lines = [
        "# HELP retail_purchase_total Total purchase attempts grouped by outcome",
        "# TYPE retail_purchase_total counter",
        f'retail_purchase_total{{status="success"}} {purchase_success}',
        f'retail_purchase_total{{status="failed"}} {purchase_failed}',
        "# HELP retail_restock_total Total restock attempts grouped by outcome",
        "# TYPE retail_restock_total counter",
        f'retail_restock_total{{status="success"}} {restock_success}',
        f'retail_restock_total{{status="failed"}} {restock_failed}',
    ]
    return "\n".join(lines) + "\n"


def build_app() -> Flask:
    app = Flask(__name__, static_folder="../static", static_url_path="")

    logging.basicConfig(
        level=getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO),
        format="%(asctime)s %(levelname)s %(name)s - %(message)s",
    )
    logger = logging.getLogger("retail-app")

    @app.get("/")
    def index():
        return send_from_directory(app.static_folder, "index.html")

    @app.get("/api/items")
    def list_items():
        return jsonify({"items": store.list_items()})

    @app.post("/api/purchase")
    def purchase_item():
        payload = request.get_json(silent=True) or {}
        item_id = payload.get("item_id")
        qty = _parse_positive_int(payload.get("qty", 1))

        if not item_id:
            _inc_metric("purchase_failed")
            return jsonify({"ok": False, "error": "item_id required"}), 400
        if qty is None:
            _inc_metric("purchase_failed")
            return jsonify({"ok": False, "error": "qty must be a positive integer"}), 400

        result = store.buy_item(item_id=item_id, amount=qty)
        if not result["ok"]:
            _inc_metric("purchase_failed")
            status = 404 if result["error"] == "item not found" else 400
            logger.info("purchase failed item=%s reason=%s", item_id, result["error"])
            return jsonify(result), status

        _inc_metric("purchase_success")
        logger.info(
            "purchase completed item=%s qty=%s total=%s",
            item_id,
            result["purchased"],
            result["total"],
        )
        return jsonify(result)

    @app.post("/api/restock")
    def restock_item():
        payload = request.get_json(silent=True) or {}
        item_id = payload.get("item_id")
        amount = _parse_positive_int(payload.get("qty", 0))

        if not item_id:
            _inc_metric("restock_failed")
            return jsonify({"ok": False, "error": "item_id required"}), 400
        if amount is None:
            _inc_metric("restock_failed")
            return jsonify({"ok": False, "error": "qty must be a positive integer"}), 400

        # TODO: lock this down with auth if someone actually deploys this.
        result = store.restock_item(item_id=item_id, amount=amount)
        if not result["ok"]:
            _inc_metric("restock_failed")
            status = 404 if result["error"] == "item not found" else 400
            return jsonify(result), status

        _inc_metric("restock_success")
        return jsonify(result)

    @app.get("/health")
    def health():
        return jsonify({"status": "ok", "env": settings.ENV})

    @app.get("/metrics")
    def metrics():
        return Response(_prometheus_metrics_payload(), mimetype="text/plain; version=0.0.4")

    return app


app = build_app()


if __name__ == "__main__":
    # this works for local dev, gunicorn runs it in prod container
    app.run(host="0.0.0.0", port=8000, debug=settings.DEBUG)
