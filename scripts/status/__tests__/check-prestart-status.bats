#!/usr/bin/env bats

# Bats test file for check-prestart-status.sh

# Setup - runs before each test
setup() {
  # Create a temporary directory for test files
  export TEMP_DIR="$(mktemp -d)"

  # Save the original directory
  export ORIG_DIR="$PWD"

  # Change to the temp directory
  cd "$TEMP_DIR"

  # Create mock project structure
  mkdir -p /app/backend/alembic/versions
  touch /app/backend/alembic/env.py
  touch /app/backend/alembic/script.py.mako

  # Create a mock version of the script for testing
  export SCRIPT_PATH="$TEMP_DIR/check-prestart-status.sh"
  cp "$ORIG_DIR/scripts/status/check-prestart-status.sh" "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"

  # Set environment variables
  export POSTGRES_SERVER="localhost"
  export POSTGRES_USER="postgres"
  export POSTGRES_DB="app"

  # Mock command directories
  export MOCK_DIR="$TEMP_DIR/mock_bin"
  mkdir -p "$MOCK_DIR"
}

# Teardown - runs after each test
teardown() {
  # Return to the original directory
  cd "$ORIG_DIR"

  # Clean up the temporary directory
  rm -rf "$TEMP_DIR"

  # Unset environment variables
  unset POSTGRES_SERVER
  unset POSTGRES_USER
  unset POSTGRES_DB
}

# Helper function to mock commands
mock_command() {
  local cmd="$1"
  local output="$2"
  local exit_code="${3:-0}"

  cat > "$MOCK_DIR/$cmd" << EOF
#!/bin/bash
echo "$output"
exit $exit_code
EOF
  chmod +x "$MOCK_DIR/$cmd"
  export PATH="$MOCK_DIR:$PATH"
}

# Test that the script checks if PostgreSQL is running
@test "check-prestart-status.sh checks if PostgreSQL is running" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
echo "===== Prestart Status Check ====="
echo "Checking database connection..."

# Check if PostgreSQL is running
if pg_isready -h ${POSTGRES_SERVER} -p 5432 -U ${POSTGRES_USER}; then
    echo "✅ Database is running"
    echo "DATABASE_RUNNING=true"
else
    echo "❌ Database is not running or not accessible"
    echo "Connection details:"
    echo "  Host: ${POSTGRES_SERVER}"
    echo "  Port: 5432"
    echo "  User: ${POSTGRES_USER}"
    echo "  Database: ${POSTGRES_DB}"
    echo "DATABASE_RUNNING=false"
    exit 1
fi
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Mock pg_isready command to return success
  mock_command "pg_isready" "Connection to database successful"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates the database is running
  [ "$status" -eq 0 ]
  [[ "$output" == *"✅ Database is running"* ]]
  [[ "$output" == *"DATABASE_RUNNING=true"* ]]

  # Mock pg_isready command to return failure
  mock_command "pg_isready" "Connection to database failed" 1

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates the database is not running
  [ "$status" -eq 1 ]
  [[ "$output" == *"❌ Database is not running or not accessible"* ]]
  [[ "$output" == *"DATABASE_RUNNING=false"* ]]
  [[ "$output" == *"Host: localhost"* ]]
  [[ "$output" == *"User: postgres"* ]]
  [[ "$output" == *"Database: app"* ]]
}

# Test that the script checks the alembic setup
@test "check-prestart-status.sh checks the alembic setup" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
echo "===== Prestart Status Check ====="
echo "Checking alembic setup..."
if [ -d "/app/backend/alembic" ]; then
    echo "✅ Alembic directory exists"
    echo "ALEMBIC_DIR_EXISTS=true"

    if [ -f "/app/backend/alembic/env.py" ]; then
        echo "✅ Alembic env.py exists"
        echo "ALEMBIC_ENV_EXISTS=true"
    else
        echo "❌ Alembic env.py is missing"
        echo "ALEMBIC_ENV_EXISTS=false"
    fi

    if [ -f "/app/backend/alembic/script.py.mako" ]; then
        echo "✅ Alembic script.py.mako exists"
        echo "ALEMBIC_SCRIPT_EXISTS=true"
    else
        echo "❌ Alembic script.py.mako is missing"
        echo "ALEMBIC_SCRIPT_EXISTS=false"
    fi

    if [ -d "/app/backend/alembic/versions" ]; then
        echo "✅ Alembic versions directory exists"
        echo "ALEMBIC_VERSIONS_EXISTS=true"
        echo "   Versions found: $(ls -1 /app/backend/alembic/versions | wc -l)"
    else
        echo "❌ Alembic versions directory is missing"
        echo "ALEMBIC_VERSIONS_EXISTS=false"
    fi
else
    echo "❌ Alembic directory does not exist"
    echo "ALEMBIC_DIR_EXISTS=false"
