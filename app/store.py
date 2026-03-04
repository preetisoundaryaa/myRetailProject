from copy import deepcopy
from threading import Lock


class InventoryStore:
    def __init__(self):
        self._lock = Lock()
        self._items = {
            "A1": {"id": "A1", "name": "Green Tea", "price": 2.49, "qty": 8},
            "A2": {"id": "A2", "name": "Chocolate Bar", "price": 1.29, "qty": 15},
            "B4": {"id": "B4", "name": "Trail Mix", "price": 3.99, "qty": 4},
            "C2": {"id": "C2", "name": "Sparkling Water", "price": 1.79, "qty": 20},
        }

    def list_items(self):
        # deepcopy avoids callers changing shared state by accident.
        items = [deepcopy(item) for item in self._items.values()]
        return sorted(items, key=lambda x: x["id"])

    def buy_item(self, item_id: str, amount: int = 1):
        if amount <= 0:
            return {"ok": False, "error": "quantity must be positive"}

        with self._lock:
            item = self._items.get(item_id)
            if not item:
                return {"ok": False, "error": "item not found"}

            if item["qty"] < amount:
                return {"ok": False, "error": "out of stock"}

            item["qty"] -= amount
            total = round(item["price"] * amount, 2)
            return {
                "ok": True,
                "item": deepcopy(item),
                "purchased": amount,
                "total": total,
            }

    def restock_item(self, item_id: str, amount: int):
        with self._lock:
            item = self._items.get(item_id)
            if not item:
                return {"ok": False, "error": "item not found"}
            if amount <= 0:
                return {"ok": False, "error": "restock amount must be positive"}

            item["qty"] += amount
            return {"ok": True, "item": deepcopy(item)}


store = InventoryStore()
