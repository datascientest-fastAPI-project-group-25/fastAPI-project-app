import requests
import json
import time
import os

def check_prometheus():
    """Check if Prometheus is collecting metrics."""
    print("\n=== Checking Prometheus Metrics ===")

    # Query Prometheus for metrics
    try:
        prometheus_host = os.environ.get("PROMETHEUS_HOST", "prometheus")
        response = requests.get(f"http://{prometheus_host}:9090/api/v1/query", params={
            "query": "http_requests_total"
        })

        if response.status_code == 200:
            data = response.json()
            if data["status"] == "success" and len(data["data"]["result"]) > 0:
                print("✅ Prometheus is collecting metrics")
                print(f"Found {len(data['data']['result'])} metrics")

                # Print a sample of the metrics
                for i, result in enumerate(data["data"]["result"][:3]):
                    print(f"  Sample {i+1}: {result['metric']}")
            else:
                print("❌ No metrics found in Prometheus")
        else:
            print(f"❌ Failed to query Prometheus: {response.status_code}")

    except Exception as e:
        print(f"❌ Error checking Prometheus: {str(e)}")

def check_loki():
    """Check if Loki is collecting logs."""
    print("\n=== Checking Loki Logs ===")

    # Query Loki for logs
    try:
        # Current time in nanoseconds
        now = int(time.time() * 1e9)
        # 1 hour ago in nanoseconds
        one_hour_ago = int((time.time() - 3600) * 1e9)

        loki_host = os.environ.get("LOKI_HOST", "loki")
        response = requests.get(
            f"http://{loki_host}:3100/loki/api/v1/query_range",
            params={
                "query": '{container="backend"}',
                "start": one_hour_ago,
                "end": now,
                "limit": 10
            }
        )

        if response.status_code == 200:
            data = response.json()
            if "data" in data and "result" in data["data"] and len(data["data"]["result"]) > 0:
                print("✅ Loki is collecting logs")
                print(f"Found {len(data['data']['result'])} log streams")

                # Print a sample of the logs
                for stream in data["data"]["result"][:2]:
                    print(f"  Stream: {stream['stream']}")
                    for i, entry in enumerate(stream["values"][:3]):
                        print(f"    Log {i+1}: {entry[1][:100]}...")
            else:
                print("❌ No logs found in Loki")
        else:
            print(f"❌ Failed to query Loki: {response.status_code}")

    except Exception as e:
        print(f"❌ Error checking Loki: {str(e)}")

def check_grafana():
    """Check if Grafana is configured correctly."""
    print("\n=== Checking Grafana Configuration ===")

    # Check Grafana datasources
    try:
        # Note: This requires admin credentials
        grafana_host = os.environ.get("GRAFANA_HOST", "grafana")
        response = requests.get(
            f"http://{grafana_host}:3000/api/datasources",
            auth=("admin", "admin")
        )

        if response.status_code == 200:
            datasources = response.json()
            print(f"✅ Grafana has {len(datasources)} datasources configured")

            # Print datasource names
            for ds in datasources:
                print(f"  - {ds['name']} ({ds['type']})")
        else:
            print(f"❌ Failed to query Grafana datasources: {response.status_code}")

    except Exception as e:
        print(f"❌ Error checking Grafana: {str(e)}")

    grafana_host = os.environ.get("GRAFANA_HOST", "grafana")
    print(f"\nGrafana dashboards can be accessed at: http://{grafana_host}:3000")
    print("Default credentials: admin/admin")

def check_health_endpoint():
    """Check if the health endpoint is working."""
    print("\n=== Checking Health Endpoint ===")

    try:
        backend_host = os.environ.get("BACKEND_HOST", "backend")
        response = requests.get(f"http://{backend_host}:8000/api/v1/utils/health-check/")

        if response.status_code == 200:
            data = response.json()
            print("✅ Health endpoint is working")
            print(f"  Status: {data.get('status', 'unknown')}")

            # Print other health information
            if "service" in data:
                print(f"  Service: {data['service'].get('name', 'unknown')}")
                print(f"  Environment: {data['service'].get('environment', 'unknown')}")

            if "system" in data:
                print(f"  Database: {data['system'].get('database', 'unknown')}")
        else:
            print(f"❌ Health endpoint returned status code: {response.status_code}")

    except Exception as e:
        print(f"❌ Error checking health endpoint: {str(e)}")

if __name__ == "__main__":
    print("=== Monitoring and Logging Test ===")

    # Check each component
    check_prometheus()
    check_loki()
    check_grafana()
    check_health_endpoint()

    print("\n=== Test Complete ===")
    print("For more detailed analysis, visit:")
    prometheus_host = os.environ.get("PROMETHEUS_HOST", "prometheus")
    grafana_host = os.environ.get("GRAFANA_HOST", "grafana")
    loki_host = os.environ.get("LOKI_HOST", "loki")
    print(f"- Prometheus: http://{prometheus_host}:9090")
    print(f"- Grafana: http://{grafana_host}:3000")
    print(f"- Loki: http://{loki_host}:3100")
