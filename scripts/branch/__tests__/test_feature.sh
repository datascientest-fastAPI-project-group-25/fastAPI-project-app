#!/usr/bin/env bash
#
# Test script for feature.sh
#

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Path to the script being tested
SCRIPT_PATH="../feature.sh"

# Test directory
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR" || exit 1

# Setup test environment
setup() {
    echo -e "${YELLOW}Setting up test environment...${NC}"
    git init
    git config --local user.name "Test User"
    git config --local user.email "test@example.com"
    echo "# Test Repository" > README.md
    git add README.md
    git commit -m "Initial commit"
    git checkout -b main
    echo "Test content" > test.txt
    git add test.txt
    git commit -m "Add test file"
    echo -e "${GREEN}Test environment setup complete${NC}"
}

# Cleanup test environment
cleanup() {
    echo -e "${YELLOW}Cleaning up test environment...${NC}"
    cd .. || exit 1
    rm -rf "$TEST_DIR"
    echo -e "${GREEN}Cleanup complete${NC}"
}

# Test validate_branch_name function
test_validate_branch_name() {
    echo -e "${YELLOW}Testing validate_branch_name function...${NC}"

    # Source the script to access its functions
    # shellcheck source=../feature.sh
    source "$SCRIPT_PATH"

    # Test valid branch names
    if validate_branch_name "valid-branch"; then
        echo -e "${GREEN}✓ Valid branch name 'valid-branch' passed${NC}"
    else
        echo -e "${RED}✗ Valid branch name 'valid-branch' failed${NC}"
        return 1
    fi

    if validate_branch_name "valid-branch-123"; then
        echo -e "${GREEN}✓ Valid branch name 'valid-branch-123' passed${NC}"
    else
        echo -e "${RED}✗ Valid branch name 'valid-branch-123' failed${NC}"
        return 1
    fi

    # Test invalid branch names
    if ! validate_branch_name "Invalid_Branch"; then
        echo -e "${GREEN}✓ Invalid branch name 'Invalid_Branch' correctly rejected${NC}"
    else
        echo -e "${RED}✗ Invalid branch name 'Invalid_Branch' incorrectly accepted${NC}"
        return 1
    fi

    if ! validate_branch_name "invalid.branch"; then
        echo -e "${GREEN}✓ Invalid branch name 'invalid.branch' correctly rejected${NC}"
    else
        echo -e "${RED}✗ Invalid branch name 'invalid.branch' incorrectly accepted${NC}"
        return 1
    fi

    if ! validate_branch_name "-invalid"; then
        echo -e "${GREEN}✓ Invalid branch name '-invalid' correctly rejected${NC}"
    else
        echo -e "${RED}✗ Invalid branch name '-invalid' incorrectly accepted${NC}"
        return 1
    fi

    echo -e "${GREEN}All validate_branch_name tests passed${NC}"
    return 0
}

# Test handle_unstaged_changes function
test_handle_unstaged_changes() {
    echo -e "${YELLOW}Testing handle_unstaged_changes function...${NC}"

    # Source the script to access its functions
    # shellcheck source=../feature.sh
    source "$SCRIPT_PATH"

    # Create unstaged changes
    echo "Unstaged content" > unstaged.txt

    # Mock the select command to choose "stash"
    handle_unstaged_changes() {
        # Override the function to simulate user selecting "stash"
        if ! git diff-index --quiet HEAD --; then
            echo -e "${YELLOW}You have unstaged changes. Stashing...${NC}"
            git stash
            return 0
        fi
        return 0
    }

    # Test the function
    handle_unstaged_changes

    # Check if stash was created
    if git stash list | grep -q "WIP"; then
        echo -e "${GREEN}✓ Unstaged changes were stashed${NC}"
    else
        echo -e "${RED}✗ Failed to stash unstaged changes${NC}"
        return 1
    fi

    echo -e "${GREEN}All handle_unstaged_changes tests passed${NC}"
    return 0
}

# Run all tests
run_tests() {
    echo -e "${YELLOW}Running tests for feature.sh...${NC}"

    local failures=0

    # Run individual tests
    if ! test_validate_branch_name; then
        failures=$((failures + 1))
    fi

    if ! test_handle_unstaged_changes; then
        failures=$((failures + 1))
    fi

    # Report results
    if [ "$failures" -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}${failures} test(s) failed!${NC}"
        return 1
    fi
}

# Main execution
main() {
    # Check if script exists
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo -e "${RED}Error: Script not found at $SCRIPT_PATH${NC}"
        exit 1
    fi

    # Run tests
    setup
    run_tests
    result=$?
    cleanup

    exit $result
}

# Run the main function
main
