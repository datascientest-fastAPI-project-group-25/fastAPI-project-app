# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the CI/CD pipeline. The workflows are designed to automate the testing, building, and deployment of the application.

## Workflow Structure

The CI/CD pipeline follows the structure described in [CD_automation.md](../../CD-automation.md) in the root of the repository. Here's a summary of the workflow:

1. **Branch Management**:
   - Start with feature branch (feat or fix)
   - Close feature branch after successful merge to staging

2. **Quality Gates**:
   - Run tests, linting, formatting, and security checks on PR

3. **Promotion Flow**:
   - Auto-create PR from feature branch to staging
   - Merge to staging after passing quality gates
   - Auto-create PR from staging to main
   - Merge to main

4. **Image Management**:
   - Build image after merge to staging
   - Tag with git hash and branch type (feat/fix)
   - Push to GitHub Container Registry
   - After merge to main, retag with semantic version based on branch type:
     - feat → minor version bump
     - fix → patch version bump
   - Push production image to GHCR

## Branch Protection Rules

1. **Protected Branches**:
   - `main`: Only PR merges from `stg` allowed
   - `stg`: Only PR merges from feature branches allowed

2. **Branch Flow**:
   - Feature branches → `stg` → `main`
   - Fix branches → `stg` → `main`

## Workflow Files

- **feature-branch-pr.yml**: Creates a PR from feature branches to staging
- **pr-checks.yml**: Runs quality gates on PRs to staging
- **merge-to-staging.yml**: Builds and pushes images after merge to staging, creates PR to main
- **merge-to-main.yml**: Retags images with semantic version after merge to main
- **ci.yml**: General CI workflow for pushes to main and staging branches
- **tests.yml**: Modular workflow for running tests
- **local-runner.yml**: Workflow for running tests locally using ACR

## Best Practices

1. Always create feature branches for new development
2. Use fix branches for bug fixes
3. Merge to staging first, then to main
4. Ensure all tests pass before merging

## Local Testing with Act

You can test workflows locally using Act:

```bash
# Test a specific workflow
./.github/workflows/test-workflow.sh feature-branch.yml push

# Test a specific job within a workflow
./.github/workflows/test-workflow.sh feature-branch.yml push style-checks
```

The test-workflow.sh script will:
1. Create a .actrc file with recommended settings if it doesn't exist
2. Create a test-event.json file if it doesn't exist
3. Run the workflow with the specified event type

## Troubleshooting

If you encounter issues with workflows, check:

1. The workflow logs for detailed error messages
2. The branch protection rules
3. The workflow permissions to ensure they have the necessary access

## Version Control

All workflow files should be version controlled and follow these naming conventions:

- Active workflows: `*.yml`
- Archived workflows: `archive/*`
