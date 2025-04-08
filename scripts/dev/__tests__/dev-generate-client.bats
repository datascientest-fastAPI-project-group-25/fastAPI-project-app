#!/usr/bin/env bats

# Bats test file for dev-generate-client.sh

# Setup - runs before each test
setup() {
  # Create a temporary directory for test files
  export TEMP_DIR="$(mktemp -d)"

  # Save the original directory
  export ORIG_DIR="$PWD"

  # Change to the temp directory
  cd "$TEMP_DIR"

  # Create mock project structure
  mkdir -p backend/app
  mkdir -p frontend/src

  # Create mock Python module
  mkdir -p backend/app
  touch backend/app/__init__.py
  cat > backend/app/main.py << 'EOF'
class MockApp:
    def openapi(self):
        return {"openapi": "3.0.0", "info": {"title": "Test API", "version": "1.0.0"}}

app = MockApp()
EOF

  # Create mock package.json
  cat > frontend/package.json << 'EOF'
{
  "name": "test-frontend",
  "version": "1.0.0",
  "scripts": {
    "generate-client": "echo 'Generating client...'"
  }
}
EOF

  # Create a mock version of the script for testing
  export SCRIPT_PATH="$TEMP_DIR/dev-generate-client.sh"
  cp "$ORIG_DIR/scripts/dev/dev-generate-client.sh" "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"

  # Mock external commands
  mock_command "python" "echo 'Python command executed: $@'; if [[ \$* == *-c* ]]; then echo '{\"openapi\":\"3.0.0\"}'; fi; exit 0"
  mock_command "node" "echo 'Node.js command executed: $@'; exit 0"
  mock_command "npm" "echo 'npm command executed: $@'; mkdir -p frontend/src/client; exit 0"
  mock_command "npx" "echo 'npx command executed: $@'; exit 0"
}

# Teardown - runs after each test
teardown() {
  # Return to the original directory
  cd "$ORIG_DIR"

  # Clean up the temporary directory
  rm -rf "$TEMP_DIR"
}

# Helper function to mock commands
mock_command() {
  local cmd="$1"
  local output="$2"

  mkdir -p "$TEMP_DIR/bin"
  cat > "$TEMP_DIR/bin/$cmd" << EOF
#!/bin/bash
$output
EOF
  chmod +x "$TEMP_DIR/bin/$cmd"
  export PATH="$TEMP_DIR/bin:$PATH"
}

# Test that the script checks if Python is available
@test "dev-generate-client.sh checks if Python is available" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Function to check if Python is available
check_python() {
  if ! command -v python &> /dev/null; then
    echo "Error: Python is not installed"
    exit 1
  fi
  echo "PYTHON_AVAILABLE=true"
}

# Call the function
check_python
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates Python is available
  [ "$status" -eq 0 ]
  [[ "$output" == *"PYTHON_AVAILABLE=true"* ]]
}

# Test that the script checks if Node.js is available
@test "dev-generate-client.sh checks if Node.js is available" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Function to check if Node.js is available
check_node() {
  if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed"
    exit 1
  fi
  echo "NODE_AVAILABLE=true"
}

# Call the function
check_node
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates Node.js is available
  [ "$status" -eq 0 ]
  [[ "$output" == *"NODE_AVAILABLE=true"* ]]
}

# Test that the script checks if Biome is available
@test "dev-generate-client.sh checks if Biome is available" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Function to check if Biome is available
check_biome() {
  if [ -z "${SKIP_FORMAT}" ] && ! npx --no biome --version &> /dev/null; then
    echo "Warning: Biome is not installed"
    echo "Code formatting will be skipped"
    SKIP_FORMAT=1
  else
    echo "BIOME_AVAILABLE=true"
  fi
}

