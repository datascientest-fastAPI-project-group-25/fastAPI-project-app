#!/bin/bash

# Script to analyze PRs and GitHub Actions using the GitHub CLI
# This script requires the GitHub CLI (gh) to be installed and authenticated

echo "🔍 Analyzing GitHub PRs and Actions..."
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed or not in PATH."
    echo "Please install it from https://cli.github.com/ and authenticate with 'gh auth login'"
    exit 1
fi

# Check if authenticated with GitHub
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub."
    echo "Please run 'gh auth login' to authenticate."
    exit 1
fi

# Get repository information
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "📊 Repository: $REPO"
echo ""

# List open PRs
echo "📋 Open Pull Requests:"
gh pr list --state open
echo ""

# List recent closed PRs
echo "📋 Recently Closed Pull Requests (last 5):"
gh pr list --state closed --limit 5
echo ""

# List recent workflow runs
echo "🔄 Recent Workflow Runs (last 10):"
gh run list --limit 10
echo ""

# List branch protection rules
echo "🔒 Branch Protection Rules:"
gh api repos/$REPO/branches?protected=true --jq '.[].name'
echo ""

# Provide instructions for disabling branch protection
echo "ℹ️ To disable branch protection for emergency pushes, run:"
echo "  ./scripts/disable-branch-protection.sh"
echo ""
echo "ℹ️ To force push to a protected branch (use with caution!):"
echo "  git push --force-with-lease origin <branch>"
echo ""
echo "ℹ️ To skip GitHub Actions workflows when pushing:"
echo "  git push -o ci.skip"
echo ""
echo "✅ Analysis complete!"
