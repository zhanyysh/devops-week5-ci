"""Unit tests for the Flask app, run by the CI `test` job."""

import os

import pytest

from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    return app.test_client()


def test_index_returns_message(client):
    resp = client.get("/")
    assert resp.status_code == 200
    assert resp.get_json() == {"message": "Hello from a multi-stage Docker image!"}


def test_healthz_returns_ok(client):
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_healthz_rejects_post(client):
    assert client.post("/healthz").status_code == 405


def test_unknown_route_is_404(client):
    assert client.get("/does-not-exist").status_code == 404


# os.getuid() only exists on Linux/macOS (the CI runners), not on Windows.
@pytest.mark.skipif(not hasattr(os, "getuid"), reason="needs os.getuid()")
def test_info_reports_runtime(client):
    resp = client.get("/info")
    assert resp.status_code == 200
    data = resp.get_json()
    assert set(data) == {"hostname", "python", "uid"}
    assert data["uid"] == os.getuid()
