# Workflow Security Policy

## Zizmor Gating

As of Phase 10 (`#33`), `zizmor` is a blocking check in `.github/workflows/workflow-ci.yml`.

Policy:

- No unsuppressed high-confidence findings are permitted.
- Low-confidence findings should be fixed when practical.
- Suppressions must include a rationale in code review/PR context.

Current disposition:

- Remaining high/medium findings: none.
- Remaining informational findings: none after refactoring `dependabot-auto-merge.yml` to avoid inline template expansion in shell `run` blocks.

## Shared Workflow Ref Pinning

`.github/workflows/workflow-ci.yml` also enforces immutable pinning for
`zavestudios/platform-pipelines` reusable workflow refs.

Policy:

- Governed repositories must pin shared workflow refs to 40-character commit SHAs.
- Floating refs such as `@main` and mutable tags are not permitted for governed consumers.
- Local workflow refs such as `./.github/workflows/foo.yml` are outside the scope of this check.
- When `workflow-ci.yml` runs as a reusable workflow, it evaluates the caller repository's workflow files directly and does not require caller-local copies of platform-pipelines helper assets.

## Canonical Required Status Checks

The `platform-pipelines` default-branch ruleset should require the current
canonical `workflow-ci.yml` job names below and no stale predecessors.

Canonical required checks:

- `Lint Workflows (actionlint)`
- `Audit Workflows (zizmor)`
- `Smoke Reusable Security Scan / Secret Scan (Trufflehog)`
- `Smoke Reusable Container Build / build_scan_sign`

Validation notes:

- Treat the active default-branch ruleset as the source of truth for enforcement.
- If a required check remains in GitHub branch protection after its workflow job
  has been renamed or removed, pull requests may hang in `Expected — Waiting for status to be reported`.
- When job names change in reusable workflows, update the affected rulesets
  before or at the same time as the workflow merge.
