# Branching Strategy Documentation

## Overview

This project follows a structured branching strategy that enforces best practices through Git hooks and GitHub Actions. The strategy is designed to:

- Protect the main branch from direct pushes
- Standardize branch naming conventions
- Automate versioning based on branch types
- Streamline the development workflow

## Branch Types

### Main Branch (`main`)

- The production-ready branch
- Protected from direct pushes
- Only accepts changes through pull requests
- When code is merged to main, it triggers:
  - Full test suite
  - Semantic versioning
  - Production deployment

### Feature Branches (`feat/*`)

- Used for new features and enhancements
- Created from the main branch
- Triggers:
  - Fast tests
  - Staging deployment
- When merged to main:
  - Increments the minor version (e.g., 1.0.0 → 1.1.0)

### Fix Branches (`fix/*`)

- Used for bug fixes and patches
- Created from the main branch
- Can include `-automerge` suffix for automatic merging
- Triggers:
  - Targeted tests
- When merged to main:
  - Increments the patch version (e.g., 1.0.0 → 1.0.1)

## Development Workflow

1. **Start from main**:

   - When checking out the main branch, you'll be prompted to create a feature or fix branch
   - Use the interactive CLI tool to create a properly named branch

2. **Make changes**:

   - Commit your changes with meaningful commit messages
   - Push your branch to origin

3. **Pull Request**:

   - GitHub Actions will run tests on your branch
   - Create a pull request to merge into main
   - For fix branches with `-automerge` suffix, merging can be automatic after tests pass

4. **Merge**:
   - After approval and passing tests, your branch will be merged to main
   - Semantic versioning will automatically increment based on branch type

## Tools

### Interactive Branch Creation

We provide an interactive CLI tool to create branches following our naming convention:

```bash
# Run directly
node scripts/create-branch.js

# Or use the npm script
npm run create-branch
```

The tool will:

- Ensure you're up to date with the main branch
- Guide you through selecting a branch type (feature or fix)
- Help you name your branch correctly
- Offer the automerge option for fix branches

### Git Hooks

We use pre-commit to manage Git hooks:

1. **Post-Checkout Hook**:

   - Triggers when checking out the main branch
   - Prompts you to create a feature or fix branch
   - Launches the interactive branch creation tool

2. **Pre-Push Hook**:

   - Prevents direct pushes to the main branch
   - Ensures all changes go through the proper workflow

3. **Commit Message Hook**:
   - Ensures commit messages are meaningful
   - Requires a minimum length for commit messages

### Semantic Versioning

Versioning is handled automatically based on branch types:

- Feature branches increment the minor version (0.1.0 → 0.2.0)
- Fix branches increment the patch version (0.1.0 → 0.1.1)

## Setup

To set up the branching strategy tools:

```bash
# Install dependencies
npm install

# Install Git hooks
pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push
```

## Best Practices

1. **Never work directly on main**:

   - Always create a feature or fix branch
   - Use the interactive CLI tool to ensure proper naming

2. **Use meaningful branch names**:

   - Choose descriptive names that reflect the purpose of your changes
   - Follow the naming convention: `feat/feature-name` or `fix/bug-name`

3. **Write meaningful commit messages**:

   - Clearly describe what your changes do
   - Provide context for why the changes are needed

4. **Use automerge judiciously**:
   - Only enable automerge for simple, low-risk fixes
   - Critical fixes should still be reviewed
