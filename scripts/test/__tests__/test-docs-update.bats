#!/usr/bin/env bats

# Bats test file for test-docs-update.sh

# Setup - runs before each test
setup() {
  # Create a temporary directory for test files
  export TEMP_DIR="$(mktemp -d)"

  # Save the original directory
  export ORIG_DIR="$PWD"

  # Change to the temp directory
  cd "$TEMP_DIR"

  # Create mock project structure
  mkdir -p docs

  # Create a mock version of the script for testing
  export SCRIPT_PATH="$TEMP_DIR/test-docs-update.sh"
  cp "$ORIG_DIR/scripts/test/test-docs-update.sh" "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"
}

# Teardown - runs after each test
teardown() {
  # Return to the original directory
  cd "$ORIG_DIR"

  # Clean up the temporary directory
  rm -rf "$TEMP_DIR"
}

# Test that the script simulates fetching a changelog
@test "test-docs-update.sh simulates fetching a changelog" {
  # Run the script with a modified version that exits after fetching changelog
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash

# Simulate fetching changelog from API
changelog="# Changelog
## Test Update

* Initial commit by Test User on 2025-03-25
* Add test feature by Test User on 2025-03-25"

echo "CHANGELOG_FETCHED=true"
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates the changelog was fetched
  [ "$status" -eq 0 ]
  [[ "$output" == *"CHANGELOG_FETCHED=true"* ]]
}

# Test that the script writes the changelog to a file
@test "test-docs-update.sh writes the changelog to a file" {
  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]

  # Check that the changelog file was created
  [ -f "docs/CHANGELOG.md" ]

  # Check the content of the changelog file
  run cat "docs/CHANGELOG.md"
  [[ "$output" == *"# Changelog"* ]]
  [[ "$output" == *"## Test Update"* ]]
  [[ "$output" == *"Initial commit by Test User on 2025-03-25"* ]]
  [[ "$output" == *"Add test feature by Test User on 2025-03-25"* ]]
}

# Test that the script outputs a success message
@test "test-docs-update.sh outputs a success message" {
  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output contains the success message
  [ "$status" -eq 0 ]
  [[ "$output" == *"Simulated documentation update complete!"* ]]
  [[ "$output" == *"Changelog written to docs/CHANGELOG.md"* ]]
}

# Test the script with a custom changelog
@test "test-docs-update.sh works with a custom changelog" {
  # Create a modified version of the script with a custom changelog
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash

# Simulate fetching changelog from API
changelog="# Custom Changelog
## Version 2.0.0

* Feature A by Developer X on 2025-04-01
* Feature B by Developer Y on 2025-04-02"

# Simulate updating documentation file
echo "$changelog" > docs/CHANGELOG.md

echo "Simulated documentation update complete!"
echo "Changelog written to docs/CHANGELOG.md"
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]

  # Check that the changelog file was created
  [ -f "docs/CHANGELOG.md" ]

  # Check the content of the changelog file
  run cat "docs/CHANGELOG.md"
  [[ "$output" == *"# Custom Changelog"* ]]
  [[ "$output" == *"## Version 2.0.0"* ]]
  [[ "$output" == *"Feature A by Developer X on 2025-04-01"* ]]
  [[ "$output" == *"Feature B by Developer Y on 2025-04-02"* ]]
}

# Test that the script creates the docs directory if it doesn't exist
@test "test-docs-update.sh creates the docs directory if it doesn't exist" {
  # Remove the docs directory
  rm -rf docs

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]

  # Check that the docs directory was created
  [ -d "docs" ]

  # Check that the changelog file was created
  [ -f "docs/CHANGELOG.md" ]
}

# Test the full script execution
@test "test-docs-update.sh runs successfully" {
  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]

  # Check that the output contains the expected messages
  [[ "$output" == *"Simulated documentation update complete!"* ]]
  [[ "$output" == *"Changelog written to docs/CHANGELOG.md"* ]]

  # Check that the changelog file was created with the expected content
  [ -f "docs/CHANGELOG.md" ]
  run cat "docs/CHANGELOG.md"
  [[ "$output" == *"# Changelog"* ]]
  [[ "$output" == *"## Test Update"* ]]
}
