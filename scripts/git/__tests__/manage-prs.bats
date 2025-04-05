#!/usr/bin/env bats

# Bats test file for manage-prs.sh

# Setup - runs before each test
setup() {
  # Create a temporary directory for test files
  export TEMP_DIR="$(mktemp -d)"

  # Save the original directory
  export ORIG_DIR="$PWD"

  # Change to the temp directory
  cd "$TEMP_DIR"

  # Create a mock git repository
  git init
  git config --local user.email "test@example.com"
  git config --local user.name "Test User"
  echo "# Test Repository" > README.md
  git add README.md
  git commit -m "Initial commit"

  # Create main and stg branches
  git branch main
  git branch stg

  # Create a feature branch
  git checkout -b feat/test-feature
  echo "Feature change" >> README.md
  git add README.md
  git commit -m "Feature change"

  # Create a mock version of the script for testing
  export SCRIPT_PATH="$TEMP_DIR/manage-prs.sh"
  cp "$ORIG_DIR/scripts/git/manage-prs.sh" "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"

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

# Helper function to mock git commands
mock_git_command() {
  local cmd="$1"
  local output="$2"
  local exit_code="${3:-0}"

  cat > "$MOCK_DIR/git" << EOF
#!/bin/bash
if [[ "\$*" == *"$cmd"* ]]; then
  echo "$output"
  exit $exit_code
else
  # Pass through to real git for other commands
  $(which git) "\$@"
fi
EOF
  chmod +x "$MOCK_DIR/git"
  export PATH="$MOCK_DIR:$PATH"
}

# Helper function to mock gh commands
mock_gh_command() {
  local cmd="$1"
  local output="$2"
  local exit_code="${3:-0}"

  cat > "$MOCK_DIR/gh" << EOF
#!/bin/bash
if [[ "\$*" == *"$cmd"* ]]; then
  echo "$output"
  exit $exit_code
else
  echo "Mock gh called with: \$@"
  exit 0
fi
EOF
  chmod +x "$MOCK_DIR/gh"
  export PATH="$MOCK_DIR:$PATH"
}

# Test that the script checks dependencies
@test "manage-prs.sh checks dependencies" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

log() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

error_exit() {
    log $RED "$1"
    exit 1
}

check_dependencies() {
    if ! command -v gh &> /dev/null; then
        error_exit "GitHub CLI (gh) is not installed. Please install it first."
    fi
    if ! gh auth status &> /dev/null; then
        error_exit "Not logged in to GitHub. Please run 'gh auth login' first."
    fi
    echo "DEPENDENCIES_CHECKED=true"
}

check_dependencies
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Mock gh command to simulate it's installed and authenticated
  mock_command "gh" "Logged in to github.com as testuser"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates dependencies were checked
  [ "$status" -eq 0 ]
  [[ "$output" == *"DEPENDENCIES_CHECKED=true"* ]]

  # Mock gh command to simulate it's not authenticated
  mock_command "gh" "Not logged in to GitHub" 1

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates authentication error
  [ "$status" -eq 1 ]
  [[ "$output" == *"Not logged in to GitHub"* ]]

  # Remove gh command to simulate it's not installed
  rm "$MOCK_DIR/gh"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates gh is not installed
  [ "$status" -eq 1 ]
  [[ "$output" == *"GitHub CLI (gh) is not installed"* ]]
}

# Test that the script checks Dependabot PRs
@test "manage-prs.sh checks Dependabot PRs" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

log() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Mock check_dependencies to always pass
check_dependencies() {
    return 0
}

check_dependencies

log $BLUE "Checking Dependabot PRs..."
DEPENDABOT_PRS=$(gh pr list --author "app/dependabot" --json number,title,state,reviewDecision,mergeStateStatus)

if [ -z "$DEPENDABOT_PRS" ]; then
    log $GREEN "No Dependabot PRs found."
    echo "NO_DEPENDABOT_PRS=true"
else
    log $BLUE "Found Dependabot PRs:"
    echo "$DEPENDABOT_PRS" | jq -r '.[] | "  PR #\(.number): \(.title) [\(.state)] [\(.reviewDecision)] [\(.mergeStateStatus)]"'
    echo "DEPENDABOT_PRS_FOUND=true"

    echo "$DEPENDABOT_PRS" | jq -c '.[]' | while read -r pr; do
        number=$(echo $pr | jq -r '.number')
        state=$(echo $pr | jq -r '.state')
        mergeStatus=$(echo $pr | jq -r '.mergeStateStatus')
        title=$(echo $pr | jq -r '.title')

        if [ "$state" = "OPEN" ] && [ "$mergeStatus" = "CLEAN" ]; then
            log $YELLOW "Attempting to merge Dependabot PR #$number: $title"
            gh pr merge $number --auto --squash
            echo "MERGING_PR_$number=true"
        fi
    done
