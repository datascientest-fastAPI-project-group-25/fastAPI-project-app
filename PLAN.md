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
   - [ ] No pre-release is being created in the app repo with the staging images attached.

4. **Payload Dispatch**:
   - [x] The `trigger-release` job is executed, which calls the `trigger-helm-release.yml` workflow.
   - [x] FIXED: The semantic version and image tags are now correctly passed to the payload.

5. **PR Creation**:
   - [x] A PR from `stg` to `main` is automatically created.

### Staging to Main (`stg` -> `main`)

1. **Docker Image Retagging**:
   - [ ] The existing `stg-<SHORTHASH>` images are not being retagged with the SemVer.
   - [ ] Instead, new images are being built with the SemVer tag.

2. **GitHub Release Creation**:
   - [x] The `create-app-release.yml` workflow is triggered after the production image build.
   - [ ] The release is not properly linking to the staging images that were promoted.

3. **Payload Dispatch**:
   - [x] The `trigger-release` job is executed for production.
   - [ ] The payload may not reference the correct images due to the retagging issue.

## Issues to Fix

1. [x] **Version Bump Process**:
   - [x] FIXED: The version bump is now applied directly to the branch rather than creating a separate PR.
   - [x] This ensures the VERSION file always reflects the current state.

2. [x] **Docker Image Tagging**:
   - [x] FIXED: For `stg`, images are now tagged with both `stg-<SHORTHASH>` AND `stg-<SemVer>`.
   - [x] FIXED: Both tags are stored as outputs for later use.
   - [x] FIXED: The commit comment now includes both tags for better traceability.

3. [ ] **Image Retagging for Production**:
   - [ ] When merging to `main`, we should retag the existing `stg-<SHORTHASH>` images with `<SemVer>` rather than rebuilding.
   - [ ] This ensures the exact same image that was tested in staging is promoted to production.

4. [ ] **GitHub Release Creation**:
   - [ ] We need to create a pre-release when merging to `stg` and promote it to a full release when merging to `main`.
   - [ ] The release should include links to the Docker images.

5. [ ] **Payload Consistency**:
   - [ ] Ensure the payload sent to the release repository contains the correct SemVer and image references.

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

1. [ ] Create a new job in `build-prod-image.yml` to:
   - [ ] Identify the corresponding `stg-<SHORTHASH>` image.
   - [ ] Retag it with the SemVer without rebuilding.
   - [ ] This ensures the exact same image is promoted.

### 4. Fix GitHub Release Creation

1. [ ] Create a new workflow or modify `create-app-release.yml` to:
   - [ ] Create a pre-release when merging to `stg`.
   - [ ] Promote the pre-release to a full release when merging to `main`.
   - [ ] Include links to the Docker images in the release notes.

### 5. Ensure Payload Consistency

1. [ ] Update the `trigger-helm-release.yml` workflow to:
   - [ ] Use consistent image references for both `stg` and `prod`.
   - [ ] Include the correct SemVer in the payload.

## Next Steps

1. [x] Implement the changes to the version bump process.
2. [x] Implement the Docker image tagging strategy.
3. [ ] Implement the next improvement: image retagging for production.
4. [ ] Fix the GitHub release creation process.
5. [ ] Ensure payload consistency.
6. [ ] Test the full workflow with a new feature branch.
