# Monitoring Tests

This directory contains tests for the monitoring setup of the FastAPI application.

## Running Tests Locally

To run these tests locally, you need to have the monitoring stack running:

```bash
# Start the monitoring stack
docker-compose -f docker-compose.monitoring-only.yml up -d
```

Then run the tests:

```bash
# Install dependencies
pip install pytest requests

# Run the tests
pytest tests/monitoring/test_monitoring_services.py -v
```

## GitHub Actions Integration

These tests are automatically run in GitHub Actions when pushing to the feature branch.
