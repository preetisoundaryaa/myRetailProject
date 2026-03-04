import logging
from flask import Flask, jsonify, request, send_from_directory

from app.config import settings
from app.store import store


def _parse_positive_int(value):
    try:
        parsed = int(value)
    except (TypeError, ValueError):
        return None
    return parsed if parsed > 0 else None


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
            return jsonify({"ok": False, "error": "item_id required"}), 400
        if qty is None:
            return jsonify({"ok": False, "error": "qty must be a positive integer"}), 400

        result = store.buy_item(item_id=item_id, amount=qty)
        if not result["ok"]:
            status = 404 if result["error"] == "item not found" else 400
            logger.info("purchase failed item=%s reason=%s", item_id, result["error"])
            return jsonify(result), status

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
            return jsonify({"ok": False, "error": "item_id required"}), 400
        if amount is None:
            return jsonify({"ok": False, "error": "qty must be a positive integer"}), 400

        # TODO: lock this down with auth if someone actually deploys this.
        result = store.restock_item(item_id=item_id, amount=amount)
        if not result["ok"]:
            status = 404 if result["error"] == "item not found" else 400
            return jsonify(result), status
        return jsonify(result)

    @app.get("/health")
    def health():
        return jsonify({"status": "ok", "env": settings.ENV})

    return app


app = build_app()


if __name__ == "__main__":
    # this works for local dev, gunicorn runs it in prod container
    app.run(host="0.0.0.0", port=8000, debug=settings.DEBUG)
