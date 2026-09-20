from application import app


def test_home():
    client = app.test_client()

    response = client.get("/")

    assert response.status_code == 200
    assert response.content_type.startswith("text/html")
    assert b"10Alytics" in response.data


def test_health():
    client = app.test_client()

    response = client.get("/health")

    assert response.status_code == 200

    data = response.get_json()

    assert data["status"] == "healthy"


def test_readiness():
    client = app.test_client()

    response = client.get("/health/ready")

    assert response.status_code == 200

    data = response.get_json()

    assert data["status"] == "ready"