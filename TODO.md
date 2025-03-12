# Project Branching Strategy TODO

## Branch Structure
- [ ] `Main`
      - [ ] Blocked for direct pushes
      - [ ] Only merge from feat / fix branches
      - [ ] Auto tagging / versioning
      - [ ] Create release
      - [ ] Auto deploy to prod
      - [ ] After full test run
- [ ] No `Dev` branch (removed)
- [ ] `Feat` branches
      - [ ] Used for development
      - [ ] When pulling main
            - [ ] → CLI triggered choice (feat or fix)
      - [ ] Runs fast tests
      - [ ] Deploys to staging
      - [ ] Auto open PR to `Main`
      - [ ] Merge → auto increment minor version
- [ ] `Fix` branches
      - [ ] Used for quick hotfixes
      - [ ] When pulling main
            - [ ] → CLI triggered choice (feat or fix)
            - [ ] On fix → [automerge] or [approval]
      - [ ] Runs only necessary tests
      - [ ] Auto open PR
      - [ ] On successful tests
            - [ ] [approval] → wait for 1 approval
            - [ ] [automerge] → auto merge with `Main`
      - [ ] Merge → auto increment fix version

## Implementation Tasks
- [ ] Set up commit-lint for standardized commit messages
- [ ] Configure semantic-release for automated versioning
- [ ] Create GitHub Actions workflows for branch protection
- [ ] Implement CLI tool for branch creation
- [ ] Set up automated PR creation
- [ ] Configure test workflows based on branch type
- [ ] Set up deployment workflows
