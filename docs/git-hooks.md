# Git Hooks with Lefthook

This project uses [Lefthook](https://github.com/evilmartians/lefthook) to manage Git hooks for code quality enforcement.

## What is Lefthook?

Lefthook is a fast and powerful Git hooks manager that helps maintain code quality by running checks before commits and pushes. It's faster and more flexible than alternatives like pre-commit.

## Features

Our Lefthook configuration provides:

- **Pre-commit hooks**:
  - Code formatting with Black
  - Linting and auto-fixing with Ruff
  - Security scanning with Bandit
  - Trailing whitespace removal
  - YAML validation
  - Merge conflict detection

- **Pre-push hooks**:
  - Running tests with pytest

- **Commit message validation**:
  - Enforcing conventional commit format

## Setup

To set up Lefthook in your development environment:

```bash
# Make the setup script executable
chmod +x scripts/setup-lefthook.sh

# Run the setup script
./scripts/setup-lefthook.sh
```

## Manual Usage

You can manually run the hooks:

```bash
# Run all pre-commit hooks
lefthook run pre-commit

# Run all pre-push hooks
lefthook run pre-push

# Run a specific hook
lefthook run pre-commit --only black
```

## Configuration

The Lefthook configuration is stored in `lefthook.yml` at the root of the project. You can modify this file to add, remove, or customize hooks.

## Skipping Hooks

In rare cases when you need to bypass the hooks:

```bash
# Skip all hooks for a commit
git commit --no-verify -m "Your message"

# Skip specific hooks
LEFTHOOK=0 git commit -m "Your message"
```

**Note**: Skipping hooks should be done only in exceptional circumstances, as it bypasses important code quality checks.
