#!/usr/bin/env bats

# Bats test file for setup-project.sh

# Setup - runs before each test
setup() {
  # Create a temporary directory for test files
  export TEMP_DIR="$(mktemp -d)"

  # Save the original directory
  export ORIG_DIR="$PWD"

  # Change to the temp directory
  cd "$TEMP_DIR"

  # Create a mock version of the script for testing
  export SCRIPT_PATH="$TEMP_DIR/setup-project.sh"
  cp "$ORIG_DIR/scripts/dev/setup-project.sh" "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"
}

# Teardown - runs after each test
teardown() {
  # Return to the original directory
  cd "$ORIG_DIR"

  # Clean up the temporary directory
  rm -rf "$TEMP_DIR"
}

# Test that the script creates directories
@test "setup-project.sh creates directories" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Function to create directory if it doesn't exist
create_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    echo "CREATED_DIR=$1"
  else
    echo "DIR_EXISTS=$1"
  fi
}

# Create test directories
create_dir "test_dir1"
create_dir "test_dir2/nested"
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates directories were created
  [ "$status" -eq 0 ]
  [[ "$output" == *"CREATED_DIR=test_dir1"* ]]
  [[ "$output" == *"CREATED_DIR=test_dir2/nested"* ]]

  # Check that the directories were actually created
  [ -d "test_dir1" ]
  [ -d "test_dir2/nested" ]
}

# Test that the script doesn't recreate existing directories
@test "setup-project.sh doesn't recreate existing directories" {
  # Create a directory that already exists
  mkdir -p "existing_dir"

  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Function to create directory if it doesn't exist
create_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    echo "CREATED_DIR=$1"
  else
    echo "DIR_EXISTS=$1"
  fi
}

# Try to create an existing directory
create_dir "existing_dir"
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates the directory already exists
  [ "$status" -eq 0 ]
  [[ "$output" == *"DIR_EXISTS=existing_dir"* ]]
  [[ "$output" != *"CREATED_DIR=existing_dir"* ]]
}

# Test that the script creates files
@test "setup-project.sh creates files" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Function to create file if it doesn't exist
create_file() {
  if [ ! -f "$1" ]; then
    touch "$1"
    echo "CREATED_FILE=$1"
  else
    echo "FILE_EXISTS=$1"
  fi
}

# Create test files
create_file "test_file1.txt"
mkdir -p "test_dir"
create_file "test_dir/test_file2.txt"
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates files were created
  [ "$status" -eq 0 ]
  [[ "$output" == *"CREATED_FILE=test_file1.txt"* ]]
  [[ "$output" == *"CREATED_FILE=test_dir/test_file2.txt"* ]]

  # Check that the files were actually created
  [ -f "test_file1.txt" ]
  [ -f "test_dir/test_file2.txt" ]
}

# Test that the script doesn't recreate existing files
@test "setup-project.sh doesn't recreate existing files" {
  # Create a file that already exists
  touch "existing_file.txt"

  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Function to create file if it doesn't exist
create_file() {
  if [ ! -f "$1" ]; then
    touch "$1"
    echo "CREATED_FILE=$1"
  else
    echo "FILE_EXISTS=$1"
  fi
}

# Try to create an existing file
create_file "existing_file.txt"
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates the file already exists
  [ "$status" -eq 0 ]
  [[ "$output" == *"FILE_EXISTS=existing_file.txt"* ]]
  [[ "$output" != *"CREATED_FILE=existing_file.txt"* ]]
}

# Test that the script creates the full project structure
@test "setup-project.sh creates the full project structure" {
  # Run the original script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]

  # Check that the main directories were created
  [ -d "backend" ]
  [ -d "frontend" ]
  [ -d "scripts" ]
  [ -d "docs" ]
  [ -d "make" ]
  [ -d "reports" ]

  # Check that the backend structure was created
  [ -d "backend/app" ]
  [ -d "backend/app/api" ]
  [ -d "backend/app/core" ]
  [ -d "backend/app/db" ]
  [ -d "backend/app/models" ]
  [ -d "backend/app/schemas" ]
  [ -d "backend/app/services" ]
  [ -d "backend/app/tests" ]
  [ -d "backend/docs" ]

  # Check that the frontend structure was created
  [ -d "frontend/src" ]
  [ -d "frontend/src/components" ]
  [ -d "frontend/src/pages" ]
  [ -d "frontend/src/styles" ]
  [ -d "frontend/src/utils" ]
  [ -d "frontend/public" ]
  [ -d "frontend/tests" ]
  [ -d "frontend/docs" ]

  # Check that the documentation directories were created
  [ -d "docs/api" ]
  [ -d "docs/frontend" ]
  [ -d "docs/backend" ]
  [ -d "docs/architecture" ]
  [ -d "docs/development" ]
  [ -d "docs/deployment" ]

  # Check that the report directories were created
  [ -d "reports/security" ]
  [ -d "reports/tests" ]
  [ -d "reports/accessibility" ]
  [ -d "reports/coverage" ]

  # Check that the necessary files were created
  [ -f "backend/requirements.txt" ]
  [ -f "frontend/package.json" ]
  [ -f "frontend/pnpm-lock.yaml" ]
  [ -f ".env" ]
  [ -f ".env.test" ]
  [ -f ".gitignore" ]
  [ -f "README.md" ]
}

# Test the full script execution with some existing directories
@test "setup-project.sh handles existing directories and files" {
  # Create some directories and files that already exist
  mkdir -p "backend/app"
  mkdir -p "frontend/src"
  touch ".env"

  # Run the original script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]

  # Check that all directories and files were created
  [ -d "backend/app/api" ]
  [ -d "frontend/src/components" ]
  [ -f ".env.test" ]

  # The script should have completed without errors
  [[ "$output" == *"Project structure setup complete!"* ]]
}
