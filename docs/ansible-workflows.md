# Using Platform Pipelines with Ansible Repositories

This guide documents how to use platform-pipelines shared workflows in Ansible-based repositories.

## Example: zavestudios/ansible Repository

The ansible repository demonstrates best practices for integrating shared workflows with Ansible infrastructure code.

---

## Workflows Used

### Security & Compliance

#### `security.yml` - Security Scanning
**Triggers:** Push to main, PRs, weekly schedule (Mon 9AM UTC), manual

**What it does:**
- **Secret Scanning:** Uses shared `platform-pipelines/security-scan.yml` with Trufflehog
- **Ansible Vault Check:** Verifies no plaintext secrets in variable files
- **Private Key Detection:** Ensures no SSH keys committed
- **Vault Encryption:** Validates vault files are properly encrypted

**Example implementation:**
```yaml
name: Security Scanning

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 9 * * 1'
  workflow_dispatch:

jobs:
  secret-scan:
    name: Scan for Secrets
    uses: zavestudios/platform-pipelines/.github/workflows/security-scan.yml@main
    with:
      fetch_depth: 0  # Scan full history

  ansible-vault-check:
    name: Verify Ansible Vault Security
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@692973e3d937129bcbf40652eb9f2f61becf3332 # v4

      - name: Check for unencrypted secrets in vars
        run: |
          # Custom Ansible-specific checks
          grep -rin "password.*:.*['\"].*['\"]" --include="*.yml" group_vars/ host_vars/ || exit 0
```

**When to run manually:** Before committing changes to group_vars, host_vars, or vault files

---

### Quality Checks

#### `ansible-quality.yml` - Ansible Quality Checks
**Triggers:** Push to main, PRs, manual

**What it does:**
- **Ansible Lint:** Full linting with ansible-lint (best practices, syntax)
- **Syntax Check:** Validates playbook syntax with `ansible-playbook --syntax-check`
- **Inventory Validation:** Ensures inventory structure is valid and required groups exist

**Example implementation:**
```yaml
name: Ansible Quality Checks

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  ansible-lint:
    name: Ansible Lint
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@692973e3d937129bcbf40652eb9f2f61becf3332 # v4
        with:
          fetch-depth: 0

      - name: Set up Python
        uses: actions/setup-python@f677139bbe7f9c59b41e40162b753c062f5d49a3 # v5
        with:
          python-version: '3.12'

      - name: Install Ansible and ansible-lint
        run: |
          python -m pip install --upgrade pip
          pip install ansible-core>=2.16 ansible-lint>=6.22

      - name: Install required Ansible collections
        run: |
          ansible-galaxy collection install -r collections/requirements.yml

      - name: Run ansible-lint
        run: |
          ansible-lint --version
          ansible-lint --force-color --show-relpath

  syntax-check:
    name: Playbook Syntax Check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@692973e3d937129bcbf40652eb9f2f61becf3332 # v4

      - name: Set up Python
        uses: actions/setup-python@f677139bbe7f9c59b41e40162b753c062f5d49a3 # v5
        with:
          python-version: '3.12'

      - name: Install Ansible
        run: |
          pip install ansible-core>=2.16

      - name: Check playbook syntax
        run: |
          for playbook in *.yml; do
            if [ -f "$playbook" ] && [ "$playbook" != "docker-compose.yml" ]; then
              ansible-playbook --syntax-check -i inventory/k3s-cluster.yml "$playbook"
            fi
          done
```

**Dependencies:** Installs Ansible collections from `collections/requirements.yml`

**When to run manually:** After creating/modifying playbooks or roles

---

#### `workflow-validation.yml` - Workflow Validation
**Triggers:** Push/PR that changes `.github/workflows/**`, manual

**What it does:**
Uses shared `platform-pipelines/workflow-ci.yml`:
- **actionlint:** Validates workflow syntax and logic
- **zizmor:** Security audit for workflows (script injection, permissions, action pinning)

**Example implementation:**
```yaml
name: Workflow Validation

on:
  push:
    branches: [main]
    paths:
      - '.github/workflows/**'
  pull_request:
    branches: [main]
    paths:
      - '.github/workflows/**'
  workflow_dispatch:

jobs:
  validate-workflows:
    name: Validate GitHub Actions Workflows
    uses: zavestudios/platform-pipelines/.github/workflows/workflow-ci.yml@main
```

**When to run manually:** After modifying workflow files

---

### Container Management

#### `docker.yml` - Docker Image Validation
**Triggers:** Push/PR that changes Dockerfile or docker-compose.yml, manual

**What it does:**
Uses shared `platform-pipelines/container-build.yml`:
- **Build:** Validates Dockerfile builds successfully
- **Optional push path:** when `push: true`, the workflow performs Trivy scan and Cosign signing

**Example implementation:**
```yaml
name: Docker Image

on:
  push:
    branches: [main]
    paths:
      - 'Dockerfile'
      - 'docker-compose.yml'
  pull_request:
    branches: [main]
    paths:
      - 'Dockerfile'
      - 'docker-compose.yml'
  workflow_dispatch:

jobs:
  build-and-scan:
    name: Build and Scan Ansible Container
    uses: zavestudios/platform-pipelines/.github/workflows/container-build.yml@main
    with:
      image_name: YOUR_ORG/ansible-control
      context: .
      dockerfile: Dockerfile
      push: false
      platforms: linux/amd64
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Note:** Set `push: false` for validation-only (no registry push)

**When to run manually:** After modifying Dockerfile or docker-compose.yml

---

## Shared Workflows Benefits

### Standardization
- Consistent security practices across all Ansible repositories
- Same tooling and versions across organization
- Unified reporting and metrics

### Centralized Maintenance
- Bug fixes and updates in one place
- Version updates managed centrally
- Security improvements benefit all repos immediately

### Security Standards
- All actions pinned to commit SHAs (not mutable tags)
- Least-privilege permissions model
- Regular security audits with zizmor

---

## Running Workflows Manually

```bash
# Trigger via GitHub CLI
gh workflow run security.yml
gh workflow run ansible-quality.yml
gh workflow run docker.yml
gh workflow run workflow-validation.yml

