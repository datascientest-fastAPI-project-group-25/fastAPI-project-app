# PowerShell script to start the monitoring stack
# Works on Windows

# Navigate to the project root directory
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $projectRoot

Write-Host "Starting monitoring stack from $projectRoot..."

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "Docker is running."
} catch {
    Write-Host "Error: Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Create log directories if they don't exist
$logDirs = @("logs/backend", "logs/application")
foreach ($dir in $logDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "Created log directory: $dir"
    }
}

# Start the monitoring stack
Write-Host "Starting monitoring services..."
docker-compose -f docker-compose.monitoring-only.yml up -d

# Check if services are running
Write-Host "Checking if services are running..."
$services = @("prometheus", "loki", "grafana")
foreach ($service in $services) {
    $status = docker ps --filter "name=$service" --format "{{.Status}}"
    if ($status) {
        Write-Host "$service is running: $status" -ForegroundColor Green
    } else {
        Write-Host "$service is not running" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Monitoring stack is ready!" -ForegroundColor Green
Write-Host "Access the dashboards at:"
Write-Host "- Grafana: http://localhost:3001 (admin/admin)"
Write-Host "- Prometheus: http://localhost:9090"
Write-Host ""
Write-Host "To generate metrics, make sure your backend is running and receiving traffic."
