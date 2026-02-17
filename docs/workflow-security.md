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