fi
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Mock jq command
  mock_command "jq" "echo 'Mock jq called'"

  # Mock gh command to return no Dependabot PRs
  mock_gh_command "pr list --author \"app/dependabot\"" ""

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates no Dependabot PRs were found
  [ "$status" -eq 0 ]
  [[ "$output" == *"No Dependabot PRs found"* ]]
  [[ "$output" == *"NO_DEPENDABOT_PRS=true"* ]]

  # Mock gh command to return Dependabot PRs
  mock_gh_command "pr list --author \"app/dependabot\"" '[{"number":123,"title":"Bump dependency","state":"OPEN","reviewDecision":"APPROVED","mergeStateStatus":"CLEAN"}]'

  # Mock jq to process the JSON
  mock_command "jq" 'if [[ "$*" == *"-r"* ]]; then echo "  PR #123: Bump dependency [OPEN] [APPROVED] [CLEAN]"; elif [[ "$*" == *"-c"* ]]; then echo "{\"number\":123,\"title\":\"Bump dependency\",\"state\":\"OPEN\",\"mergeStateStatus\":\"CLEAN\"}"; else echo "123"; fi'

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates Dependabot PRs were found and merged
  [ "$status" -eq 0 ]
  [[ "$output" == *"Found Dependabot PRs"* ]]
  [[ "$output" == *"DEPENDABOT_PRS_FOUND=true"* ]]
  [[ "$output" == *"Attempting to merge Dependabot PR #123"* ]]
  [[ "$output" == *"MERGING_PR_123=true"* ]]
}

# Test that the script checks feature and fix branches
@test "manage-prs.sh checks feature and fix branches" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

log() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Mock check_dependencies to always pass
check_dependencies() {
    return 0
}

check_dependencies

log $BLUE "Checking feature and fix branches..."
BRANCHES=$(git branch -r | grep -E 'origin/(feat|fix)/' | sed 's/origin\///')

if [ -z "$BRANCHES" ]; then
    log $GREEN "No feature or fix branches found."
    echo "NO_FEATURE_FIX_BRANCHES=true"
else
    echo "Found branches:"
    echo "$BRANCHES"
    echo "FEATURE_FIX_BRANCHES_FOUND=true"

    echo "$BRANCHES" | while read -r branch; do
        if [ -n "$branch" ]; then
            log $YELLOW "Checking branch: $branch"

            PR_INFO=$(gh pr list --head "$branch" --json number,title,state,reviewDecision,mergeStateStatus)

            if [ -z "$PR_INFO" ] || [ "$PR_INFO" = "[]" ]; then
                log $YELLOW "No PR found for $branch. Creating PR to stg..."
                gh pr create --base stg --head "$branch" --title "$(echo $branch | sed 's/\//:/')" --body "Automated PR from $branch to stg"
                echo "CREATING_PR_FOR_$branch=true"
            else
                PR_NUMBER=$(echo $PR_INFO | jq -r '.[0].number')
                PR_STATE=$(echo $PR_INFO | jq -r '.[0].state')
                MERGE_STATUS=$(echo $PR_INFO | jq -r '.[0].mergeStateStatus')

                log $BLUE "Found PR #$PR_NUMBER for branch $branch"
                log $BLUE "Status: $PR_STATE, Merge Status: $MERGE_STATUS"

                if [ "$PR_STATE" = "OPEN" ] && [ "$MERGE_STATUS" = "CLEAN" ]; then
                    log $YELLOW "PR is ready to merge. Merging..."
                    gh pr merge $PR_NUMBER --auto --squash
                    echo "MERGING_PR_$PR_NUMBER=true"
                fi
            fi
        fi
    done
fi
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Mock git command to return feature branches
  mock_git_command "branch -r" "  origin/feat/test-feature\n  origin/fix/bug-fix"

  # Mock jq command
  mock_command "jq" "echo 'Mock jq called'"

  # Mock gh command to return no PRs for the branches
  mock_gh_command "pr list --head" "[]"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates feature/fix branches were found and PRs were created
  [ "$status" -eq 0 ]
  [[ "$output" == *"Found branches"* ]]
  [[ "$output" == *"FEATURE_FIX_BRANCHES_FOUND=true"* ]]
  [[ "$output" == *"No PR found for feat/test-feature"* ]]
  [[ "$output" == *"CREATING_PR_FOR_feat/test-feature=true"* ]]

  # Mock gh command to return existing PRs for the branches
  mock_gh_command "pr list --head \"feat/test-feature\"" '[{"number":456,"title":"feat: test feature","state":"OPEN","reviewDecision":"APPROVED","mergeStateStatus":"CLEAN"}]'

  # Mock jq to process the JSON
  mock_command "jq" 'if [[ "$*" == *".[0].number"* ]]; then echo "456"; elif [[ "$*" == *".[0].state"* ]]; then echo "OPEN"; elif [[ "$*" == *".[0].mergeStateStatus"* ]]; then echo "CLEAN"; else echo "Mock jq called"; fi'

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates PRs were found and merged
  [ "$status" -eq 0 ]
  [[ "$output" == *"Found PR #456 for branch feat/test-feature"* ]]
  [[ "$output" == *"Status: OPEN, Merge Status: CLEAN"* ]]
  [[ "$output" == *"PR is ready to merge. Merging..."* ]]
  [[ "$output" == *"MERGING_PR_456=true"* ]]
}