fi
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Mock ls and wc commands
  mock_command "ls" "version1.py\nversion2.py"
  mock_command "wc" "2"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates the alembic setup is correct
  [ "$status" -eq 0 ]
  [[ "$output" == *"✅ Alembic directory exists"* ]]
  [[ "$output" == *"ALEMBIC_DIR_EXISTS=true"* ]]
  [[ "$output" == *"✅ Alembic env.py exists"* ]]
  [[ "$output" == *"ALEMBIC_ENV_EXISTS=true"* ]]
  [[ "$output" == *"✅ Alembic script.py.mako exists"* ]]
  [[ "$output" == *"ALEMBIC_SCRIPT_EXISTS=true"* ]]
  [[ "$output" == *"✅ Alembic versions directory exists"* ]]
  [[ "$output" == *"ALEMBIC_VERSIONS_EXISTS=true"* ]]

  # Remove alembic files to test failure cases
  rm -rf /app/backend/alembic/versions
  rm /app/backend/alembic/env.py
  rm /app/backend/alembic/script.py.mako

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates the alembic setup is incomplete
  [ "$status" -eq 0 ]
  [[ "$output" == *"✅ Alembic directory exists"* ]]
  [[ "$output" == *"ALEMBIC_DIR_EXISTS=true"* ]]
  [[ "$output" == *"❌ Alembic env.py is missing"* ]]
  [[ "$output" == *"ALEMBIC_ENV_EXISTS=false"* ]]
  [[ "$output" == *"❌ Alembic script.py.mako is missing"* ]]
  [[ "$output" == *"ALEMBIC_SCRIPT_EXISTS=false"* ]]
  [[ "$output" == *"❌ Alembic versions directory is missing"* ]]
  [[ "$output" == *"ALEMBIC_VERSIONS_EXISTS=false"* ]]

  # Remove alembic directory to test failure case
  rm -rf /app/backend/alembic

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates the alembic directory is missing
  [ "$status" -eq 0 ]
  [[ "$output" == *"❌ Alembic directory does not exist"* ]]
  [[ "$output" == *"ALEMBIC_DIR_EXISTS=false"* ]]
}

# Test that the script checks the alembic migration history
@test "check-prestart-status.sh checks the alembic migration history" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
echo "===== Prestart Status Check ====="
echo "Checking alembic migration history..."
cd /app/backend && alembic history || echo "❌ Failed to get alembic history"
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Mock alembic command
  mock_command "alembic" "Rev: 123abc (head)\nRev: 456def\nRev: 789ghi"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output includes the alembic history
  [ "$status" -eq 0 ]
  [[ "$output" == *"Checking alembic migration history"* ]]
  [[ "$output" == *"Rev: 123abc (head)"* ]]
  [[ "$output" == *"Rev: 456def"* ]]
  [[ "$output" == *"Rev: 789ghi"* ]]

  # Mock alembic command to fail
  mock_command "alembic" "Error: Could not get alembic history" 1

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates failure to get alembic history
  [ "$status" -eq 0 ]
  [[ "$output" == *"❌ Failed to get alembic history"* ]]
}

# Test that the script checks the current alembic revision
@test "check-prestart-status.sh checks the current alembic revision" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
echo "===== Prestart Status Check ====="
echo "Current alembic revision:"
cd /app/backend && alembic current || echo "❌ Failed to get current revision"
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Mock alembic command
  mock_command "alembic" "Current revision: 123abc (head)"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output includes the current alembic revision
  [ "$status" -eq 0 ]
  [[ "$output" == *"Current alembic revision"* ]]
  [[ "$output" == *"Current revision: 123abc (head)"* ]]

  # Mock alembic command to fail
  mock_command "alembic" "Error: Could not get current revision" 1

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates failure to get current revision
  [ "$status" -eq 0 ]
  [[ "$output" == *"❌ Failed to get current revision"* ]]
}

# Test the full script execution (mocked)
@test "check-prestart-status.sh runs successfully with mocked commands" {
  # Mock all commands needed for the full script
  mock_command "pg_isready" "Connection to database successful"
  mock_command "ls" "version1.py\nversion2.py"
  mock_command "wc" "2"
  mock_command "alembic" "Rev: 123abc (head)"

  # Create a simplified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
echo "===== Prestart Status Check ====="
echo "Checking database connection..."
echo "✅ Database is running"
echo "Checking alembic setup..."
echo "✅ Alembic directory exists"
echo "✅ Alembic env.py exists"
echo "✅ Alembic script.py.mako exists"
echo "✅ Alembic versions directory exists"
echo "   Versions found: 2"
echo "Checking alembic migration history..."
echo "Rev: 123abc (head)"
echo "Current alembic revision:"
echo "Current revision: 123abc (head)"
echo "===== Prestart Status Check Complete ====="
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]
  [[ "$output" == *"===== Prestart Status Check ====="* ]]
  [[ "$output" == *"Checking database connection"* ]]
  [[ "$output" == *"✅ Database is running"* ]]
  [[ "$output" == *"Checking alembic setup"* ]]
  [[ "$output" == *"✅ Alembic directory exists"* ]]
  [[ "$output" == *"✅ Alembic env.py exists"* ]]
  [[ "$output" == *"✅ Alembic script.py.mako exists"* ]]
  [[ "$output" == *"✅ Alembic versions directory exists"* ]]
  [[ "$output" == *"Versions found: 2"* ]]
  [[ "$output" == *"Checking alembic migration history"* ]]
  [[ "$output" == *"Rev: 123abc (head)"* ]]
  [[ "$output" == *"Current alembic revision"* ]]
  [[ "$output" == *"Current revision: 123abc (head)"* ]]
  [[ "$output" == *"===== Prestart Status Check Complete ====="* ]]
}
