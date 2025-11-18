import json
import pytest
from unittest.mock import patch, MagicMock
import azure.functions as func
from backend.http_trigger_app import function_app as main


@pytest.fixture(autouse=True)
def mock_env_vars(monkeypatch, request):
    """Automatically set environment variables unless test disables it."""
    if "no_env" in request.keywords:
        return  # skip env setup for this test

    monkeypatch.setenv("COSMOS_DB_URL", "mock_url")
    monkeypatch.setenv("COSMOS_DB_KEY", "mock_key")
    monkeypatch.setenv("COSMOS_DB_NAME", "mock_db")
    monkeypatch.setenv("COSMOS_DB_CONTAINER", "mock_container")


@pytest.fixture
def mock_req_get():
    """Mock GET request."""
    return func.HttpRequest(
        method='GET',
        url='/api/http_trigger',
        body=None,
    )


@pytest.fixture
def mock_req_post():
    """Mock POST request."""
    return func.HttpRequest(
        method='POST',
        url='/api/http_trigger',
        body=None,
    )


def make_mock_container(count=1):
    """Create a mocked Cosmos container."""
    mock_container = MagicMock()
    mock_container.read_item.return_value = {"id": "1", "count": count}
    return mock_container


@patch("backend.function_app.CosmosClient")
def test_get_request_returns_count(mock_cosmos, mock_req_get):
    """Test GET request returns count from mocked Cosmos DB."""
    mock_client = MagicMock()
    mock_container = make_mock_container(5)

    # Mock Cosmos DB structure
    mock_db = MagicMock()
    mock_db.get_container_client.return_value = mock_container
    mock_client.get_database_client.return_value = mock_db
    mock_cosmos.return_value = mock_client

    # Run function
    response = main.http_trigger(mock_req_get)

    # Validate
    assert response.status_code == 200
    data = json.loads(response.get_body())
    assert data["count"] == 5


@patch("backend.function_app.CosmosClient")
def test_post_request_increments_count(mock_cosmos, mock_req_post):
    """Test POST request increments visitor count."""
    mock_client = MagicMock()
    mock_container = make_mock_container(2)

    mock_db = MagicMock()
    mock_db.get_container_client.return_value = mock_container
    mock_client.get_database_client.return_value = mock_db
    mock_cosmos.return_value = mock_client

    response = main.http_trigger(mock_req_post)

    # Assertions
    assert response.status_code == 200
    data = json.loads(response.get_body())
    assert data["new_count"] == 3
    mock_container.replace_item.assert_called_once()


@pytest.mark.no_env
@patch("backend.function_app.CosmosClient")
def test_missing_env_vars_returns_500(mock_cosmos, mock_req_get, monkeypatch):
    """Test when environment variables are missing."""
    # All env vars are skipped because of @pytest.mark.no_env
    response = main.http_trigger(mock_req_get)

    assert response.status_code == 500
    data = json.loads(response.get_body())
    assert "Missing Cosmos DB URL or key" in data["error"]

