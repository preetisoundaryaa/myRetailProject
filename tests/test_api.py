from app.main import build_app


def test_health_endpoint_returns_ok():
    app = build_app()
    app.testing = True
    client = app.test_client()

    response = client.get('/health')
    body = response.get_json()

    assert response.status_code == 200
    assert body['status'] == 'ok'


def test_purchase_requires_item_id():
    app = build_app()
    app.testing = True
    client = app.test_client()

    response = client.post('/api/purchase', json={"qty": 1})
    assert response.status_code == 400
    assert response.get_json()['error'] == 'item_id required'


def test_purchase_rejects_bad_qty_type():
    app = build_app()
    app.testing = True
    client = app.test_client()

    response = client.post('/api/purchase', json={"item_id": "A1", "qty": "abc"})
    assert response.status_code == 400
    assert response.get_json()['error'] == 'qty must be a positive integer'
