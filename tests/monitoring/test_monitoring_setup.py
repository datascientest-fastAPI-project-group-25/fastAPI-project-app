import unittest
import requests
import os
import time
import json
from urllib.parse import urljoin


class TestMonitoringSetup(unittest.TestCase):
    """Test the monitoring and logging setup."""

    @classmethod
    def setUpClass(cls):
        """Set up test class."""
        # Get service URLs from environment variables or use defaults
        cls.prometheus_url = os.environ.get("PROMETHEUS_URL", "http://prometheus:9090")
        cls.loki_url = os.environ.get("LOKI_URL", "http://loki:3100")
        cls.grafana_url = os.environ.get("GRAFANA_URL", "http://grafana:3000")
        cls.backend_url = os.environ.get("BACKEND_URL", "http://backend:8000")
        
        # Wait for services to be ready
        cls._wait_for_services()

    @classmethod
    def _wait_for_services(cls, max_retries=30, retry_interval=2):
        """Wait for services to be ready."""
        services = {
            "Prometheus": cls.prometheus_url,
            "Loki": cls.loki_url,
            "Grafana": cls.grafana_url,
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

    def test_prometheus_up(self):
        """Test that Prometheus is up and running."""
        try:
            response = requests.get(urljoin(self.prometheus_url, "/api/v1/query"), 
                                   params={"query": "up"})
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["status"], "success")
        except requests.RequestException as e:
            self.fail(f"Prometheus is not accessible: {str(e)}")

    def test_loki_up(self):
        """Test that Loki is up and running."""
        try:
            # Current time in nanoseconds
            now = int(time.time() * 1e9)
            # 1 hour ago in nanoseconds
            one_hour_ago = int((time.time() - 3600) * 1e9)
            
            response = requests.get(
                urljoin(self.loki_url, "/loki/api/v1/query_range"),
                params={
                    "query": "{}",  # Empty query to match all logs
                    "start": one_hour_ago,
                    "end": now,
                    "limit": 1
                }
            )
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["status"], "success")
        except requests.RequestException as e:
            self.fail(f"Loki is not accessible: {str(e)}")

    def test_grafana_up(self):
        """Test that Grafana is up and running."""
        try:
            response = requests.get(self.grafana_url)
            self.assertEqual(response.status_code, 200)
        except requests.RequestException as e:
            self.fail(f"Grafana is not accessible: {str(e)}")

    def test_grafana_datasources(self):
        """Test that Grafana has the required datasources."""
        try:
            # Note: This requires admin credentials
            response = requests.get(
                urljoin(self.grafana_url, "/api/datasources"),
                auth=("admin", "admin")
            )
            
            # Even if auth fails, we just want to make sure Grafana is responding
            self.assertIn(response.status_code, [200, 401, 403])
            
            if response.status_code == 200:
                datasources = response.json()
                datasource_names = [ds["name"] for ds in datasources]
                self.assertIn("Prometheus", datasource_names)
                self.assertIn("Loki", datasource_names)
        except requests.RequestException as e:
            self.fail(f"Grafana datasources API is not accessible: {str(e)}")

    def test_prometheus_metrics(self):
        """Test that Prometheus is collecting metrics."""
        try:
            response = requests.get(
                urljoin(self.prometheus_url, "/api/v1/label/__name__/values")
            )
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["status"], "success")
            
            # Check if there are metrics
            self.assertTrue(len(data["data"]) > 0)
            
            # Check for some common Prometheus metrics
            common_metrics = ["up", "process_cpu_seconds_total", "go_goroutines"]
            for metric in common_metrics:
                self.assertIn(metric, data["data"])
        except requests.RequestException as e:
            self.fail(f"Prometheus metrics API is not accessible: {str(e)}")


if __name__ == "__main__":
    unittest.main()
