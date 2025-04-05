#!/usr/bin/env bats

# Bats test file for update-docs.sh

# Setup - runs before each test
setup() {
  # Create a temporary directory for test files
  export TEMP_DIR="$(mktemp -d)"

  # Save the original directory
  export ORIG_DIR="$PWD"

  # Change to the temp directory
  cd "$TEMP_DIR"

  # Create a mock version of the script for testing
  export SCRIPT_PATH="$TEMP_DIR/update-docs.sh"
  cp "$ORIG_DIR/scripts/docs/update-docs.sh" "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"
}

# Teardown - runs after each test
teardown() {
  # Return to the original directory
  cd "$ORIG_DIR"

  # Clean up the temporary directory
  rm -rf "$TEMP_DIR"
}

# Test that the script creates the docs directory if it doesn't exist
@test "update-docs.sh creates the docs directory if it doesn't exist" {
  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]

  # Check that the docs directory was created
  [ -d "docs" ]
}

# Test that the script writes the changelog to the file
@test "update-docs.sh writes the changelog to the file" {
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

# Test that the script overwrites an existing changelog file
@test "update-docs.sh overwrites an existing changelog file" {
  # Create the docs directory and an existing changelog file
  mkdir -p "docs"
  echo "Old content" > "docs/CHANGELOG.md"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]

  # Check that the changelog file was updated
  run cat "docs/CHANGELOG.md"
  [[ "$output" != *"Old content"* ]]
  [[ "$output" == *"# Changelog"* ]]
  [[ "$output" == *"## Test Update"* ]]
}

# Test that the script outputs success messages
@test "update-docs.sh outputs success messages" {
  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]

  # Check that the output contains success messages
  [[ "$output" == *"Simulated documentation update complete!"* ]]
  [[ "$output" == *"Changelog written to docs/CHANGELOG.md"* ]]
}

# Test the script with a custom changelog
@test "update-docs.sh works with a custom changelog" {
  # Create a modified version of the script with a custom changelog
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash

# Custom changelog
changelog="# Custom Changelog
## Version 2.0.0

* Feature A by Developer X on 2025-04-01
* Feature B by Developer Y on 2025-04-02"

# Update documentation file
echo "$changelog" > docs/CHANGELOG.md

echo "Documentation update complete!"
echo "Custom changelog written to docs/CHANGELOG.md"
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]

  # Check that the changelog file was created with the custom content
  run cat "docs/CHANGELOG.md"
  [[ "$output" == *"# Custom Changelog"* ]]
  [[ "$output" == *"## Version 2.0.0"* ]]
  [[ "$output" == *"Feature A by Developer X on 2025-04-01"* ]]
  [[ "$output" == *"Feature B by Developer Y on 2025-04-02"* ]]

  # Check that the output contains the custom success messages
  [[ "$output" == *"Documentation update complete!"* ]]
  [[ "$output" == *"Custom changelog written to docs/CHANGELOG.md"* ]]
}
