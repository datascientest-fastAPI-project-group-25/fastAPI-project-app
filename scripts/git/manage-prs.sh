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
}

check_dependencies

log $BLUE "Checking Dependabot PRs..."
DEPENDABOT_PRS=$(gh pr list --author "app/dependabot" --json number,title,state,reviewDecision,mergeStateStatus)

if [ -z "$DEPENDABOT_PRS" ]; then
    log $GREEN "No Dependabot PRs found."
else
    log $BLUE "Found Dependabot PRs:"
    echo "$DEPENDABOT_PRS" | jq -r '.[] | "  PR #\(.number): \(.title) [\(.state)] [\(.reviewDecision)] [\(.mergeStateStatus)]"'

    echo "$DEPENDABOT_PRS" | jq -c '.[]' | while read -r pr; do
        number=$(echo $pr | jq -r '.number')
        state=$(echo $pr | jq -r '.state')
        mergeStatus=$(echo $pr | jq -r '.mergeStateStatus')
        title=$(echo $pr | jq -r '.title')

        if [ "$state" = "OPEN" ] && [ "$mergeStatus" = "CLEAN" ]; then
            log $YELLOW "Attempting to merge Dependabot PR #$number: $title"
            gh pr merge $number --auto --squash
        fi
    done
fi

log $BLUE "\nChecking feature and fix branches..."
BRANCHES=$(git branch -r | grep -E 'origin/(feat|fix)/' | sed 's/origin\///')

if [ -z "$BRANCHES" ]; then
    log $GREEN "No feature or fix branches found."
else
    echo "Found branches:"
    echo "$BRANCHES"

    echo "$BRANCHES" | while read -r branch; do
        if [ -n "$branch" ]; then
            log $YELLOW "\nChecking branch: $branch"

            PR_INFO=$(gh pr list --head "$branch" --json number,title,state,reviewDecision,mergeStateStatus)

            if [ -z "$PR_INFO" ] || [ "$PR_INFO" = "[]" ]; then
                log $YELLOW "No PR found for $branch. Creating PR to stg..."
                gh pr create --base stg --head "$branch" --title "$(echo $branch | sed 's/\//:/')" --body "Automated PR from $branch to stg"
            else
                PR_NUMBER=$(echo $PR_INFO | jq -r '.[0].number')
                PR_STATE=$(echo $PR_INFO | jq -r '.[0].state')
                MERGE_STATUS=$(echo $PR_INFO | jq -r '.[0].mergeStateStatus')

                log $BLUE "Found PR #$PR_NUMBER for branch $branch"
                log $BLUE "Status: $PR_STATE, Merge Status: $MERGE_STATUS"

                if [ "$PR_STATE" = "OPEN" ] && [ "$MERGE_STATUS" = "CLEAN" ]; then
                    log $YELLOW "PR is ready to merge. Merging..."
                    gh pr merge $PR_NUMBER --auto --squash
                fi
            fi
        fi
    done
fi

log $BLUE "\nChecking if stg is ahead of main..."
git fetch origin main stg

AHEAD_COUNT=$(git rev-list --count main..stg)
if [ "$AHEAD_COUNT" -gt 0 ]; then
    log $YELLOW "stg is ahead of main by $AHEAD_COUNT commits"

    STG_PR=$(gh pr list --base main --head stg --json number,title,state,mergeStateStatus)

    if [ -z "$STG_PR" ] || [ "$STG_PR" = "[]" ]; then
        log $YELLOW "Creating PR from stg to main..."
        gh pr create --base main --head stg --title "chore: merge stg to main" --body "Automated PR to merge stg into main"
    else
        PR_NUMBER=$(echo $STG_PR | jq -r '.[0].number')
        MERGE_STATUS=$(echo $STG_PR | jq -r '.[0].mergeStateStatus')

        if [ "$MERGE_STATUS" = "CLEAN" ]; then
            log $YELLOW "PR #$PR_NUMBER is ready to merge. Merging..."
            gh pr merge $PR_NUMBER --auto --squash
        fi
    fi
else
    log $GREEN "stg is up to date with main"
fi

log $GREEN "\nPR management complete!"
