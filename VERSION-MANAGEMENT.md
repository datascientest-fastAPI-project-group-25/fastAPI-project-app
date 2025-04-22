# Version Management

This document explains how version management works in this repository and how to avoid merge conflicts with the VERSION file.

## Automatic Conflict Resolution

To avoid merge conflicts in the VERSION file, we've implemented a custom Git merge driver that automatically resolves conflicts by keeping the higher version number.

### Setup

To set up the custom merge driver, run the following command:

```bash
./scripts/setup-version-merge.sh
```

This only needs to be done once per local repository.

### How It Works

1. The `.gitattributes` file specifies that the VERSION file should use a custom merge driver called `version-merge`.
2. The `scripts/version-merge.sh` script implements the merge driver logic, which:
   - Compares the version numbers from both branches
   - Keeps the higher version number
   - Resolves the conflict automatically

### Manual Conflict Resolution

If you encounter a merge conflict in the VERSION file and haven't set up the custom merge driver, you should:

1. Always keep the higher version number
2. If the versions are equal, keep the current branch's version

## Version Bumping

Version bumping is handled automatically by the CI/CD pipeline based on conventional commit messages:

- `fix:` commits bump the patch version (0.0.X)
- `feat:` commits bump the minor version (0.X.0)
- `feat!:` or `fix!:` commits bump the major version (X.0.0)

## Best Practices

1. **Set up the custom merge driver** to avoid manual conflict resolution
2. **Don't manually edit the VERSION file** unless absolutely necessary
3. **Use conventional commit messages** to ensure proper version bumping
4. If you must manually bump the version, always increment it (never decrement)
