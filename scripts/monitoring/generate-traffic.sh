#!/bin/bash
# Bash script to generate traffic to the FastAPI backend
# Works on macOS and Linux

# Define the base URL
BASE_URL="http://localhost:8000"

# Function to make a request
make_request() {
    url=$1
    method=${2:-GET}
    auth_header=${3:-""}
    
    if [ -n "$auth_header" ]; then
        response=$(curl -s -X "$method" -H "$auth_header" "$url")
    else
        response=$(curl -s -X "$method" "$url")
    fi
    
    status=$?
    if [ $status -eq 0 ]; then
        echo "Request to $url - Success"
    else
        echo "Error requesting $url - Status: $status"
    fi
}

# Login to get a token
get_auth_token() {
    login_url="$BASE_URL/api/v1/login/access-token"
    response=$(curl -s -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=admin@example.com&password=adminadmin&grant_type=password" \
        "$login_url")
    
    if [ $? -eq 0 ]; then
        # Extract token using grep and cut (basic approach)
        token=$(echo "$response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$token" ]; then
            echo "Login successful, got token"
            echo "$token"
            return
        fi
    fi
    
    echo "Login failed"
    echo ""
}

# Get auth token
token=$(get_auth_token)
auth_header=""
if [ -n "$token" ]; then
    auth_header="Authorization: Bearer $token"
    echo "Using authentication token for requests"
fi

# Define endpoints to test
endpoints=(
    "$BASE_URL/api/v1/utils/health-check/|false"
    "$BASE_URL/api/v1/users/|true"
    "$BASE_URL/api/v1/items/|true"
    "$BASE_URL/metrics|false"
)

# Generate traffic
echo "Generating traffic to FastAPI backend..."
iterations=100
for ((i=0; i<iterations; i++)); do
    for endpoint in "${endpoints[@]}"; do
        IFS='|' read -r url requires_auth <<< "$endpoint"
        
        if [ "$requires_auth" = "true" ] && [ -n "$token" ]; then
            make_request "$url" "GET" "$auth_header"
        else
            make_request "$url"
        fi
        
        sleep 0.1
    done
    
    # Show progress
    if ((i % 10 == 0)); then
        echo "Completed $i/$iterations iterations"
    fi
done

echo "Traffic generation complete!"
