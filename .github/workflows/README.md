# GitHub Actions Workflows

## Current Status

All workflows have been temporarily disabled (renamed with `.disabled` extension) as part of a systematic debugging process.

## Restoration Plan

We will re-enable workflows one by one through separate PRs to identify which workflow(s) may be causing issues.

## How to Re-enable a Workflow

Use the `enable-workflow.sh` script in the root directory:

```bash
./enable-workflow.sh .github/workflows/workflow-name.yml.disabled
```

## Workflow Dependencies

When re-enabling workflows, consider these dependencies:

1. Core workflows:

   - branch-protection.yml
   - main-branch.yml
   - feature-branch.yml
   - fix-branch.yml

2. Support workflows:

   - pr-workflow.yml
   - push-to-ghcr.yml
   - auto-pr.yml

3. CI/CD workflows:

   - testing/\*
   - ci/\*
   - deploy/\*

4. Utility workflows:
   - latest-changes.yml

## Shared Resources

The `_shared` directory contains reusable workflow components that may be referenced by multiple workflows.
