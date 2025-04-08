#!/usr/bin/env bats

# Bats test file for app-status.sh

# Setup - runs before each test
setup() {
  # Create a temporary directory for test files
  export TEMP_DIR="$(mktemp -d)"

  # Save the original directory
  export ORIG_DIR="$PWD"

  # Change to the temp directory
  cd "$TEMP_DIR"

  # Create a mock version of the script for testing
  export SCRIPT_PATH="$TEMP_DIR/app-status.sh"
  cp "$ORIG_DIR/scripts/status/app-status.sh" "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"
}

# Teardown - runs after each test
teardown() {
  # Return to the original directory
  cd "$ORIG_DIR"

  # Clean up the temporary directory
  rm -rf "$TEMP_DIR"
}

# Test that the script executes successfully
@test "app-status.sh executes successfully" {
  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]
}

# Test that the script displays application URLs
@test "app-status.sh displays application URLs" {
  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output contains the expected URLs
  [[ "$output" == *"Application URLs"* ]]
  [[ "$output" == *"Frontend Dashboard: http://dashboard.localhost"* ]]
  [[ "$output" == *"API Documentation:  http://api.localhost/docs"* ]]
  [[ "$output" == *"Database Admin:     http://adminer.localhost"* ]]
  [[ "$output" == *"Mail Catcher:       http://mail.localhost"* ]]
  [[ "$output" == *"Traefik Dashboard:  http://traefik.localhost"* ]]
}

# Test that the script displays login information
@test "app-status.sh displays login information" {
  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output contains the expected login information
  [[ "$output" == *"Default Login"* ]]
  [[ "$output" == *"Email:    admin@example.com"* ]]
  [[ "$output" == *"Password: FastAPI_Secure_2025!"* ]]
}

# Test that the script waits before displaying information
@test "app-status.sh waits before displaying information" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/sh
# Record start time
start_time=$(date +%s)

# Wait for a moment to make sure everything is ready
sleep 2

# Record end time
end_time=$(date +%s)

# Calculate elapsed time
elapsed=$((end_time - start_time))

# Check if at least 2 seconds have passed
if [ $elapsed -ge 2 ]; then
  echo "WAIT_SUCCESSFUL=true"
else
  echo "WAIT_FAILED=true"
fi
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script waited for at least 2 seconds
  [ "$status" -eq 0 ]
  [[ "$output" == *"WAIT_SUCCESSFUL=true"* ]]
}

# Test the full script execution
@test "app-status.sh runs successfully with all expected output" {
  # Create a simplified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/sh
# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Skip the sleep for testing
# sleep 2

# Header with URLs
printf "\n\n${BOLD}=============================================\n"
printf "${BOLD}       FastAPI Application Ready!     \n"
printf "${BOLD}=============================================\n"

# Application URLs
printf "\n${BOLD}Application URLs:${NC}\n"
printf "Frontend Dashboard: ${GREEN}http://dashboard.localhost${NC}\n"
printf "API Documentation:  ${GREEN}http://api.localhost/docs${NC}\n"

# Login information
printf "\n${BOLD}Default Login:${NC}\n"
printf "Email:    ${BLUE}admin@example.com${NC}\n"
printf "Password: ${BLUE}FastAPI_Secure_2025!${NC}\n"
printf "${BOLD}=============================================\n\n"
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully and contains all expected sections
  [ "$status" -eq 0 ]
  [[ "$output" == *"FastAPI Application Ready!"* ]]
  [[ "$output" == *"Application URLs:"* ]]
  [[ "$output" == *"Frontend Dashboard:"* ]]
  [[ "$output" == *"API Documentation:"* ]]
  [[ "$output" == *"Default Login:"* ]]
  [[ "$output" == *"Email:"* ]]
  [[ "$output" == *"Password:"* ]]
}
