# Script to generate more traffic to the FastAPI backend with authentication

# Define the base URL
$baseUrl = "http://localhost:8000"

# Function to make a request
function Make-Request {
    param (
        [string]$url,
        [string]$method = "GET",
        [hashtable]$headers = @{},
        [object]$body = $null,
        [string]$contentType = "application/json"
    )
    
    try {
        $params = @{
            Uri = $url
            Method = $method
            UseBasicParsing = $true
            Headers = $headers
        }
        
        if ($body -and $method -ne "GET") {
            $params.Body = $body
            $params.ContentType = $contentType
        }
        
        $response = Invoke-WebRequest @params
        Write-Host "Request to $url - Status: $($response.StatusCode)"
        return $response
    }
    catch {
        Write-Host "Error requesting $url - $($_.Exception.Message)"
        return $null
    }
}

# Login to get a token
function Get-AuthToken {
    $loginUrl = "$baseUrl/api/v1/login/access-token"
    $body = "username=admin@example.com&password=adminadmin&grant_type=password"
    
    try {
        $response = Make-Request -url $loginUrl -method "POST" -body $body -contentType "application/x-www-form-urlencoded"
        if ($response) {
            $token = ($response.Content | ConvertFrom-Json).access_token
            Write-Host "Login successful, got token"
            return $token
        }
    }
    catch {
        Write-Host "Login failed: $($_.Exception.Message)"
    }
    return $null
}

# Get auth token
$token = Get-AuthToken
$authHeaders = @{}
if ($token) {
    $authHeaders = @{
        "Authorization" = "Bearer $token"
    }
    Write-Host "Using authentication token for requests"
}

# Define endpoints to test
$endpoints = @(
    @{ Url = "$baseUrl/api/v1/utils/health-check/"; Auth = $false },
    @{ Url = "$baseUrl/api/v1/users/"; Auth = $true },
    @{ Url = "$baseUrl/api/v1/items/"; Auth = $true },
    @{ Url = "$baseUrl/metrics"; Auth = $false }
)

# Generate traffic
Write-Host "Generating traffic to FastAPI backend..."
for ($i = 0; $i -lt 200; $i++) {
    foreach ($endpoint in $endpoints) {
        if ($endpoint.Auth -and $token) {
            Make-Request -url $endpoint.Url -headers $authHeaders
        } else {
            Make-Request -url $endpoint.Url
        }
        Start-Sleep -Milliseconds 100
    }
    
    # Show progress
    if ($i % 10 -eq 0) {
        Write-Host "Completed $i iterations"
    }
}

Write-Host "Traffic generation complete!"
