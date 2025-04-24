# Script to generate traffic to the FastAPI backend

# Define the base URL
$baseUrl = "http://localhost:8000"

# Define the endpoints to hit
$endpoints = @(
    "/api/v1/utils/health-check/",
    "/api/v1/users/",
    "/api/v1/items/",
    "/metrics"
)

# Function to make a request
function Make-Request {
    param (
        [string]$url
    )
    
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -Method GET
        Write-Host "Request to $url - Status: $($response.StatusCode)"
    }
    catch {
        Write-Host "Error requesting $url - $($_.Exception.Message)"
    }
}

# Login to get a token
function Login {
    $loginUrl = "$baseUrl/api/v1/login/access-token"
    $body = @{
        username = "admin@example.com"
        password = "adminadmin"
    }
    
    try {
        $response = Invoke-WebRequest -Uri $loginUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded" -UseBasicParsing
        $token = ($response.Content | ConvertFrom-Json).access_token
        return $token
    }
    catch {
        Write-Host "Login failed: $($_.Exception.Message)"
        return $null
    }
}

# Main loop
Write-Host "Starting traffic generation to $baseUrl"
Write-Host "Press Ctrl+C to stop"

# Try to login
$token = Login
$headers = @{}
if ($token) {
    Write-Host "Login successful, using token for authenticated requests"
    $headers = @{
        "Authorization" = "Bearer $token"
    }
}
else {
    Write-Host "Continuing without authentication"
}

# Generate traffic in a loop
while ($true) {
    foreach ($endpoint in $endpoints) {
        $url = "$baseUrl$endpoint"
        
        # Use authentication for endpoints that require it
        if ($endpoint -eq "/api/v1/users/" -or $endpoint -eq "/api/v1/items/") {
            if ($token) {
                try {
                    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -Method GET -Headers $headers
                    Write-Host "Authenticated request to $url - Status: $($response.StatusCode)"
                }
                catch {
                    Write-Host "Error requesting $url - $($_.Exception.Message)"
                }
            }
        }
        else {
            # Public endpoints
            Make-Request -url $url
        }
        
        # Add a small delay between requests
        Start-Sleep -Milliseconds 500
    }
    
    # Wait a bit before the next round
    Start-Sleep -Seconds 2
    
    # Refresh token every 10 minutes
    $tokenRefreshCounter++
    if ($tokenRefreshCounter -ge 300) {
        $token = Login
        if ($token) {
            $headers = @{
                "Authorization" = "Bearer $token"
            }
        }
        $tokenRefreshCounter = 0
    }
}
