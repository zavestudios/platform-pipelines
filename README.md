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

- Generic Terraform plan workflow (provider-agnostic)
- Generic Terraform apply workflow (provider-agnostic)
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
│       ├── terraform-rds.yml           # AWS Terraform with OIDC
│       ├── terraform-plan.yml          # Generic plan (planned)
│       ├── terraform-apply.yml         # Generic apply (planned)
│       ├── tfsec.yml                   # Security scanning (planned)
│       └── db-bootstrap-psql.yml       # PostgreSQL bootstrap
├── docs/                                # Additional documentation (planned)
└── README.md
```

## License

MIT License - See [LICENSE](LICENSE) file

---

**Maintainer:** Xavier Lopez
**Organization:** ZaveStudios
