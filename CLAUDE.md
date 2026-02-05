# Project Context for AI Assistants

## Purpose
Centralized, reusable GitHub Actions workflows for ZaveStudios infrastructure and application automation.

## Current State
Core workflows operational across Terraform, Python, Rails, Jekyll, Hugo, security scanning, database bootstrap, image builds, and link checks.

## Key Files
- `README.md` - Complete workflow documentation and usage examples
- `.github/workflows/` - All reusable workflow definitions
- GitHub Issues - Enhancement tracking

## Working With This Repo

**Adding new workflows:**
```bash
# Create workflow file
vim .github/workflows/new-workflow.yml

# Test from calling repo
# .github/workflows/test.yml in target repo:
jobs:
  test:
    uses: zavestudios/platform-pipelines/.github/workflows/new-workflow.yml@main
```

**Workflow structure:**
```yaml
name: Workflow Name
on:
  workflow_call:
    inputs:
      param_name:
        description: 'What it does'
        required: false
        type: string
        default: 'value'
jobs:
  job_name:
    runs-on: ubuntu-latest
    steps:
      - name: Do something
        run: echo "action"
```

## Available Workflows

**Terraform:**
- `terraform-plan.yml` - Generic provider-agnostic plan
- `terraform-apply.yml` - Generic provider-agnostic apply
- `terraform-rds.yml` - AWS-specific with OIDC

**Python:**
- `python-test.yml` - pytest with PostgreSQL + Redis
- `python-lint.yml` - ruff + black + mypy

**Ruby/Rails:**
- `rails-test.yml` - RSpec/Minitest with PostgreSQL
- `rails-lint.yml` - RuboCop + Brakeman + bundler-audit

**Jekyll/Static Sites:**
- `jekyll-deploy.yml` - Build and deploy to GitHub Pages
- `jekyll-quality.yml` - Build + markdownlint + link checking
- `jekyll-validate-front-matter.yml` - YAML validation
- `link-check.yml` - Standalone link checking

**Hugo:**
- `hugo-deploy.yml` - Build and deploy to GitHub Pages

**Images:**
- `image-build.yml` - Docker image build and push

**Database:**
- `db-bootstrap-psql.yml` - PostgreSQL initialization via psql

**Security:**
- `security-scan.yml` - Gitleaks secret scanning

## Related Repos
All repos in ZaveStudios ecosystem use these workflows:
- **kubernetes-platform-infrastructure** - Terraform workflows (future)
- **panchito** - Python workflows
- **thehouseguy** - Rails workflows
- **rigoberta** - Rails workflows
- **xavierlopez.me** - Jekyll workflows
- **pg-multitenant** - Database workflows

## Architecture
Single source of truth for CI/CD patterns. Repos call workflows via `uses:` with version pinning. Updates propagate to all consumers automatically.

---

## Maintaining This File

**When to update:**
- New workflow added (update Available Workflows list)
- Workflow renamed or removed (update documentation)
- Major parameter changes (update examples)
- New technology stack supported (add to workflow categories)

**What NOT to include:**
- Detailed workflow documentation (belongs in README.md)
- Usage examples for specific repos (belongs in their docs)
- Workflow implementation details (self-documenting in .yml files)
- Pending feature requests (belongs in GitHub Issues)

**Keep it under 100 lines total.**
