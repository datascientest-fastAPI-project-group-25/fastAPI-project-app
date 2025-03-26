# GitHub Actions Workflows

## Workflow Organization

### Core Workflows
These workflows manage our branching strategy and core CI/CD processes:

- **branch-protection.yml**: Protects main and dev branches from direct pushes
- **feature-branch-checks.yml**: Runs checks for feature branches
- **fix-branch.yml**: Handles fix branches with optional automerge
- **main-branch.yml**: Main branch production workflow

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
   - feature-branch-checks.yml
   - fix-branch.yml

## Best Practices

1. Always create feature branches for new development
2. Use fix branches for bug fixes
3. Merge to dev first, then to main
4. Ensure all tests pass before merging

## Troubleshooting

If you encounter issues with workflows, check:

1. The workflow logs for detailed error messages
2. The branch protection rules
3. The workflow permissions to ensure they have the necessary access

## Version Control

All workflow files should be version controlled and follow these naming conventions:

- Active workflows: `*.yml`
- Shared components: `_shared/*`
