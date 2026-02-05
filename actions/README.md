# GitHub Actions Workflows

This directory contains reusable GitHub Actions workflows for integrating Copilot CLI automation into your CI/CD pipelines.

## Available Actions

Choose the workflow that fits your needs:

1. **[copilot-cli-action.yml](#copilot-cli-actionyml)** - General-purpose code review
2. **[code-review.yml](#code-reviewyml)** - Built-in code review agent
3. **[security-analysis.yml](#security-analysisyml)** - Built-in security scanner
4. **[documentation.yml](#documentationyml)** - Built-in documentation generator
5. **[Custom Agents](#custom-agent-workflows)** - Use your own agents from `.copilot-agents/`

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
