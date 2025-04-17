import unittest
import requests
import os
import time
from urllib.parse import urljoin


class TestMonitoringServices(unittest.TestCase):
    """Test that monitoring services are running."""

    def test_prometheus_up(self):
        """Test that Prometheus is up and running."""
        prometheus_url = os.environ.get("PROMETHEUS_URL", "http://localhost:9090")
        try:
            response = requests.get(prometheus_url, timeout=5)
            self.assertTrue(response.status_code < 400, f"Prometheus returned status code {response.status_code}")
            print(f"Prometheus is up and running at {prometheus_url}")
        except requests.RequestException as e:
            self.fail(f"Prometheus is not accessible: {str(e)}")

    def test_grafana_up(self):
        """Test that Grafana is up and running."""
        grafana_url = os.environ.get("GRAFANA_URL", "http://localhost:3000")
        try:
            response = requests.get(grafana_url, timeout=5)
            self.assertTrue(response.status_code < 400, f"Grafana returned status code {response.status_code}")
            print(f"Grafana is up and running at {grafana_url}")
        except requests.RequestException as e:
            self.fail(f"Grafana is not accessible: {str(e)}")

    def test_loki_up(self):
        """Test that Loki is up and running."""
        loki_url = os.environ.get("LOKI_URL", "http://localhost:3100")
        try:
            # Test the Loki ready endpoint
            response = requests.get(urljoin(loki_url, "/ready"), timeout=5)
            self.assertTrue(response.status_code < 400, f"Loki returned status code {response.status_code}")
            print(f"Loki is up and running at {loki_url}")
        except requests.RequestException as e:
            self.fail(f"Loki is not accessible: {str(e)}")


if __name__ == "__main__":
    unittest.main()
