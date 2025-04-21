# Version Management

This document explains how version management works in this repository and how to avoid merge conflicts with the VERSION file.

## Overview

This repository uses semantic versioning (SemVer) for managing versions. The version is stored in two places:

1. **VERSION file**: Used for Docker image tagging and Helm chart versioning
2. **package.json**: Used for npm package versioning and semantic-release

The version is automatically bumped based on the type of changes being made:

- **Major version** (X.0.0): Breaking changes (branches with "breaking" or "!" in the name)
- **Minor version** (0.X.0): New features (branches starting with "feat/")
- **Patch version** (0.0.X): Bug fixes and other changes (branches starting with "fix/")

## Automatic Version Bumping

Version bumping happens automatically at two points in the workflow:

1. **When opening a PR to the `stg` branch**:
   - The VERSION file is bumped based on the branch name
   - package.json is synchronized with the VERSION file
   - The PR title is updated to include the new version

2. **When merging a PR to the `main` branch** (except for stg → main PRs):
   - package.json is bumped based on the branch name
   - VERSION file is synchronized with package.json
   - A GitHub Release is created with the new version

## Automatic Conflict Resolution

To avoid merge conflicts in the VERSION file, we've implemented a custom Git merge driver that automatically resolves conflicts by keeping the higher version number.

### Setup

To set up the custom merge driver, run the following command:

```bash
./scripts/version-management/setup-version-merge.sh
```

This only needs to be done once per local repository.

### How It Works

1. The `.gitattributes` file specifies that the VERSION file should use a custom merge driver called `version-merge`.
2. The `scripts/version-management/version-merge.sh` script implements the merge driver logic, which:
   - Compares the version numbers from both branches
   - Keeps the higher version number
   - Resolves the conflict automatically

### Manual Conflict Resolution

If you encounter a merge conflict in the VERSION file and haven't set up the custom merge driver, you should:

1. Always keep the higher version number
2. If the versions are equal, keep the current branch's version

## Version Synchronization

To ensure that the VERSION file and package.json always have the same version, we've implemented a synchronization script:

```bash
# Sync VERSION file to package.json
node scripts/version-management/sync-versions.js to-package

# Sync package.json to VERSION file
node scripts/version-management/sync-versions.js to-version

# Automatically determine which file has the higher version and sync accordingly
node scripts/version-management/sync-versions.js auto
```

This script is automatically run in the CI/CD workflows, but you can also run it manually if needed.

## Best Practices

1. **Set up the custom merge driver** to avoid manual conflict resolution
2. **Don't manually edit the VERSION file** unless absolutely necessary
3. **Use conventional commit messages** to ensure proper version bumping
4. If you must manually bump the version, always increment it (never decrement)
5. Use the sync script if you notice that the VERSION file and package.json have different versions
