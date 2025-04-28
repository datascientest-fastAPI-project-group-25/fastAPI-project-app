#!/bin/bash
# Bash script to start the monitoring stack
# Works on macOS and Linux

# Navigate to the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "Starting monitoring stack from $PROJECT_ROOT..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi
echo "Docker is running."

# Create log directories if they don't exist
LOG_DIRS=("logs/backend" "logs/application")
for dir in "${LOG_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "Created log directory: $dir"
    fi
done

# Start the monitoring stack
echo "Starting monitoring services..."
docker-compose -f docker-compose.monitoring-only.yml up -d

# Check if services are running
echo "Checking if services are running..."
SERVICES=("prometheus" "loki" "grafana")
for service in "${SERVICES[@]}"; do
    status=$(docker ps --filter "name=$service" --format "{{.Status}}")
    if [ -n "$status" ]; then
        echo -e "\033[0;32m$service is running: $status\033[0m"
    else
        echo -e "\033[0;33m$service is not running\033[0m"
    fi
done

echo ""
echo -e "\033[0;32mMonitoring stack is ready!\033[0m"
echo "Access the dashboards at:"
echo "- Grafana: http://localhost:3001 (admin/admin)"
echo "- Prometheus: http://localhost:9090"
echo ""
echo "To generate metrics, make sure your backend is running and receiving traffic."
