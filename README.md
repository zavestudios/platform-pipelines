# platform-pipelines

Centralized, reusable GitHub Actions workflows for ZaveStudios infrastructure and platform automation.

## Purpose

As ZaveStudios grows, we'll be managing infrastructure across multiple repositories, cloud providers, and environments. This repository centralizes our CI/CD pipeline definitions to ensure:

- **Consistency** - Every infrastructure repo uses the same validated patterns
- **Security** - Security scanning and compliance checks enforced everywhere
- **Maintainability** - Update pipeline logic once, applies to all repos
- **Quality** - Best practices codified and shared across all teams
- **Speed** - Don't rebuild pipelines for each new infrastructure repo

## Vision

This repository serves as the single source of truth for:
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
    uses: eckslopez/platform-pipelines/.github/workflows/terraform-plan.yml@main
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
    uses: eckslopez/platform-pipelines/.github/workflows/terraform-apply.yml@main
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
    uses: eckslopez/platform-pipelines/.github/workflows/terraform-rds.yml@main
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
    uses: eckslopez/platform-pipelines/.github/workflows/security-scan.yml@main
```

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
    uses: eckslopez/platform-pipelines/.github/workflows/jekyll-deploy.yml@main
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
    uses: eckslopez/platform-pipelines/.github/workflows/jekyll-quality.yml@main
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
    uses: eckslopez/platform-pipelines/.github/workflows/jekyll-validate-front-matter.yml@main
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
    uses: eckslopez/platform-pipelines/.github/workflows/db-bootstrap-psql.yml@main
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

See [Issues](https://github.com/eckslopez/platform-pipelines/issues) for planned additions:

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
# Pin to specific commit (most stable)
uses: eckslopez/platform-pipelines/.github/workflows/terraform-rds.yml@a1b2c3d

# Pin to tag (recommended for production)
uses: eckslopez/platform-pipelines/.github/workflows/terraform-rds.yml@v1.0.0

# Use branch (gets latest updates)
uses: eckslopez/platform-pipelines/.github/workflows/terraform-rds.yml@main
```

## Repository Structure

```
platform-pipelines/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml                    # Generic Terraform plan
│       ├── terraform-apply.yml                   # Generic Terraform apply
│       ├── terraform-rds.yml                     # AWS Terraform with OIDC
│       ├── security-scan.yml                     # Gitleaks secret scanning
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
