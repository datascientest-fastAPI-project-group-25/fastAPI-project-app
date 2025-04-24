# Monitoring and Logging Setup

This directory contains the configuration for the monitoring and logging stack for the FastAPI application.

## Overview

The monitoring stack consists of:

- **Prometheus**: Collects and stores metrics from the FastAPI application
- **Loki**: Collects and stores logs
- **Promtail**: Forwards logs to Loki
- **Grafana**: Visualizes metrics and logs

## Platform-Independent Setup

This monitoring setup is designed to work across all platforms (Windows, macOS, and Linux) without any platform-specific configurations.

### Prerequisites

- Docker and Docker Compose installed
- Docker Desktop running (for Windows and macOS)

### Starting the Monitoring Stack

#### Using the Scripts (Recommended)

We provide platform-specific scripts to start the monitoring stack:

**Windows (PowerShell):**
```powershell
.\scripts\monitoring\start-monitoring.ps1
```

**macOS/Linux (Bash):**
```bash
./scripts/monitoring/start-monitoring.sh
```

#### Manual Start

If you prefer to start the stack manually:

```bash
# Create log directories
mkdir -p logs/backend logs/application

# Start the monitoring stack
docker-compose -f docker-compose.monitoring-only.yml up -d
```

### Accessing the Dashboards

- **Grafana**: http://localhost:3001
  - Username: `admin`
  - Password: `admin`
- **Prometheus**: http://localhost:9090

## Generating Metrics

To see metrics in the dashboards, you need to:

1. Start the backend application:
   ```bash
   docker-compose -f docker-compose.backend-only.yml up -d
   ```

2. Generate traffic to the backend API:
   ```powershell
   # Windows
   .\scripts\monitoring\generate-traffic.ps1
   ```
   ```bash
   # macOS/Linux
   ./scripts/monitoring/generate-traffic.sh
   ```

## Available Dashboards

- **FastAPI Overview**: General metrics about the FastAPI application
- **FastAPI Dashboard**: Detailed metrics about the FastAPI application

## Troubleshooting

### No Metrics Showing in Grafana

1. Make sure the backend application is running
2. Check that the backend is exposing metrics at `/metrics`
3. Verify that Prometheus can scrape the metrics (check Prometheus targets)
4. Generate some traffic to the backend API

### No Logs Showing in Grafana

1. Check that the application is writing logs to the correct location
2. Verify that Promtail is running and configured correctly
3. Check Loki's status in Grafana's data sources

### Docker Issues

If you encounter Docker-related issues:

1. Restart Docker Desktop
2. Run `docker-compose down` before starting the stack again
3. Check Docker logs for any errors

## Customizing the Setup

### Adding New Dashboards

1. Create a new JSON dashboard in Grafana
2. Export the dashboard
3. Save the JSON file in the `monitoring/dashboards` directory
4. Update `monitoring/grafana-dashboards.yml` if needed

### Modifying Prometheus Configuration

Edit `monitoring/prometheus.yml` to change how Prometheus scrapes metrics.

### Modifying Loki Configuration

Edit `monitoring/loki-config.yml` to change Loki's behavior.

## Restarting After a Break

If you've taken a break from development and need to restart the monitoring stack:

1. Start Docker Desktop (if not already running)
2. Run the appropriate start script for your platform
3. Verify that all services are running
4. Start generating traffic to see metrics
