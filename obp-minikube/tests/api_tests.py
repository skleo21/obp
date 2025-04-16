# tests/api_tests.py
import requests
import pytest
import os

# Configure the base URL for testing
BASE_URL = os.getenv("API_URL", "http://localhost:8080")

class TestOpenBankingAPI:
    
    def test_root_endpoint(self):
        """Test that the root API endpoint is functioning"""
        response = requests.get(f"{BASE_URL}/")
        assert response.status_code == 200
    
    def test_health_endpoint(self):
        """Test that health endpoint returns OK status"""
        response = requests.get(f"{BASE_URL}/health")
        assert response.status_code == 200
        assert "status" in response.json()
        assert response.json()["status"] == "OK"
    
    @pytest.mark.parametrize("api_version", ["v4.0.0", "v3.1.0"])
    def test_api_version_support(self, api_version):
        """Test that different API versions are supported"""
        response = requests.get(f"{BASE_URL}/obp/{api_version}/root")
        assert response.status_code == 200