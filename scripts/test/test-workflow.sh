#!/usr/bin/env bash
#
# ===================================================================
# GITHUB WORKFLOW TESTER
# ===================================================================
#
# PURPOSE:
#   Tests GitHub Actions workflows locally using act.
#   Validates that workflow files are working correctly before pushing.
#
# USAGE:
#   ./scripts/test/test-workflow.sh [workflow_file] [event_type] [branch]
#   ./scripts/test/test-workflow.sh -w workflow_file -e event_type [-b branch]
#
# ARGUMENTS:
#   workflow_file  Path to the workflow file to test
#   event_type     Event type to trigger (push, pull_request, etc.)
#   branch         Optional branch name to use for the test
#
# OPTIONS:
#   -w, --workflow  Workflow file to test
#   -e, --event     Event type to trigger
#   -b, --branch    Branch name to use for the test
#   -h, --help      Show help message
#
# DEPENDENCIES:
#   - act (GitHub Actions local runner)
#   - Docker
#
# ===================================================================

# Colors for output
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Function to print colored output
log() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Function to check dependencies
check_dependencies() {
    if ! command -v act &> /dev/null; then
        log $RED "Error: 'act' is not installed. Please install it first:"
        log $YELLOW "brew install act"
        exit 1
    fi
}

# Function to validate workflow file
validate_workflow() {
    local workflow_file=$1
    if [ ! -f ".github/workflows/${workflow_file}" ]; then
        log $RED "Error: Workflow file .github/workflows/${workflow_file} not found"
        exit 1
    fi
}

# Function to validate event type
validate_event() {
    local event_type=$1
    case $event_type in
        push|pull_request|workflow_dispatch)
            ;;
        *)
            log $RED "Error: Unsupported event type: ${event_type}"
            log $YELLOW "Supported event types: push, pull_request, workflow_dispatch"
            exit 1
            ;;
    esac
}

# Function to show available workflows
show_workflows() {
    log $BLUE "Available workflows:"
    ls -1 .github/workflows/*.yml | sed 's|.github/workflows/||' | nl
}

# Function to run workflow test
run_workflow_test() {
    local workflow_file=$1
    local event_type=$2
    local branch=$3

    log $BLUE "Testing workflow: ${workflow_file}"
    log $BLUE "Event type: ${event_type}"
    if [ -n "$branch" ]; then
        log $BLUE "Branch: ${branch}"
    fi

    # Prepare act command
    local act_cmd="act ${event_type} -W .github/workflows/${workflow_file}"
    if [ -n "$branch" ]; then
        act_cmd="${act_cmd} -b ${branch}"
    fi

    # Run the workflow
    log $YELLOW "Running workflow test..."
    if eval "$act_cmd"; then
        log $GREEN "Workflow test completed successfully"
    else
        log $RED "Workflow test failed"
        exit 1
    fi
}

# Function to run interactive mode
interactive_mode() {
    show_workflows

    log $YELLOW "Enter the number of the workflow to test:"
    read -r workflow_num
    workflow_file=$(ls -1 .github/workflows/*.yml | sed -n "${workflow_num}p" | xargs basename)

    if [ -z "$workflow_file" ]; then
        log $RED "Invalid selection"
        exit 1
    fi

    log $YELLOW "Select event type:"
    select event in "push" "pull_request" "workflow_dispatch"; do
        if [ -n "$event" ]; then
            break
        fi
    done

    log $YELLOW "Enter branch name (optional, press enter to skip):"
    read -r branch

    run_workflow_test "$workflow_file" "$event" "$branch"
}

# Main script
main() {
    check_dependencies

    # Parse command line arguments
    if [ $# -eq 0 ]; then
        interactive_mode
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                -w|--workflow)
                    workflow_file="$2"
                    shift 2
                    ;;
                -e|--event)
                    event_type="$2"
                    shift 2
                    ;;
                -b|--branch)
                    branch="$2"
                    shift 2
                    ;;
                -h|--help)
                    log $BLUE "Usage: $0 [-w workflow_file] [-e event_type] [-b branch]"
                    log $BLUE "Or run without arguments for interactive mode"
                    exit 0
                    ;;
                *)
                    log $RED "Unknown argument: $1"
                    exit 1
                    ;;
            esac
        done

        if [ -n "$workflow_file" ]; then
            validate_workflow "$workflow_file"
        fi
        if [ -n "$event_type" ]; then
            validate_event "$event_type"
        fi

        run_workflow_test "$workflow_file" "${event_type:-push}" "$branch"
    fi
}

main "$@"