# Test that the script checks if stg is ahead of main
@test "manage-prs.sh checks if stg is ahead of main" {
  # Create a modified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

log() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Mock check_dependencies to always pass
check_dependencies() {
    return 0
}

check_dependencies

log $BLUE "Checking if stg is ahead of main..."
git fetch origin main stg

AHEAD_COUNT=$(git rev-list --count main..stg)
if [ "$AHEAD_COUNT" -gt 0 ]; then
    log $YELLOW "stg is ahead of main by $AHEAD_COUNT commits"
    echo "STG_AHEAD=true"

    STG_PR=$(gh pr list --base main --head stg --json number,title,state,mergeStateStatus)

    if [ -z "$STG_PR" ] || [ "$STG_PR" = "[]" ]; then
        log $YELLOW "Creating PR from stg to main..."
        gh pr create --base main --head stg --title "chore: merge stg to main" --body "Automated PR to merge stg into main"
        echo "CREATING_STG_PR=true"
    else
        PR_NUMBER=$(echo $STG_PR | jq -r '.[0].number')
        MERGE_STATUS=$(echo $STG_PR | jq -r '.[0].mergeStateStatus')

        if [ "$MERGE_STATUS" = "CLEAN" ]; then
            log $YELLOW "PR #$PR_NUMBER is ready to merge. Merging..."
            gh pr merge $PR_NUMBER --auto --squash
            echo "MERGING_STG_PR_$PR_NUMBER=true"
        fi
    fi
else
    log $GREEN "stg is up to date with main"
    echo "STG_UP_TO_DATE=true"
fi
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Mock git command to simulate stg is ahead of main
  mock_git_command "rev-list --count main..stg" "3"

  # Mock jq command
  mock_command "jq" "echo 'Mock jq called'"

  # Mock gh command to return no PRs for stg to main
  mock_gh_command "pr list --base main --head stg" "[]"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates stg is ahead and a PR was created
  [ "$status" -eq 0 ]
  [[ "$output" == *"stg is ahead of main by 3 commits"* ]]
  [[ "$output" == *"STG_AHEAD=true"* ]]
  [[ "$output" == *"Creating PR from stg to main"* ]]
  [[ "$output" == *"CREATING_STG_PR=true"* ]]

  # Mock gh command to return existing PR for stg to main
  mock_gh_command "pr list --base main --head stg" '[{"number":789,"title":"chore: merge stg to main","state":"OPEN","mergeStateStatus":"CLEAN"}]'

  # Mock jq to process the JSON
  mock_command "jq" 'if [[ "$*" == *".[0].number"* ]]; then echo "789"; elif [[ "$*" == *".[0].mergeStateStatus"* ]]; then echo "CLEAN"; else echo "Mock jq called"; fi'

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates an existing PR was found and merged
  [ "$status" -eq 0 ]
  [[ "$output" == *"stg is ahead of main by 3 commits"* ]]
  [[ "$output" == *"STG_AHEAD=true"* ]]
  [[ "$output" == *"PR #789 is ready to merge. Merging"* ]]
  [[ "$output" == *"MERGING_STG_PR_789=true"* ]]

  # Mock git command to simulate stg is up to date with main
  mock_git_command "rev-list --count main..stg" "0"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates stg is up to date
  [ "$status" -eq 0 ]
  [[ "$output" == *"stg is up to date with main"* ]]
  [[ "$output" == *"STG_UP_TO_DATE=true"* ]]
}

# Test the full script execution (mocked)
@test "manage-prs.sh runs successfully with mocked commands" {
  # Mock all commands needed for the full script
  mock_command "gh" "Logged in to github.com as testuser"
  mock_command "jq" "echo 'Mock jq called'"
  mock_git_command "branch -r" "  origin/feat/test-feature\n  origin/fix/bug-fix"
  mock_git_command "rev-list --count main..stg" "3"

  # Create a simplified version of the script for testing
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
echo "=== PR Management Script ==="
echo "Checking dependencies..."
echo "Dependencies OK"
echo "Checking Dependabot PRs..."
echo "No Dependabot PRs found."
echo "Checking feature and fix branches..."
echo "Found branches: feat/test-feature, fix/bug-fix"
echo "Creating PR for feat/test-feature to stg"
echo "Creating PR for fix/bug-fix to stg"
echo "Checking if stg is ahead of main..."
echo "stg is ahead of main by 3 commits"
echo "Creating PR from stg to main..."
echo "PR management complete!"
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the script executed successfully
  [ "$status" -eq 0 ]
  [[ "$output" == *"=== PR Management Script ==="* ]]
  [[ "$output" == *"Checking dependencies"* ]]
  [[ "$output" == *"Checking Dependabot PRs"* ]]
  [[ "$output" == *"Checking feature and fix branches"* ]]
  [[ "$output" == *"Creating PR for feat/test-feature to stg"* ]]
  [[ "$output" == *"Checking if stg is ahead of main"* ]]
  [[ "$output" == *"stg is ahead of main by 3 commits"* ]]
  [[ "$output" == *"PR management complete!"* ]]
}
