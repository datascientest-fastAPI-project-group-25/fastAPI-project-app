# CI/CD Workflow

This document describes the CI/CD workflow implemented in this project.

## Overview

The CI/CD pipeline automates the following process:

1. Feature branch -> Auto PR creation to staging
2. PR checks (tests, linting, formatting, security)
3. Merge to staging -> Build and tag Docker images
4. Auto PR creation from staging to main
5. Merge to main -> Retag images with semantic versioning

## Workflow Details

### 1. Feature Branch Development

- Create a feature branch with prefix `feat/` or a fix branch with prefix `fix/`
- Push changes to the branch
- GitHub Actions automatically creates a PR to the `stg` branch

### 2. PR Checks

When a PR is created to the `stg` branch, the following checks are run:
- Linting
- Formatting
- Security scanning
- Tests (backend and frontend)

### 3. Merge to Staging

When a PR is merged to the `stg` branch:
- Docker images are built for both backend and frontend
- Images are tagged with:
  - Git hash and branch type: `ghcr.io/repo-name-backend:<git-hash>-<branch-type>`
  - Staging tag: `ghcr.io/repo-name-backend:stg`
- Images are pushed to GitHub Container Registry (GHCR)
- A PR is automatically created from `stg` to `main`
- The feature branch is deleted

### 4. Merge to Main

When a PR is merged to the `main` branch:
- The staging images are pulled
- Images are retagged with:
  - Semantic version (based on branch type):
    - `feat/` branches trigger a minor version bump (0.1.0 -> 0.2.0)
    - `fix/` branches trigger a patch version bump (0.1.0 -> 0.1.1)
  - Latest tag: `ghcr.io/repo-name-backend:latest`
- The VERSION file is updated with the new version
- A comment is added to the PR with the new version and image details

## Semantic Versioning

The project follows semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes (manually incremented)
- MINOR: New features (automatically incremented for `feat/` branches)
- PATCH: Bug fixes (automatically incremented for `fix/` branches)

## Testing the Workflow Locally

You can test the CI/CD workflow locally using the following command:

```bash
make test-ci-workflow
```

Or test a specific workflow:

```bash
./scripts/test-ci-workflow.sh -w feature-branch-pr.yml -e push -b feat/my-feature
```

## Workflow Files

- `.github/workflows/feature-branch-pr.yml`: Creates PRs from feature branches to staging
- `.github/workflows/pr-checks.yml`: Runs checks on PRs to staging
- `.github/workflows/merge-to-staging.yml`: Builds and pushes images when PRs are merged to staging
- `.github/workflows/merge-to-main.yml`: Retags images when PRs are merged to main
