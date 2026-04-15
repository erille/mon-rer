from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_root_redirects_without_station_param() -> None:
    response = client.get("/", follow_redirects=False)
    assert response.status_code == 302
    assert response.headers["location"].startswith("/?s=")


def test_root_renders_selected_station() -> None:
    response = client.get("/?s=EVC")
    assert response.status_code == 200
    assert "IDF Trains by Ketah" in response.text
    assert "Favorite stations" in response.text
    assert "Template:" in response.text
    assert "theme-moderne" in response.text
    assert "Evry" in response.text or "Évry" in response.text


def test_root_renders_standard_theme_when_requested() -> None:
    response = client.get("/?s=EVC&theme=standard")
    assert response.status_code == 200
    assert "theme-standard" in response.text
    assert "standard-board" in response.text
    assert "Template:" in response.text


def test_autocomplete_returns_station_matches() -> None:
    response = client.get("/autocomp", params={"s": "evry"})
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert any("Evry" in item["name"] or "Évry" in item["name"] for item in data)


def test_json_requires_configured_token() -> None:
    response = client.get("/json", params={"s": "EVC"})
    assert response.status_code == 503
    assert response.json()["error"] == "IDFM_API_TOKEN is not configured."


def test_health_reports_station_count() -> None:
    response = client.get("/health")
    assert response.status_code in {200, 503}
    payload = response.json()
    assert payload["station_count"] == 476
