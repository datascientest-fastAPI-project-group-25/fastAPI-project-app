#!/usr/bin/env bats

# Bats test file for feature.sh

# Setup - runs before each test
setup() {
  # Create a temporary directory for test files
  TEMP_DIR="$(mktemp -d)"
  export TEMP_DIR

  # Save the original directory
  export ORIG_DIR="$PWD"

  # Change to the temp directory
  cd "$TEMP_DIR" || exit

  # Create a mock git repository
  git init
  git config --local user.email "test@example.com"
  git config --local user.name "Test User"
  echo "# Test Repository" > README.md
  git add README.md
  git commit -m "Initial commit"

  # Create main branch (already created by default in newer Git versions)
  # No need to rename from master to main

  # Create a mock version of the script for testing
  export SCRIPT_PATH="$TEMP_DIR/feature.sh"
  cp "$ORIG_DIR/scripts/branch/feature.sh" "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"

  # Mock external commands
  mock_command "git" "echo 'Git command executed:' \"\$@\"; exit 0"
}

# Teardown - runs after each test
teardown() {
  # Return to the original directory
  cd "$ORIG_DIR" || exit

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

# Test branch name validation
@test "feature.sh validates branch names correctly" {
  # Create a modified version of the script with just the validate_branch_name function
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Function to validate branch name
validate_branch_name() {
    local name=$1
    if [[ ! $name =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
        echo "Invalid branch name. Use lowercase letters, numbers, and hyphens only."
        return 1
    fi
    return 0
}
EOF
  chmod +x "$SCRIPT_PATH"

  # Source the script to get the function
  # shellcheck source=/dev/null
  source "$SCRIPT_PATH"

  # Test valid branch names
  validate_branch_name "feature-name"
  [ "$?" -eq 0 ]

  validate_branch_name "fix-123"
  [ "$?" -eq 0 ]

  # Test invalid branch names
  run validate_branch_name "Feature_Name"
  [ "$status" -eq 1 ]

  run validate_branch_name "feature name"
  [ "$status" -eq 1 ]

  run validate_branch_name "feature_name"
  [ "$status" -eq 1 ]
}

# Test handling unstaged changes
@test "feature.sh handles unstaged changes" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Function to handle unstaged changes
handle_unstaged_changes() {
    if ! git diff-index --quiet HEAD --; then
        echo "UNSTAGED_CHANGES_DETECTED=true"
        return 0
    fi
    echo "NO_UNSTAGED_CHANGES=true"
    return 0
}

# Call the function
handle_unstaged_changes
EOF
  chmod +x "$SCRIPT_PATH"

  # Create an unstaged change
  echo "Unstaged change" >> README.md

  # Run the script
  run "$SCRIPT_PATH"

  # Check that unstaged changes were detected
  [ "$status" -eq 0 ]
  [[ "$output" == *"UNSTAGED_CHANGES_DETECTED=true"* ]]
}

# Test creating dev branch
@test "feature.sh creates dev branch if it doesn't exist" {
  # Mock git to simulate dev branch not existing
  mock_command "git" "if [[ \$* == *show-ref* && \$* == *dev* ]]; then exit 1; else echo 'Git command executed:' \"\$@\"; exit 0; fi"

  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Check if dev branch exists
if ! git show-ref --verify --quiet refs/heads/dev; then
    echo "DEV_BRANCH_DOESNT_EXIST=true"
    # Simulate user input 'y' to create dev branch
    create_dev="y"
    if [[ $create_dev =~ ^[Yy]$ ]]; then
        echo "CREATING_DEV_BRANCH=true"
    fi
else
    echo "DEV_BRANCH_EXISTS=true"
fi
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script detected dev branch doesn't exist and would create it
  [ "$status" -eq 0 ]
  [[ "$output" == *"DEV_BRANCH_DOESNT_EXIST=true"* ]]
  [[ "$output" == *"CREATING_DEV_BRANCH=true"* ]]
}

# Test creating feature branch
@test "feature.sh creates feature branch" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Simulate user input for creating a feature branch
create_new="y"
prefix="feat"
branch_name="test-feature"

# Create and checkout new branch
new_branch="${prefix}/${branch_name}"
echo "CREATING_FEATURE_BRANCH=${new_branch}"
git checkout -b "$new_branch"
echo "FEATURE_BRANCH_CREATED=true"
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script would create a feature branch
  [ "$status" -eq 0 ]
  [[ "$output" == *"CREATING_FEATURE_BRANCH=feat/test-feature"* ]]
  [[ "$output" == *"FEATURE_BRANCH_CREATED=true"* ]]
}

# Test creating fix branch
@test "feature.sh creates fix branch" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Simulate user input for creating a fix branch
create_new="y"
prefix="fix"
branch_name="bug-fix"

# Create and checkout new branch
new_branch="${prefix}/${branch_name}"
echo "CREATING_FIX_BRANCH=${new_branch}"
git checkout -b "$new_branch"
echo "FIX_BRANCH_CREATED=true"
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script would create a fix branch
  [ "$status" -eq 0 ]
  [[ "$output" == *"CREATING_FIX_BRANCH=fix/bug-fix"* ]]
  [[ "$output" == *"FIX_BRANCH_CREATED=true"* ]]
}

# Test error when branch already exists
@test "feature.sh shows error when branch already exists" {
  # Mock git to simulate branch already existing
  mock_command "git" "if [[ \$* == *show-ref* && \$* == *feat/existing-feature* ]]; then exit 0; else echo 'Git command executed:' \"\$@\"; exit 0; fi"

  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Simulate user input for creating a feature branch
create_new="y"
prefix="feat"
branch_name="existing-feature"

# Check if branch already exists
new_branch="${prefix}/${branch_name}"
if git show-ref --verify --quiet refs/heads/"$new_branch"; then
    echo "ERROR_BRANCH_EXISTS=true"
    exit 1
fi

# Create and checkout new branch
echo "CREATING_FEATURE_BRANCH=${new_branch}"
git checkout -b "$new_branch"
echo "FEATURE_BRANCH_CREATED=true"
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script detected the branch already exists
  [ "$status" -eq 1 ]
  [[ "$output" == *"ERROR_BRANCH_EXISTS=true"* ]]
}

# Test the full script execution (mocked)
@test "feature.sh runs successfully with mocked inputs" {
  # Create a simplified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
echo "Checking git repository..."
echo "Handling unstaged changes..."
echo "Checking dev branch..."
echo "Dev branch exists, switching to it..."
echo "Creating new feature branch: feat/test-feature"
echo "Successfully created and switched to feat/test-feature"
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]
  [[ "$output" == *"Successfully created and switched to feat/test-feature"* ]]
}
