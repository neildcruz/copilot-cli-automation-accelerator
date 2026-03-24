# GitHub Actions Workflows - Reference

> **New here?** Start with the [Quick Start Guide](../README.md#-30-second-quick-start) in the main README.
> 
> **This document** is reference documentation for GitHub Actions integration.

This directory contains reusable GitHub Actions workflows for integrating Copilot CLI automation into your CI/CD pipelines.

---

## 🔐 Required Permissions

### Minimal Permissions (Read-Only Analysis)

For basic code analysis that only reads files and generates reports:

```yaml
permissions:
  contents: read
```

**This allows:**
- ✅ Reading repository code
- ✅ Analyzing files
- ✅ Generating reports in workflow logs
- ✅ Running security scans
- ✅ Code quality analysis

### Enhanced Permissions (Interactive Workflows)

For workflows that post comments or create issues:

```yaml
permissions:
  contents: read
  pull-requests: write  # Post review comments on PRs
  issues: write         # Create issues for findings
```

**This additionally allows:**
- ✅ Posting comments on pull requests
- ✅ Creating issues from analysis findings
- ✅ Updating PR descriptions
- ✅ Adding labels to PRs/issues

### Why Specify Permissions?

GitHub's `GITHUB_TOKEN` has limited permissions by default for security. The `permissions:` block grants only what your workflow needs, following the **principle of least privilege**.

**Learn more:** [GitHub Token Permissions Documentation](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token)

---

## Available Actions

Choose the workflow that fits your needs:

1. **[copilot-cli-action.yml](#copilot-cli-actionyml)** - General-purpose code review
2. **[code-review.yml](#code-reviewyml)** - Built-in code review agent
3. **[security-analysis.yml](#security-analysisyml)** - Built-in security scanner
4. **[documentation.yml](#documentationyml)** - Built-in documentation generator
5. **[auto-heal-deploy.yml](#auto-heal-deployyml)** - Build, deploy, and auto-heal with AI-powered failure analysis
6. **[auto-update-unit-tests.yml](#auto-update-unit-testsyml)** - Run tests with coverage analysis and AI-driven test generation
7. **[automate-pr.yml](#automate-pryml)** - Multi-agent issue-to-PR automation (BRD, Architect, Engineer agents)
8. **[Custom Agents](#custom-agent-workflows)** - Use your own agents from `.copilot-agents/`

---

## Custom Agent Workflows

> **New!** Use your project's custom agents in CI/CD pipelines.

Custom agents are stored in your project's `.copilot-agents/` directory and automatically discovered in workflows.

### Example: Use Custom Agent from Repository

```yaml
name: Custom Code Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  custom-review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3
      
      - name: Install Copilot CLI Tools
        run: |
          curl -fsSL https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.sh | bash
      
      - name: Run Your Custom Agent
        run: |
          # Your custom agent is in .copilot-agents/dotnet-review/
          ./copilot-cli-automation-accelerator/automation/copilot-cli.sh \
            --agent dotnet-review \
            --no-ask-user true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Example: Multiple Custom Agents Sequentially

```yaml
name: Multi-Stage Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  multi-stage-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Copilot CLI
        run: curl -fsSL https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.sh | bash
      
      - name: Security + Quality Review
        run: |
          ./copilot-cli-automation-accelerator/automation/copilot-cli.sh \
            --agents "security-baseline,code-quality" \
            --agent-error-mode stop
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Example: Use Shared Organization Agents

```yaml
name: Company Standard Review

on: [pull_request]

jobs:
  company-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Checkout Shared Agents
        uses: actions/checkout@v3
        with:
          repository: your-org/shared-agents
          path: .shared-agents
          token: ${{ secrets.ORG_PAT }}
      
      - name: Install Copilot CLI
        run: curl -fsSL https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.sh | bash
      
      - name: Run Organization Agent
        run: |
          ./copilot-cli-automation-accelerator/automation/copilot-cli.sh \
            --agent-directory .shared-agents \
            --agent company-standards
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Creating Custom Agents

To create custom agents for your workflows:

```bash
# In your repository
cd your-project/
./path/to/copilot-cli.sh --init --as-agent --agent-name "your-agent"

# Edit .copilot-agents/your-agent/user.prompt.md
# Commit to repository
# Use in workflows as shown above
```

**See [CUSTOM-AGENTS.md](../CUSTOM-AGENTS.md) for complete guide.**

---

## auto-heal-deploy.yml

Reusable build, deploy, and auto-heal workflow for Azure Container Apps. On deployment failure, it captures logs, generates an AI-powered root cause analysis via Copilot CLI, and creates a GitHub issue assigned to `@copilot` for automated remediation.

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `container-app-name` | Name of the Azure Container App to deploy to | Yes | — |
| `image-name` | Docker image name (without registry prefix) | Yes | — |
| `resource-group` | Azure resource group for the Container App | No | Falls back to `AZURE_RESOURCE_GROUP` secret |
| `registry` | Container registry URL | No | Falls back to `AZURE_CONTAINER_REGISTRY` secret |

### Secrets

| Secret | Description |
|--------|-------------|
| `AZURE_CONTAINER_REGISTRY` | Container registry URL |
| `REGISTRY_USERNAME` | Registry login username |
| `REGISTRY_PASSWORD` | Registry login password |
| `AZURE_RESOURCE_GROUP` | Azure resource group |
| `AZURE_CREDENTIALS` | Azure service principal credentials |
| `GH_TOKEN` | GitHub token for issue creation |
| `COPILOT_GITHUB_TOKEN` | Token for Copilot CLI authentication |

### Usage

```yaml
name: Deploy My App

on:
  push:
    branches: [main]

jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test

  deploy:
    needs: tests
    uses: ./.github/workflows/auto-heal-deploy.yml
    with:
      container-app-name: my-service
      image-name: my-service-image
    secrets: inherit
```

### What Happens on Failure

1. Deployment logs are captured (Docker build output, Azure Container App logs, app status)
2. Copilot CLI analyzes the logs and identifies root cause
3. A GitHub issue is created with the AI analysis, suggested fix, and full logs
4. `@copilot` is assigned to the issue for automated remediation

---

## auto-update-unit-tests.yml

Reusable unit test and coverage workflow for Python projects. Runs pytest with coverage measurement and, when coverage falls below the threshold, uses Copilot CLI to analyze gaps and create a GitHub issue with suggested test code assigned to `@copilot`.

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `python-version` | Python version to use | No | `3.11` |
| `working-directory` | Directory containing source and test files | No | `src` |
| `requirements-file` | Path to requirements.txt (relative to repo root) | No | `src/requirements.txt` |
| `test-file` | Test file or directory to run (relative to working-directory) | No | `test_app.py` |
| `source-module` | Source module name for coverage measurement | No | `app` |
| `coverage-threshold` | Minimum required coverage percentage | No | `90` |

### Secrets

| Secret | Description |
|--------|-------------|
| `GH_TOKEN` | GitHub token for issue creation |
| `COPILOT_GITHUB_TOKEN` | Token for Copilot CLI authentication |

### Usage

```yaml
name: Test and Coverage

on:
  pull_request:
    branches: [main]

jobs:
  unit-tests:
    uses: ./.github/workflows/auto-update-unit-tests.yml
    with:
      python-version: "3.12"
      working-directory: "myapp"
      test-file: "tests/"
      source-module: "myapp"
      coverage-threshold: 80
    secrets: inherit
```

### What Happens When Coverage Is Low

1. Test results and coverage reports are uploaded as artifacts
2. A PR comment is posted with test results (on pull requests)
3. If coverage is below the threshold, Copilot CLI analyzes the source code and tests
4. A GitHub issue is created with specific uncovered areas, suggested test code, and acceptance criteria
5. `@copilot` is assigned to implement the missing tests

---

## automate-pr.yml

Reusable multi-agent workflow that automates the full lifecycle from GitHub issue to pull request. When triggered (by label, manual dispatch, or another workflow), it runs three AI agents in sequence — BRD, Architect, and Engineer — to generate requirements, plan the architecture, implement the feature, optionally run tests, and open a PR.

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `label-name` | Issue label that triggers the automation | No | `automate-pr` |
| `brd-agent-file` | Path to the BRD agent prompt file | No | `.github/agents/brd.agent.md` |
| `architect-agent-file` | Path to the Architect agent prompt file | No | `.github/agents/architect.agent.md` |
| `engineer-agent-file` | Path to the Engineer agent prompt file | No | `.github/agents/engineer.agent.md` |
| `working-directory` | Directory containing source and test files | No | `src` |
| `requirements-file` | Path to requirements.txt (relative to repo root) | No | `src/requirements.txt` |
| `test-file` | Test file or directory to run (relative to working-directory) | No | `test_app.py` |
| `source-module` | Source module name for coverage measurement | No | `app` |
| `base-branch` | Base branch for feature branch and PR target | No | `main` |
| `run-tests` | Whether to run unit tests after implementation | No | `true` |
| `artifact-retention-days` | Number of days to retain workflow artifacts | No | `30` |
| `pr-labels` | Comma-separated labels to apply to the created PR | No | `automated,enhancement` |

### Secrets

| Secret | Description |
|--------|-------------|
| `GH_TOKEN` | GitHub token for issue/PR operations and pushing branches |
| `COPILOT_GITHUB_TOKEN` | Token for Copilot CLI authentication |

### Usage

#### As a reusable workflow (called from another workflow)

```yaml
name: Issue to PR Automation

on:
  issues:
    types: [labeled]

jobs:
  automate:
    uses: ./.github/workflows/automate-pr.yml
    with:
      label-name: "automate-pr"
      working-directory: "myapp"
      requirements-file: "myapp/requirements.txt"
      test-file: "tests/"
      source-module: "myapp"
      base-branch: "develop"
    secrets: inherit
```

#### Standalone (triggered by issue label)

The workflow also triggers directly when the configured label is added to an issue — no wrapper workflow needed. Just copy `automate-pr.yml` into `.github/workflows/` and add the `automate-pr` label to any issue.

#### Manual trigger

Use `workflow_dispatch` to run against a specific issue number:

```yaml
# Trigger via GitHub UI or CLI:
gh workflow run automate-pr.yml -f issue-number=42
```

### What Happens

1. **BRD Agent** reads the issue and generates a Business Requirements Document
2. **Architect Agent** analyzes the BRD and produces an architecture and task plan
3. **Engineer Agent** implements the feature using Copilot CLI with full tool access
4. Unit tests are run (if `run-tests` is enabled), results captured in artifacts
5. Changes are committed, pushed to a feature branch, and a PR is opened linking the issue
6. Copilot is optionally requested as a reviewer on the PR
7. On failure, a diagnostic comment is posted on the issue

---

## copilot-cli-action.yml

General-purpose action with custom prompts.

```yaml
name: Code Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  review:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Review this PR for code quality, security issues, and best practices."
    secrets:
      github_token: ${{ secrets.GITHUB_TOKEN }}
```

## code-review.yml

Uses the built-in code review agent.

```yaml
name: Code Review

on: [pull_request]

jobs:
  review:
    uses: ./.github/workflows/code-review.yml
    secrets:
      github_token: ${{ secrets.GITHUB_TOKEN }}
```

## security-analysis.yml

Uses the built-in security analysis agent.

```yaml
name: Security Analysis

on:
  pull_request:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

jobs:
  security:
    uses: ./.github/workflows/security-analysis.yml
    secrets:
      github_token: ${{ secrets.GITHUB_TOKEN }}
```

## documentation.yml

Uses the built-in documentation generation agent.

```yaml
name: Generate Documentation

on:
  push:
    branches: [main]

jobs:
  docs:
    uses: ./.github/workflows/documentation.yml
    secrets:
      github_token: ${{ secrets.GITHUB_TOKEN }}
```

---

## Configuration

All workflows support these inputs:

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `prompt` | Custom prompt for analysis | No | (uses agent default) |
| `agent` | Built-in or custom agent name | No | `code-review` |
| `model` | Copilot model to use | No | `claude-sonnet-4.5` |
| `no_ask_user` | Disable interactive prompts | No | `true` |

## Secrets

Required secrets:

- `GITHUB_TOKEN` - Automatically provided by GitHub Actions

Optional secrets:

- `COPILOT_GITHUB_TOKEN` - Alternative token for Copilot CLI

---

## Best Practices

### 1. Use Custom Agents for Consistency

Store agents in `.copilot-agents/` for version-controlled, team-shared configurations:

```yaml
- name: Run Team Standards
  run: ./copilot-cli.sh --agent team-standards
```

### 2. Multiple Agents for Comprehensive Analysis

```yaml
- name: Multi-Stage Review
  run: |
    ./copilot-cli.sh --agents "security,quality,performance" \
      --agent-error-mode stop
```

### 3. Conditional Execution

```yaml
- name: Security Scan
  if: github.event_name == 'pull_request'
  run: ./copilot-cli.sh --agent security-baseline
```

### 4. Cache Installation for Faster Builds

```yaml
- name: Cache Copilot CLI
  uses: actions/cache@v3
  with:
    path: copilot-cli-automation-accelerator
    key: copilot-cli-${{ hashFiles('**/install.sh') }}
```

---

## Troubleshooting

### Agent Not Found

Ensure `.copilot-agents/` is committed to your repository:

```bash
git add .copilot-agents/
git commit -m "Add custom agents"
```

### Permission Errors

Ensure workflow has required permissions:

```yaml
permissions:
  contents: read
  pull-requests: write
```

### Authentication Issues

Verify `GITHUB_TOKEN` is passed correctly:

```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Additional Resources

- [CUSTOM-AGENTS.md](../CUSTOM-AGENTS.md) - Complete guide to creating custom agents
- [README.md](../README.md) - Main project documentation
- [automation/README.md](../automation/README.md) - Local script usage

---

**Questions?** Open an issue on GitHub.
