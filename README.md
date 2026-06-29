# platform-pipelines

Centralized, reusable GitHub Actions workflows for ZaveStudios infrastructure and platform automation.

**Repository Category:** `platform-service` (canonical classification in [REPO_TAXONOMY.md](https://github.com/zavestudios/platform-docs/blob/main/_platform/REPO_TAXONOMY.md))

## Purpose

As ZaveStudios grows, we'll be managing infrastructure across multiple repositories, cloud providers, and environments. This repository centralizes our CI/CD pipeline definitions to ensure:

- **Consistency** - Every infrastructure repo uses the same validated patterns
- **Security** - Security scanning and compliance checks enforced everywhere
- **Maintainability** - Update pipeline logic once, applies to all repos
- **Quality** - Best practices codified and shared across all teams
- **Speed** - Don't rebuild pipelines for each new infrastructure repo

## Vision

This repository is the centralized home for reusable workflow implementations for:
- Terraform workflows (plan, apply, security scanning)
- Database provisioning and bootstrapping
- Infrastructure testing and validation
- Compliance and security automation
- Deployment pipelines for multiple cloud providers

As our infrastructure footprint expands, this repo scales with us - whether we're deploying RDS instances, Kubernetes clusters, networking infrastructure, or application platforms.

## Architecture

**Reusable Workflows** - All workflows use GitHub's `workflow_call` trigger, making them composable building blocks that can be called from any infrastructure repository.

**Provider-Agnostic** - While we have provider-specific workflows (e.g., AWS OIDC), we maintain generic workflows that work with any infrastructure provider (AWS, GCP, Azure, libvirt, etc.).

**Separation of Concerns** - Pipeline logic lives here; infrastructure code lives in dedicated repos. Infrastructure repos stay focused on what they provision, not how they're deployed.

## Current Workflows

### Terraform

#### `.github/workflows/terraform-plan.yml`
Generic Terraform plan workflow (provider-agnostic).

**Features:**
- Runs `terraform init`, `validate`, `fmt -check`, `plan`
- Comments plan output on pull requests
- Configurable Terraform version and working directory
- Supports tfvars files and JSON variables

**Usage:**
```yaml
# In your infrastructure repo
name: Terraform Plan
on: [pull_request]

jobs:
  plan:
    uses: zavestudios/platform-pipelines/.github/workflows/terraform-plan.yml@main
    with:
      tf_working_dir: ./terraform
      terraform_version: latest
```

#### `.github/workflows/terraform-apply.yml`
Generic Terraform apply workflow (provider-agnostic).

**Features:**
- Runs `terraform init` and `apply`
- Auto-approves apply
- Configurable Terraform version and working directory
- Supports tfvars files and JSON variables

**Usage:**
```yaml
# In your infrastructure repo
name: Terraform Apply
on:
  push:
    branches: [main]

jobs:
  apply:
    uses: zavestudios/platform-pipelines/.github/workflows/terraform-apply.yml@main
    with:
      tf_working_dir: ./terraform
      terraform_version: latest
```

#### `.github/workflows/terraform-rds.yml`
AWS-specific Terraform workflow with OIDC authentication.

**Features:**
- Assumes AWS IAM role via GitHub OIDC
- Runs `terraform init`, `validate`, `plan`
- Optionally runs `terraform apply`
- Designed for AWS infrastructure repos

**Usage:**
```yaml
# In your infrastructure repo
name: Deploy RDS
on: [push]

jobs:
  terraform:
    uses: zavestudios/platform-pipelines/.github/workflows/terraform-rds.yml@main
    with:
      tf_working_dir: ./terraform
      aws_region: us-east-1
      run_apply: true
    secrets:
      AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}
```

### Security

#### `.github/workflows/security-scan.yml`
Secret scanning with Gitleaks.

**Features:**
- Scans repository for exposed secrets and credentials
- Works with any repository type
- Configurable git fetch depth

**Usage:**
```yaml
# In your repo
name: Security Scan
on:
  pull_request:
  schedule:
    - cron: "0 9 * * 1"

jobs:
  security:
    uses: zavestudios/platform-pipelines/.github/workflows/security-scan.yml@main
```

### Ruby on Rails

#### `.github/workflows/rails-test.yml`
Comprehensive Rails test suite with PostgreSQL.

**Features:**
- Sets up Ruby and PostgreSQL service container
- Runs database setup and migrations
- Executes unit, integration, and system tests
- Uploads screenshots on system test failures
- Configurable Ruby version, PostgreSQL version, and test commands

**Usage:**
```yaml
# In your Rails repo
name: Tests
on: [pull_request, push]

jobs:
  test:
    uses: zavestudios/platform-pipelines/.github/workflows/rails-test.yml@main
    with:
      ruby_version: '3.2'
      run_system_tests: true
```

#### `.github/workflows/rails-lint.yml`
Rails code quality and security checks.

**Features:**
- RuboCop for Ruby style and best practices
- Brakeman for Rails security vulnerabilities
- bundler-audit for dependency vulnerability scanning
- Configurable to enable/disable individual checks

**Requirements:**
- Repositories must declare enabled lint/security tools in their own `Gemfile`
  and lockfile. This workflow does not install ad-hoc latest gems at runtime.

**Usage:**
```yaml
# In your Rails repo
name: Lint & Security
on: [pull_request]

jobs:
  lint:
    uses: zavestudios/platform-pipelines/.github/workflows/rails-lint.yml@main
    with:
      ruby_version: '3.2'
      run_rubocop: true
      run_brakeman: true
      run_bundler_audit: true
```

### Containers

#### `.github/workflows/container-build.yml`
Reusable GHCR container build workflow.

**Features:**
- Builds multi-architecture container images with Buildx
- Optionally pushes images to GHCR
- Runs Trivy and Cosign only for push/promote invocations
- Supports optional changed-path gating through `build_paths`

**Usage:**
```yaml
# In your container repo
name: Build
on:
  push:
    branches:
      - main
  pull_request:
  workflow_dispatch:

jobs:
  build:
    uses: zavestudios/platform-pipelines/.github/workflows/container-build.yml@main
    with:
      image_name: zavestudios/example
      dockerfile: Dockerfile
      push: ${{ github.event_name == 'push' && github.ref == 'refs/heads/main' }}
      build_paths: |
        Dockerfile
        config/**
        scripts/build/**
        .github/workflows/build.yml
```

If `build_paths` is empty, the workflow preserves legacy behavior and always runs the container build. `workflow_dispatch` also always runs the build.

### Jekyll / Static Sites

#### `.github/workflows/jekyll-deploy.yml`
Build and deploy Jekyll site to GitHub Pages.

**Features:**
- Builds Jekyll site with configurable Ruby version
- Deploys to GitHub Pages
- Configurable Jekyll environment

**Usage:**
```yaml
# In your Jekyll repo
name: Deploy Jekyll Site
on:
  push:
    branches: [main]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    uses: zavestudios/platform-pipelines/.github/workflows/jekyll-deploy.yml@main
    with:
      ruby_version: '3.1'
```

#### `.github/workflows/jekyll-quality.yml`
Jekyll site quality checks (build, markdown lint, link checking).

**Features:**
- Builds Jekyll site
- Runs markdownlint on all markdown files
- Checks for broken links with lychee
- Configurable markdown globs and lychee options

**Usage:**
```yaml
# In your Jekyll repo
name: Site Quality
on: [pull_request]

jobs:
  quality:
    uses: zavestudios/platform-pipelines/.github/workflows/jekyll-quality.yml@main
    with:
      lychee_config_path: .github/lychee.toml
```

#### `.github/workflows/jekyll-validate-front-matter.yml`
Validate Jekyll post front matter.

**Features:**
- Validates YAML front matter in Jekyll posts
- Runs custom validation script
- Configurable Python version and script path

**Usage:**
```yaml
# In your Jekyll repo
name: Validate Front Matter
on: [pull_request]

jobs:
  validate:
    uses: zavestudios/platform-pipelines/.github/workflows/jekyll-validate-front-matter.yml@main
```

### Database

#### `.github/workflows/db-bootstrap-psql.yml`
PostgreSQL database bootstrapping workflow.

**Features:**
- Connects to PostgreSQL endpoint via `psql`
- Runs SQL files for schema creation, roles, tenants, etc.
- Supports SSL connections

**Usage:**
```yaml
# In your infrastructure repo
name: Bootstrap Database
on: [workflow_dispatch]

jobs:
  bootstrap:
    uses: zavestudios/platform-pipelines/.github/workflows/db-bootstrap-psql.yml@main
    with:
      db_endpoint: my-db.region.rds.amazonaws.com
      db_name: myapp
      db_user: admin
      sql_paths: |
        sql/01-schema.sql
        sql/02-roles.sql
        sql/03-seed.sql
    secrets:
      DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

## Upcoming Workflows

See [Issues](https://github.com/zavestudios/platform-pipelines/issues) for planned additions:

- tfsec security scanning workflow
- Terraform cost estimation
- Multi-environment deployment patterns

## Contributing

When adding new workflows:

1. **Make them reusable** - Use `workflow_call` trigger
2. **Document inputs/outputs** - Clear descriptions for all parameters
3. **Provide examples** - Show real-world usage in README
4. **Consider security** - Follow least-privilege principles
5. **Test thoroughly** - Validate with real infrastructure repos

## Workflow Versioning

**Pinning versions:**
```yaml
# Governed repositories must pin to a specific 40-character commit SHA
uses: zavestudios/platform-pipelines/.github/workflows/terraform-rds.yml@0123456789abcdef0123456789abcdef01234567

# Mutable tags are not permitted for governed repositories
uses: zavestudios/platform-pipelines/.github/workflows/terraform-rds.yml@v1.0.0

# Floating branches such as @main are not permitted for governed repositories
uses: zavestudios/platform-pipelines/.github/workflows/terraform-rds.yml@main
```

For governed `tenant` and `portfolio` repositories, shared workflow refs must use
an immutable 40-character commit SHA.

## Repository Structure

```
platform-pipelines/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml                    # Generic Terraform plan
│       ├── terraform-apply.yml                   # Generic Terraform apply
│       ├── terraform-rds.yml                     # AWS Terraform with OIDC
│       ├── security-scan.yml                     # Gitleaks secret scanning
│       ├── rails-test.yml                        # Rails test suite with PostgreSQL
│       ├── rails-lint.yml                        # Rails lint & security checks
│       ├── jekyll-deploy.yml                     # Jekyll GitHub Pages deploy
│       ├── jekyll-quality.yml                    # Jekyll quality checks
│       ├── jekyll-validate-front-matter.yml      # Jekyll front matter validation
│       └── db-bootstrap-psql.yml                 # PostgreSQL bootstrap
├── docs/                                          # Additional documentation (planned)
└── README.md
```

## License

MIT License - See [LICENSE](LICENSE) file

---

**Maintainer:** Xavier Lopez
**Organization:** ZaveStudios
# A little test