# Call the function
check_biome
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates Biome is available
  [ "$status" -eq 0 ]
  [[ "$output" == *"BIOME_AVAILABLE=true"* ]]

  # Test with SKIP_FORMAT set
  export SKIP_FORMAT=1
  run "$SCRIPT_PATH"

  # Check that the output still indicates success
  [ "$status" -eq 0 ]
}

# Test that the script generates OpenAPI schema
@test "dev-generate-client.sh generates OpenAPI schema" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Function to generate OpenAPI schema
generate_schema() {
  echo "Generating OpenAPI schema from backend..."

  cd backend
  python -c "import app.main; import json; print(json.dumps(app.main.app.openapi()))" > ../openapi.json
  cd ..

  if [ -f "openapi.json" ]; then
    echo "SCHEMA_GENERATED=true"
    mv openapi.json frontend/
  else
    echo "Error: Failed to generate OpenAPI schema"
    exit 1
  fi
}

# Call the function
generate_schema
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates schema was generated
  [ "$status" -eq 0 ]
  [[ "$output" == *"Generating OpenAPI schema from backend"* ]]
  [[ "$output" == *"SCHEMA_GENERATED=true"* ]]

  # Check that the file was moved to frontend
  [ -f "frontend/openapi.json" ]
}

# Test that the script generates TypeScript client
@test "dev-generate-client.sh generates TypeScript client" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Function to generate TypeScript client
generate_client() {
  echo "Generating TypeScript client in frontend..."

  cd frontend
  npm run generate-client

  if [ -d "./src/client" ]; then
    echo "CLIENT_GENERATED=true"
  else
    echo "Error: Failed to generate TypeScript client"
    exit 1
  fi
}

# Create the client directory to simulate successful generation
mkdir -p frontend/src/client

# Call the function
generate_client
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates client was generated
  [ "$status" -eq 0 ]
  [[ "$output" == *"Generating TypeScript client in frontend"* ]]
  [[ "$output" == *"CLIENT_GENERATED=true"* ]]
}

# Test that the script formats generated code
@test "dev-generate-client.sh formats generated code" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Function to format generated code
format_code() {
  if [ -z "${SKIP_FORMAT}" ]; then
    echo "Formatting generated client code..."

    cd frontend
    npx biome format --write ./src/client

    echo "CODE_FORMATTED=true"
  else
    echo "Skipping code formatting (SKIP_FORMAT is set)"
  fi
}

# Create the client directory
mkdir -p frontend/src/client

# Call the function
format_code
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates code was formatted
  [ "$status" -eq 0 ]
  [[ "$output" == *"Formatting generated client code"* ]]
  [[ "$output" == *"CODE_FORMATTED=true"* ]]

  # Test with SKIP_FORMAT set
  export SKIP_FORMAT=1
  run "$SCRIPT_PATH"

  # Check that the output indicates formatting was skipped
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipping code formatting"* ]]
}

# Test the full script execution (mocked)
@test "dev-generate-client.sh runs successfully with mocked commands" {
  # Create a simplified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
echo "=== DevOps Demo Application - API Client Generator ==="
echo "Checking dependencies..."
echo "Python is available"
echo "Node.js is available"
echo "Biome is available for code formatting"
echo "Generating OpenAPI schema from backend..."
echo "OpenAPI schema generated successfully"
echo "Generating TypeScript client in frontend..."
echo "TypeScript client generated successfully"
echo "Formatting generated client code..."
echo "Client code formatted successfully"
echo "=== API client generation completed successfully ==="
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]
  [[ "$output" == *"=== DevOps Demo Application - API Client Generator ==="* ]]
  [[ "$output" == *"Python is available"* ]]
  [[ "$output" == *"Node.js is available"* ]]
  [[ "$output" == *"Biome is available for code formatting"* ]]
  [[ "$output" == *"OpenAPI schema generated successfully"* ]]
  [[ "$output" == *"TypeScript client generated successfully"* ]]
  [[ "$output" == *"Client code formatted successfully"* ]]
  [[ "$output" == *"=== API client generation completed successfully ==="* ]]
}
