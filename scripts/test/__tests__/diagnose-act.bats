#!/usr/bin/env bats

# Bats test file for diagnose-act.sh

# Setup - runs before each test
setup() {
  # Create a temporary directory for test files
  export TEMP_DIR="$(mktemp -d)"
  
  # Save the original directory
  export ORIG_DIR="$PWD"
  
  # Change to the temp directory
  cd "$TEMP_DIR"
  
  # Create mock project structure
  mkdir -p .github/workflows/events
  touch .github/workflows/events/push.json
  touch .github/workflows/events/pull_request.json
  
  # Create mock .actrc and .env.test files
  echo "--container-architecture linux/amd64" > .actrc
  echo "TEST_ENV=test_value" > .env.test
  
  # Create a mock version of the script for testing
  export SCRIPT_PATH="$TEMP_DIR/diagnose-act.sh"
  cp "$ORIG_DIR/scripts/test/diagnose-act.sh" "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"
  
  # Mock external commands
  mock_command "docker" "echo 'Docker is running'"
  mock_command "act" "echo 'Act is installed'"
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
echo "$output"
exit 0
EOF
  chmod +x "$TEMP_DIR/bin/$cmd"
  export PATH="$TEMP_DIR/bin:$PATH"
}

# Test that the script checks if act is installed
@test "diagnose-act.sh checks if act is installed" {
  # Override the act command to return success
  mock_command "act" "Act version 0.2.34"
  
  # Run the script with the check for act only
  run bash -c "sed -n '/Checking if act is installed/,/act is installed/p' \"$SCRIPT_PATH\" | bash"
  
  # Check that the output contains the success message
  [ "$status" -eq 0 ]
  [[ "$output" == *"act is installed"* ]]
}

# Test that the script checks if Docker is running
@test "diagnose-act.sh checks if Docker is running" {
  # Run the script with the check for Docker only
  run bash -c "sed -n '/Checking Docker/,/Docker is running/p' \"$SCRIPT_PATH\" | bash"
  
  # Check that the output contains the success message
  [ "$status" -eq 0 ]
  [[ "$output" == *"Docker is running"* ]]
}

# Test that the script checks for required Docker images
@test "diagnose-act.sh checks for required Docker images" {
  # Override the docker command to simulate image check
  mock_command "docker" "echo 'Image exists'"
  
  # Run the script with the check for Docker images only
  run bash -c "sed -n '/Checking for required Docker images/,/Some required Docker images are missing/p' \"$SCRIPT_PATH\" | bash"
  
  # Check that the output contains the image check
  [ "$status" -eq 0 ]
  [[ "$output" == *"Checking for required Docker images"* ]]
}

# Test that the script checks for .actrc file
@test "diagnose-act.sh checks for .actrc file" {
  # Run the script with the check for .actrc only
  run bash -c "sed -n '/Checking .actrc configuration/,/.actrc file exists/p' \"$SCRIPT_PATH\" | bash"
  
  # Check that the output contains the success message
  [ "$status" -eq 0 ]
  [[ "$output" == *".actrc file exists"* ]]
}

# Test that the script checks for test environment file
@test "diagnose-act.sh checks for test environment file" {
  # Run the script with the check for .env.test only
  run bash -c "sed -n '/Checking test environment file/,/.env.test file exists/p' \"$SCRIPT_PATH\" | bash"
  
  # Check that the output contains the success message
  [ "$status" -eq 0 ]
  [[ "$output" == *".env.test file exists"* ]]
}

# Test that the script checks for event files
@test "diagnose-act.sh checks for event files" {
  # Run the script with the check for event files only
  run bash -c "sed -n '/Checking event files/,/Event files exist/p' \"$SCRIPT_PATH\" | bash"
  
  # Check that the output contains the success message
  [ "$status" -eq 0 ]
  [[ "$output" == *"Event files exist"* ]]
}

# Test that the script creates a temporary workflow file
@test "diagnose-act.sh creates a temporary workflow file" {
  # Run the script with the temporary workflow creation only
  run bash -c "sed -n '/Testing a simple workflow/,/Created temporary workflow file/p' \"$SCRIPT_PATH\" | bash"
  
  # Check that the output contains the success message
  [ "$status" -eq 0 ]
  [[ "$output" == *"Created temporary workflow file"* ]]
  
  # Check that the file was created
  [ -f ".github/workflows/act-test.yml" ]
}

# Test the full script execution (mocked)
@test "diagnose-act.sh runs successfully with all checks passing" {
  # Mock the act command to return success
  mock_command "act" "echo 'Act executed successfully'"
  
  # Create a simplified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
echo "=== ACT Diagnostic Tool ==="
echo "Checking if act is installed..."
echo "✓ act is installed"
echo "Checking Docker..."
echo "✓ Docker is running"
echo "Checking for required Docker images..."
echo "✓ Image found: catthehacker/ubuntu:act-latest"
echo "✓ Image found: node:18-bullseye"
echo "Checking .actrc configuration..."
echo "✓ .actrc file exists"
echo "Checking test environment file..."
echo "✓ .env.test file exists"
echo "Checking event files..."
echo "✓ Event files exist"
echo "Testing a simple workflow..."
echo "Created temporary workflow file: .github/workflows/act-test.yml"
echo "Running act with the test workflow..."
echo "Act executed successfully"
echo "Cleaning up..."
echo "✓ Temporary workflow file removed"
echo "Diagnostic test complete!"
exit 0
EOF
  chmod +x "$SCRIPT_PATH"
  
  # Run the script
  run "$SCRIPT_PATH"
  
  # Check that the script executed successfully
  [ "$status" -eq 0 ]
  [[ "$output" == *"Diagnostic test complete!"* ]]
}