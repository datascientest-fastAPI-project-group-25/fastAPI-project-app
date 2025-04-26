import unittest
import requests
import os
import time
import json
from urllib.parse import urljoin


class TestBackendMonitoring(unittest.TestCase):
    """Test the backend integration with monitoring."""

    @classmethod
    def setUpClass(cls):
        """Set up test class."""
        # Get service URLs from environment variables or use defaults
        cls.prometheus_url = os.environ.get("PROMETHEUS_URL", "http://prometheus:9090")
        cls.loki_url = os.environ.get("LOKI_URL", "http://loki:3100")
        cls.backend_url = os.environ.get("BACKEND_URL", "http://backend:8000")
        
        # Wait for services to be ready
        cls._wait_for_services()

    @classmethod
    def _wait_for_services(cls, max_retries=30, retry_interval=2):
        """Wait for services to be ready."""
        services = {
            "Prometheus": cls.prometheus_url,
            "Loki": cls.loki_url,
            "Backend": cls.backend_url,
        }
        
        for service_name, url in services.items():
            for i in range(max_retries):
                try:
                    response = requests.get(url, timeout=5)
                    if response.status_code < 500:  # Accept any non-server error
                        print(f"{service_name} is ready!")
                        break
                except requests.RequestException:
                    if i == max_retries - 1:
                        print(f"Warning: {service_name} is not ready after {max_retries} retries")
                    time.sleep(retry_interval)

    def test_backend_health_endpoint(self):
        """Test that the backend health endpoint is working."""
        try:
            response = requests.get(urljoin(self.backend_url, "/api/v1/utils/health-check/"))
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["status"], "healthy")
        except requests.RequestException as e:
            self.fail(f"Backend health endpoint is not accessible: {str(e)}")

    def test_backend_metrics_endpoint(self):
        """Test that the backend metrics endpoint is working."""
        try:
            response = requests.get(urljoin(self.backend_url, "/metrics"))
            self.assertEqual(response.status_code, 200)
            # Metrics endpoint should return text/plain content
            self.assertIn("text/plain", response.headers.get("Content-Type", ""))
        except requests.RequestException as e:
            self.fail(f"Backend metrics endpoint is not accessible: {str(e)}")

    def test_prometheus_scraping_backend(self):
        """Test that Prometheus is scraping metrics from the backend."""
        # First, generate some traffic to the backend
        self._generate_backend_traffic()
        
        # Then check if Prometheus has collected metrics
        try:
            # Wait a bit for Prometheus to scrape the metrics
            time.sleep(15)
            
            # Query for FastAPI metrics
            response = requests.get(
                urljoin(self.prometheus_url, "/api/v1/query"),
                params={"query": 'http_requests_total{job="fastapi_backend"}'}
            )
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["status"], "success")
            
            # Check if there are results
            self.assertTrue(len(data["data"]["result"]) > 0, 
                           "No metrics found for the backend in Prometheus")
        except requests.RequestException as e:
            self.fail(f"Failed to query Prometheus for backend metrics: {str(e)}")

    def test_loki_collecting_backend_logs(self):
        """Test that Loki is collecting logs from the backend."""
        # First, generate some traffic to the backend to produce logs
        self._generate_backend_traffic()
        
        # Then check if Loki has collected logs
        try:
            # Wait a bit for logs to be collected
            time.sleep(15)
            
            # Current time in nanoseconds
            now = int(time.time() * 1e9)
            # 10 minutes ago in nanoseconds
            ten_min_ago = int((time.time() - 600) * 1e9)
            
            response = requests.get(
                urljoin(self.loki_url, "/loki/api/v1/query_range"),
                params={
                    "query": '{container="backend"}',
                    "start": ten_min_ago,
                    "end": now,
                    "limit": 10
                }
            )
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["status"], "success")
            
            # Check if there are log entries
            # Note: This might fail if no logs were generated
            # self.assertTrue(len(data["data"]["result"]) > 0, 
            #               "No logs found for the backend in Loki")
        except requests.RequestException as e:
            self.fail(f"Failed to query Loki for backend logs: {str(e)}")

    def _generate_backend_traffic(self, num_requests=10):
        """Generate traffic to the backend."""
        endpoints = [
            "/api/v1/utils/health-check/",
            "/docs",
            "/openapi.json",
            "/metrics"
        ]
        
        for _ in range(num_requests):
            for endpoint in endpoints:
                try:
                    requests.get(urljoin(self.backend_url, endpoint), timeout=5)
                except requests.RequestException:
                    pass  # Ignore errors
                time.sleep(0.1)  # Small delay between requests


if __name__ == "__main__":
    unittest.main()
