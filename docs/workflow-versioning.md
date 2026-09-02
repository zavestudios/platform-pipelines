# Shared Workflow Versioning

`platform-pipelines` releases provide stable discovery metadata for automated
caller updates. Callers continue to execute immutable commit SHAs.

## Release contract

- Use semantic versions in the form `vMAJOR.MINOR.PATCH`.
- Publish releases only from a green `main` revision.
- Increment `MAJOR` for breaking inputs, outputs, permission requirements, or
  behavior.
- Increment `MINOR` for backward-compatible capabilities and runtime upgrades.
- Increment `PATCH` for backward-compatible fixes and documentation changes
  that affect release metadata.
- Do not move or reuse a published release tag.

Releases are published by manually running **Publish Platform Release** against
`main`. This keeps release authority with the human maintainer while making the
operation repeatable.

## Caller contract

Callers pin the commit associated with the release and document the release on
the same line:

```yaml
uses: zavestudios/platform-pipelines/.github/workflows/workflow-ci.yml@0123456789abcdef0123456789abcdef01234567 # v1.0.0
```

Each active caller enables Dependabot for the `github-actions` ecosystem.
Dependabot then resolves new releases to their immutable commit SHAs and opens
an update pull request. Multiple references to `platform-pipelines` are grouped
into one pull request per caller.

Shared platform workflow updates always require human review, including patch
updates. Caller checks must validate reusable-workflow interfaces and required
permissions before merge.

## Caller Dependabot configuration

```yaml
version: 2

updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "America/Los_Angeles"
    open-pull-requests-limit: 5
    groups:
      platform-workflows:
        patterns:
          - "zavestudios/platform-pipelines"
      actions-minor-and-patch:
        update-types:
          - "minor"
          - "patch"
```
