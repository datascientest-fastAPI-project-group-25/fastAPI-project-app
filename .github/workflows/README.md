# GitHub Actions Workflows

## Workflow Organization

Workflows are now organized into subdirectories by function:

- **branch/**: Workflows related to branch operations and protection
- **ci/**: Continuous integration workflows for testing, linting, and security checks
- **utils/**: Utility workflows and scripts for testing and maintenance

### Branch Workflows
These workflows manage our branching strategy and core CI/CD processes:

- **branch/branch-protection.yml**: Protects main and dev branches from direct pushes
- **branch/feature-branch.yml**: Runs checks for feature branches
- **branch/fix-branch.yml**: Handles fix branches with optional automerge
- **branch/main-branch.yml**: Main branch production workflow

## Branch Protection Rules

1. **Protected Branches**:
   - `main`: Only PR merges from `dev` allowed
   - `dev`: Only PR merges from feature branches allowed

2. **Branch Flow**:
   - Feature branches → `dev` → `main`
   - Fix branches → `dev` → `main`

## Workflow Dependencies

1. Core Workflows (must be enabled first):
   - branch-protection.yml
   - main-branch.yml
   - feature-branch.yml
   - fix-branch.yml

## Best Practices

1. Always create feature branches for new development
2. Use fix branches for bug fixes
3. Merge to dev first, then to main
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
