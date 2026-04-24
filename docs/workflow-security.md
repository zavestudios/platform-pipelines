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