# Or use the GitHub UI:
# Actions tab → Select workflow → Run workflow button
```

---

## Ansible-Specific Considerations

### Collection Dependencies
Many Ansible workflows require collections to be installed:
```yaml
- name: Install required Ansible collections
  run: |
    ansible-galaxy collection install -r collections/requirements.yml
```

Common collections for infrastructure management:
- `community.general` - General-purpose modules
- `community.libvirt` - VM management
- `ansible.posix` - POSIX system operations

### Inventory Validation
Validate inventory structure to catch configuration errors early:
```yaml
- name: Validate inventory structure
  run: |
    ansible-inventory -i inventory/production.yml --list > /dev/null

- name: Check for required groups
  run: |
    ansible-inventory -i inventory/production.yml --graph | grep -q "webservers"
```

### Vault Security
Always include Ansible Vault-specific checks:
- Verify vault files are encrypted (start with `$ANSIBLE_VAULT`)
- No plaintext passwords in variable files
- Vault password files not committed (`.gitignore` coverage)

### Container-based Ansible
When using Ansible in containers (like `ansible-control`):
- Validate Dockerfile builds
- Scan for vulnerabilities regularly
- Keep base images updated
- Test collections installation in container

---

## CI/CD Best Practices for Ansible

### Action Pinning
Following platform-pipelines security standards, all GitHub Actions must be pinned to commit SHAs:
```yaml
# Good - pinned to commit SHA with version comment
uses: actions/checkout@692973e3d937129bcbf40652eb9f2f61becf3332 # v4

# Bad - mutable tag reference
uses: actions/checkout@v4
```

This prevents supply chain attacks via compromised action updates.

### Least-Privilege Permissions
Specify minimal required permissions per job:
```yaml
jobs:
  ansible-lint:
    permissions:
      contents: read  # Only needs to read code
```

### Security Scanning Schedule
Run secret scanning on a schedule, not just on commits:
```yaml
on:
  schedule:
    - cron: '0 9 * * 1'  # Weekly on Mondays
```

This catches secrets that may have been committed historically.

---

## Troubleshooting

### Workflow fails with "workflow not found"
The shared workflow repository must be accessible:
- Repository exists: `zavestudios/platform-pipelines`
- Workflow file exists at specified path
- No typos in the `uses:` statement
- Correct branch/tag reference (`@main` vs `@v1.0.0`)

### Ansible lint fails
```bash
# Test locally first
ansible-lint --force-color --show-relpath

# Or with Docker
docker run -v $(pwd):/ansible ansible-control ansible-lint
```

Common issues:
- Missing collections in `collections/requirements.yml`
- Invalid YAML syntax
- Deprecated Ansible modules
- Overly complex tasks (can be split)

### Secret scanning fails
If secrets are detected:
1. **DO NOT** push the code
2. Immediately rotate any exposed credentials
3. Remove secrets from files
4. Re-encrypt with Ansible Vault
5. Update `.gitignore` patterns
6. Use `git filter-branch` or BFG Repo-Cleaner to remove from history

### Docker build fails
```bash
# Test locally
docker build -t ansible-control:test .

# Check for common issues
- Base image availability
- Network connectivity during pip install
- Dockerfile syntax errors
```

---

## Adding Ansible Workflows to New Repos

### Step 1: Create workflow files
Copy examples from this document or `zavestudios/ansible` repository.

### Step 2: Pin all actions
Use commit SHAs for all `uses:` statements:
```bash
# Find the commit SHA for a tag
gh api repos/actions/checkout/commits/v4 --jq .sha
```

### Step 3: Test locally
Before pushing:
```bash
# Test Ansible lint
ansible-lint

# Test playbook syntax
ansible-playbook --syntax-check site.yml

# Test Docker build
docker build -t test .
```

### Step 4: Validate workflows
```bash
# Install actionlint
brew install actionlint

# Validate workflow syntax
actionlint .github/workflows/*.yml
```

### Step 5: Enable workflows in GitHub
After pushing, visit Actions tab and enable workflows for the repository.

---

## Future Enhancements

### Potential Shared Ansible Workflows
Consider adding to platform-pipelines:

1. **ansible-lint.yml** (reusable)
   - Standardized Ansible linting across organization
   - Configurable ansible-lint versions
   - Optional collections installation

2. **ansible-test.yml** (reusable)
   - Run Ansible test framework
   - Integration test support
   - Service container options (PostgreSQL, Redis, etc.)

3. **ansible-deploy.yml** (reusable)
   - Standardized deployment pattern
   - Environment-specific variable injection
   - Vault password handling
   - Rollback support

### Documentation Improvements
- Add more Ansible-specific examples
- Document vault password management in CI/CD
- Add troubleshooting flowcharts
- Include common patterns library

---

## Related Documentation

- [platform-pipelines README](../README.md) - Main documentation
- [workflow-security.md](workflow-security.md) - Security policies
- [zavestudios/ansible](https://github.com/zavestudios/ansible) - Reference implementation

---

**Note:** This document will be reorganized and integrated into the main platform-pipelines documentation structure. See issue #[TBD] for tracking.
