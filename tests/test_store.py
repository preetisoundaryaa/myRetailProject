from app.store import InventoryStore


def test_buy_item_reduces_quantity_and_returns_total():
    store = InventoryStore()

    before_qty = [i for i in store.list_items() if i["id"] == "A1"][0]["qty"]
    result = store.buy_item("A1", 2)

    assert result["ok"] is True
    assert result["total"] == 4.98
    after_qty = [i for i in store.list_items() if i["id"] == "A1"][0]["qty"]
    assert before_qty - after_qty == 2


def test_buy_item_fails_when_stock_is_too_low():
    store = InventoryStore()
    result = store.buy_item("B4", 100)
    assert result["ok"] is False
    assert result["error"] == "out of stock"
