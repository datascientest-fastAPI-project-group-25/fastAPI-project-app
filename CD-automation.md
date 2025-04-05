Automated CI/CD Workflow
Here's a Mermaid diagram representing your workflow:
graph LR
    feat[Feature Branch] --> autoPR[Auto PR to Staging]
    autoPR --> tests[Tests]
    autoPR --> lint[Lint]
    autoPR --> format[Format]
    autoPR --> sec[Security Checks]

    tests --> stg[Staging Branch]
    lint --> stg
    format --> stg
    sec --> stg

    stg --> merge[Merge to Staging]
    merge --> close[Close Feature Branch]
    merge --> build[Build Image]

    build --> tag[Tag with gitHash + branchtype]
    tag --> ghcr1[Push to GHCR]

    ghcr1 --> prMain[Auto PR to Main]
    prMain --> mergeMain[Merge to Main]

    mergeMain --> retag[Retag with SemVer]
    retag --> ghcr2[Push to GHCR Production]

    subgraph "Branch Management"
        feat
        close
    end

    subgraph "Quality Gates"
        tests
        lint
        format
        sec
    end

    subgraph "Image Management"
        build
        tag
        ghcr1
        retag
        ghcr2
    end

    subgraph "Promotion Flow"
        autoPR
        stg
        merge
        prMain
        mergeMain
    end
Workflow Explanation
	1.	Branch Management:
	▪	Start with feature branch (⁠feat or ⁠fix)
	▪	Close feature branch after successful merge to staging
	2.	Quality Gates:
	▪	Run tests, linting, formatting, and security checks on PR
	3.	Promotion Flow:
	▪	Auto-create PR from feature branch to staging
	▪	Merge to staging after passing quality gates
	▪	Auto-create PR from staging to main
	▪	Merge to main
	4.	Image Management:
	▪	Build image after merge to staging
	▪	Tag with git hash and branch type (feat/fix)
	▪	Push to GitHub Container Registry
	▪	After merge to main, retag with semantic version based on branch type:
	◦	⁠feat → minor version bump
	◦	⁠fix → patch version bump
	▪	Push production image to GHCR
