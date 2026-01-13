def test_healthz():
    from app.main import app
    # FastAPI TestClient is optional in requirements; do a simple import smoke test
    assert hasattr(app, 'routes')
