# CI/CD Workflow Improvement Plan

## Current Workflow Observations

### Feature Branch to Staging (`feat/*` -> `stg`)

1. **Version Bumping**:
   - [x] The workflow correctly identifies branch type (`feat/*` vs `fix/*`) and sets the appropriate bump type (minor vs patch).
   - [x] FIXED: The version bump is now applied directly to the branch rather than creating a separate PR.
   - [x] This ensures the VERSION file is always in sync with the actual state.

2. **Docker Image Building and Tagging**:
   - [x] Images are built and pushed to GHCR.
   - [x] FIXED: Images are now tagged with both `stg-<SHORTHASH>` and `stg-<SemVer>` formats.
   - [x] FIXED: The commit comment now includes both tags for better traceability.

3. **GitHub Release Creation**:
   - [x] A pre-release is being created in the app repo with the staging images attached.

4. **Payload Dispatch**:
   - [x] The `trigger-release` job is executed, which calls the `trigger-helm-release.yml` workflow.
   - [x] FIXED: The semantic version and image tags are now correctly passed to the payload.

5. **PR Creation**:
   - [x] A PR from `stg` to `main` is automatically created.

### Staging to Main (`stg` -> `main`)

1. **Docker Image Retagging**:
   - [x] FIXED: The existing `stg-<SHORTHASH>` images are now retagged with the SemVer.
   - [x] FIXED: We no longer rebuild images for production, ensuring the exact same image is promoted.

2. **GitHub Release Creation**:
   - [x] FIXED: The `create-release.yml` workflow is now integrated directly into the production workflow.
   - [x] FIXED: The release now properly links to the retagged staging images that were promoted.

3. **Payload Dispatch**:
   - [x] The `trigger-release` job is executed for production.
   - [x] FIXED: The payload now references the correct retagged images.

## Issues to Fix

1. [x] **Version Bump Process**:
   - [x] FIXED: The version bump is now applied directly to the branch rather than creating a separate PR.
   - [x] This ensures the VERSION file always reflects the current state.

2. [x] **Docker Image Tagging**:
   - [x] FIXED: For `stg`, images are now tagged with both `stg-<SHORTHASH>` AND `stg-<SemVer>`.
   - [x] FIXED: Both tags are stored as outputs for later use.
   - [x] FIXED: The commit comment now includes both tags for better traceability.

3. [x] **Image Retagging for Production**:
   - [x] FIXED: When merging to `main`, we now retag the existing `stg-<SHORTHASH>` images with `<SemVer>` rather than rebuilding.
   - [x] FIXED: This ensures the exact same image that was tested in staging is promoted to production.

4. [x] **GitHub Release Creation**:
   - [x] FIXED: We now create a proper release when merging to `main`.
   - [x] Create a pre-release when merging to `stg`.

5. [x] **Payload Consistency**:
   - [x] FIXED: The payload sent to the release repository now contains the correct SemVer and image references.
   - [x] FIXED: We ensure consistent image references for both `stg` and `prod`.

## Implementation Plan

### 1. Fix Version Bump Process

1. [x] Modified the `build-image.yml` workflow to:
   - [x] Apply the version bump directly to the branch.
   - [x] Remove the PR creation for version bumps.
   - [x] Ensure the VERSION file is committed to the branch.

### 2. Improve Docker Image Tagging

1. [x] Updated the `set-tags` step in `build-image.yml` to:
   - [x] For `stg`, tag images with both `stg-<SHORTHASH>` and `stg-<SemVer>`.
   - [x] Store both tags as outputs for later use.
   - [x] Update the commit comment to include both tags.

2. [x] Updated the `build-stg-image.yml` workflow to:
   - [x] Pass the correct image tags to the trigger-release job.
   - [x] Ensure the semantic version is correctly passed.

### 3. Implement Image Retagging for Production

1. [x] Created a new job in `build-prod-image.yml` to:
   - [x] Identify the corresponding `stg-<SHORTHASH>` image.
   - [x] Retag it with the SemVer without rebuilding.
   - [x] This ensures the exact same image is promoted.

2. [x] Added a GitHub release creation step to:
   - [x] Create a proper release with the retagged images.
   - [x] Include a changelog of changes since the last tag.

3. [x] Updated the trigger-release job to:
   - [x] Use the retagged images.
   - [x] Pass the correct semantic version.

### 4. Fix GitHub Release Creation

1. [x] Create a new workflow or modify `build-stg-image.yml` to:
   - [x] Create a pre-release when merging to `stg`.
   - [x] Include links to the staging Docker images.

### 5. Ensure Payload Consistency

1. [x] Updated the workflows to:
   - [x] Use consistent image references for both `stg` and `prod`.
   - [x] Include the correct SemVer in the payload.

## Next Steps

1. [x] Implement the changes to the version bump process.
2. [x] Implement the Docker image tagging strategy.
3. [x] Implement the image retagging for production.
4. [x] Implement the next improvement: Create a pre-release when merging to `stg`.
5. [x] Ensure payload consistency.
6. [ ] Test the full workflow with a new feature branch.
