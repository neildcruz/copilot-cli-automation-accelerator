# Creating Custom Agents

> **Quick Start:** Want to create a custom agent right now? Run `./ copilot-cli.sh --init --as-agent --agent-name "my-agent"` from your project directory.

Custom agents allow you to create specialized, reusable configurations tailored to your specific codebase, technology stack, and team standards. This guide shows you how to create, organize, and use custom agents in your projects and CI/CD pipelines.

## Table of Contents

- [Quick Start](#quick-start)
- [Agent Structure](#agent-structure)
- [Discovery and Priority](#discovery-and-priority)
- [Creating Custom Agents](#creating-custom-agents)
- [Using Custom Agents](#using-custom-agents)
- [CI/CD Integration](#cicd-integration)
- [Advanced Patterns](#advanced-patterns)
- [Troubleshooting](#troubleshooting)

---

##  Quick Start

### Create Your First Custom Agent

```bash
# Navigate to your project
cd your-project/

# Create a custom agent
./path/to/copilot-cli.sh --init --as-agent --agent-name "my-custom-agent"

# This creates:
# .copilot-agents/
#   my-custom-agent/
#     copilot-cli.properties
#     user.prompt.md
#     my-custom-agent.agent.md
#     description.txt
```

```powershell
# PowerShell (Windows)
.\path\to\copilot-cli.ps1 -Init -AsAgent -AgentName "my-custom-agent"
```

### Edit the Agent Configuration

Edit `.copilot-agents/my-custom-agent/user.prompt.md`:

```markdown
# User Prompt: my-custom-agent

Analyze this C# codebase for:
1. SOLID principle violations
2. Missing XML documentation on public APIs
3. Async/await best practices
4. Dependency injection anti-patterns

Provide specific examples and prioritized recommendations.
```

### Run Your Custom Agent

```bash
# From your project root
./path/to/copilot-cli.sh --agent my-custom-agent
```

```powershell
# PowerShell
.\path\to\copilot-cli.ps1 -Agent my-custom-agent
```

---

## Agent Structure

A custom agent is a directory containing configuration and prompt files:

```
my-custom-agent/
├── copilot-cli.properties    # Agent configuration
├── user.prompt.md             # Main task/instructions
├── my-custom-agent.agent.md   # Agent definition (YAML frontmatter + guidelines)
└── description.txt            # (Optional) One-line description
```

### File Descriptions

#### `copilot-cli.properties`

Configuration for the agent including model, permissions, and settings.

```properties
# Custom Agent Configuration
prompt.file=user.prompt.md
agent.file=my-custom-agent.agent.md

# Model and permissions
copilot.model=claude-sonnet-4.5
allow.all.tools=true
allow.all.paths=false

# Tool restrictions for security-focused agents
# denied.tools=shell,bash,rm

# Execution settings
log.level=info
timeout.minutes=30
```

#### `user.prompt.md`

The main prompt defining what the agent should do:

```markdown
# User Prompt: Security Review Agent

Perform a comprehensive security review of this codebase:

## Focus Areas
1. **Authentication & Authorization**
   - JWT token handling
   - Session management
   - Role-based access control

2. **Input Validation**
   - SQL injection risks
   - XSS vulnerabilities
   - Command injection potential

3. **Data Protection**
   - Sensitive data exposure
   - Encryption usage
   - API key management

Provide severity ratings (Critical/High/Medium/Low) and specific remediation steps.
```

#### `{name}.agent.md`

The agent definition file using YAML frontmatter for metadata and markdown for the prompt body:

```markdown
---
name: security-review
description: Security expert reviewing code for vulnerabilities
tools:
  - read_file
  - grep_search
  - list_dir
---

# Security Review Agent

You are a security expert with deep knowledge of OWASP Top 10 and security best practices.

## Response Format
- Group findings by severity
- Provide code examples for each issue
- Include fix recommendations with code snippets
- Reference relevant CWE identifiers

## Constraints
- Focus only on security issues, not code style
- Be thorough but avoid false positives
- Prioritize actionable findings
```

#### `description.txt`

A one-line description shown when listing agents:

```
Comprehensive security vulnerability scanner for web applications
```

---

## Discovery and Priority

The tool searches for agents in this order (**first match wins**):

### 1. `--agent-directory` Parameter (Highest Priority)

```bash
./copilot-cli.sh --agent-directory ./my-agents --agent security-scan
```

Use when you want to explicitly specify where agents are located.

### 2. `--additional-agent-directories` Parameter

```bash
./copilot-cli.sh --additional-agent-dirs "./team-agents,./ci-agents" --agent code-review
```

Search multiple directories (comma-separated). Useful for combining team-wide and project-specific agents.

### 3. `COPILOT_AGENT_DIRECTORIES` Environment Variable

**Linux/macOS (colon-separated `:` delimiter):**
```bash
export COPILOT_AGENT_DIRECTORIES="/shared/company-agents:$HOME/.copilot-agents"
```

**Windows CMD (semicolon-separated `;` delimiter):**
```cmd
set COPILOT_AGENT_DIRECTORIES=C:\shared\company-agents;%USERPROFILE%\.copilot-agents
```

**Windows PowerShell (semicolon-separated `;` delimiter):**
```powershell
$env:COPILOT_AGENT_DIRECTORIES = "C:\shared\company-agents;$HOME\.copilot-agents"
```

> ⚠️ **Important Platform Difference:** 
> - **Windows** uses **semicolons** (`;`) to separate paths
> - **Linux/macOS** uses **colons** (`:`) to separate paths
> 
> Using the wrong delimiter will cause agent discovery to fail silently.

Perfect for CI/CD environments and organization-wide agent sharing.

### 4. `.copilot-agents/` in Current Directory (Convention)

The **recommended** location for project-specific agents. Automatically discovered when present.

```
your-project/
├── .copilot-agents/          # ✅ Recommended location
│   ├── dotnet-review/
│   ├── security-scan/
│   └── test-coverage/
├── src/
└── tests/
```

### 5. Built-in Examples (Fallback)

The tool's built-in example agents are always available as fallback.

---

## Creating Custom Agents

### Method 1: Using `--init --as-agent` (Recommended)

Creates a complete agent structure with templates:

```bash
# Bash
./copilot-cli.sh --init --as-agent --agent-name "dotnet-standards"

# PowerShell
.\copilot-cli.ps1 -Init -AsAgent -AgentName "dotnet-standards"
```

**Advantages:**
- ✅ Complete structure created automatically
- ✅ Template files with helpful comments
- ✅ Placed in `.copilot-agents/` by default
- ✅ Ready to use immediately

### Method 2: Copy and Customize Examples

Start from a built-in example:

```bash
# Copy an example as starting point
mkdir -p .copilot-agents/
cp -r automation/examples/code-review/ .copilot-agents/my-code-review/

# Customize for your needs
cd .copilot-agents/my-code-review/
nano user.prompt.md
nano my-code-review.agent.md

# Use it
../../automation/copilot-cli.sh --agent my-code-review
```

### Method 3: Create From Scratch

Manually create the directory and files:

```bash
mkdir -p .copilot-agents/custom-agent
cd .copilot-agents/custom-agent

# Create config file
cat > copilot-cli.properties << 'EOF'
prompt.file=user.prompt.md
agent.file=custom-agent.agent.md
copilot.model=claude-sonnet-4.5
allow.all.tools=true
EOF

# Create prompt files
echo "# Your prompt here" > user.prompt.md
echo "---" > custom-agent.agent.md
echo "name: custom-agent" >> custom-agent.agent.md
echo "description: Your agent description" >> custom-agent.agent.md
echo "---" >> custom-agent.agent.md
echo "# Your agent guidelines here" >> custom-agent.agent.md
echo "Brief description" > description.txt
```

---

## Using Custom Agents

### By Name (Searches Agent Directories)

```bash
# Discovers agent in .copilot-agents/, COPILOT_AGENT_DIRECTORIES, etc.
./copilot-cli.sh --agent my-agent
```

### By Relative Path

```bash
# Use agent from specific location
./copilot-cli.sh --agent ./ci/agents/pipeline-validator
```

### By Absolute Path

```bash
# Use agent from anywhere
./copilot-cli.sh --agent /shared/company/agents/security-baseline
```

### With Properties File

Configure default agent in `copilot-cli.properties`:

```properties
# Project configuration
agent.directory=./.copilot-agents
additional.agent.directories=./team-agents,/shared/agents

# Default agent (can be overridden with --agent)
# agent=security-scan
```

### List Available Agents

```bash
./copilot-cli.sh --list-agents
```

Shows all agents from all discovery locations with their descriptions.

---

## CI/CD Integration

### GitHub Actions

#### Option 1: Agent in Repository

```yaml
name: Custom Code Review

on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Copilot CLI Tools
        run: |
          curl -fsSL https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.sh | bash
      
      - name: Run Custom Agent
        run: |
          # Agent is in .copilot-agents/dotnet-standards/
          ./copilot-cli-automation-accelerator/automation/copilot-cli.sh \
            --agent dotnet-standards \
            --no-ask-user true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### Option 2: Shared Agents via Environment

```yaml
name: Company Standard Review

on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Checkout Shared Agents
        uses: actions/checkout@v3
        with:
          repository: company/shared-agents
          path: .shared-agents
          token: ${{ secrets.COMPANY_PAT }}
      
      - name: Install Copilot CLI Tools
        run: curl -fsSL https://... | bash
      
      - name: Run Company Standard Agent
        run: |
          ./copilot-cli-automation-accelerator/automation/copilot-cli.sh \
            --agent-directory .shared-agents \
            --agent code-standards
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Azure Pipelines

```yaml
trigger:
  - main
  - develop

pool:
  vmImage: 'ubuntu-latest'

steps:
- checkout: self
- task: Bash@3
  displayName: 'Install Copilot CLI'
  inputs:
    targetType: 'inline'
    script: curl -fsSL https://... | bash

- task: Bash@3
  displayName: 'Run Custom Agent'
  inputs:
    targetType: 'inline'
    script: |
      ./copilot-cli-automation-accelerator/automation/copilot-cli.sh \
        --agent security-baseline \
        --no-ask-user true
  env:
    GITHUB_TOKEN: $(GITHUB_TOKEN)
```

### GitLab CI

```yaml
code-review:
  stage: test
  image: node:20
  before_script:
    - curl -fsSL https://... | bash
  script:
    - ./copilot-cli-automation-accelerator/automation/copilot-cli.sh
        --agent custom-review
        --no-ask-user true
  variables:
    COPILOT_AGENT_DIRECTORIES: "${CI_PROJECT_DIR}/.copilot-agents"
  only:
    - merge_requests
```

### Multi-Project Setup (Organization-Wide)

```bash
# Shared agents repository structure
company-agents/
├── security/
│   ├── baseline-scan/
│   ├── dependency-check/
│   └── secrets-scanner/
├── code-quality/
│   ├── dotnet-standards/
│   ├── python-pep8/
│   └── javascript-eslint/
└── compliance/
    ├── gdpr-checker/
    └── sox-validator/

# Each project configures discovery
export COPILOT_AGENT_DIRECTORIES="/shared/company-agents/security:/shared/company-agents/code-quality"

# Projects can still have local agents in .copilot-agents/ that take priority
```

---

## Advanced Patterns

### Multi-Stage Agents

Create agents that write files for later agents to consume:

**Agent 1: Security Scanner**
```markdown
# user.prompt.md
Scan for security issues and write findings to `SECURITY_FINDINGS.md`

Format each finding as:
## [SEVERITY] Issue Title
**Location:** file:line
**Description:** ...
**Remediation:** ...
```

**Agent 2: Fix Generator**
```markdown
# user.prompt.md
Read `SECURITY_FINDINGS.md` andgenerate fixes for all High and Critical issues.
Create a summary with proposed changes.
```

**Usage:**
```bash
./copilot-cli.sh --agents "security-scan,security-fix-gen" --agent-error-mode stop
```

**🎯 Working Example:** See [automation/examples/multi-stage-workflow/](automation/examples/multi-stage-workflow/) for a complete, ready-to-use multi-stage security analysis pipeline with detailed documentation, CI/CD integration examples, and troubleshooting guide.

### Technology-Specific Agents

Organize by technology:

```
.copilot-agents/
├── dotnet/
│   ├── async-patterns/
│   ├── dependency-injection/
│   └── entity-framework/
├── react/
│   ├── hooks-review/
│   ├── performance/
│   └── accessibility/
└── sql/
    ├── query-optimization/
    └── index-recommendations/
```

### Security-Focused Agents with Restricted Permissions

```properties
# copilot-cli.properties
allow.all.tools=false
allowed.tools=read_file,grep_search,list_dir
denied.tools=shell,bash,rm,write

# Read-only agent for security audits
allow.all.paths=false
```

###Team Agent Repository Pattern

```bash
# Company-wide shared agents
git clone git@company.com:platform/copilot-agents.git /shared/agents

# Projects reference shared agents
export COPILOT_AGENT_DIRECTORIES="/shared/agents:$HOME/.copilot-agents"

# Each project can override with local agents in .copilot-agents/
```

---

## Troubleshooting

### Agent Not Found

**Symptom:**
```
Error: Agent 'my-agent' not found
```

**Solutions:**

1. **List available agents:**
   ```bash
   ./copilot-cli.sh --list-agents
   ```

2. **Check agent directory exists:**
   ```bash
   ls -la .copilot-agents/
   ```

3. **Verify agent has required files:**
   ```bash
   ls -la .copilot-agents/my-agent/
   # Should have: copilot-cli.properties OR user.prompt.md OR *.agent.md
   ```

4. **Use explicit directory:**
   ```bash
   ./copilot-cli.sh --agent-directory .copilot-agents --agent my-agent
   ```

### Agent Found But Not Working

**Check file paths in properties:**
```properties
# ❌ Wrong - absolute paths
prompt.file=/full/path/to/user.prompt.md

# ✅ Correct - relative to agent directory
prompt.file=user.prompt.md
```

**Validate prompt files exist:**
```bash
cd .copilot-agents/my-agent/
test -f user.prompt.md && echo "✓ User prompt exists" || echo "✗ User prompt missing"
test -f *.agent.md && echo "✓ Agent definition exists" || echo "✗ Agent definition missing"
```

### Multiple Agents with Same Name

The first agent found wins. To see which agent is being used:

```bash
# Run with verbose logging
./copilot-cli.sh --agent my-agent --verbose
```

Look for discovery messages showing which directories are searched.

### Permission Denied in CI/CD

**Symptom:**
```
Error: Agent path not found: .copilot-agents/my-agent
```

**Solution:**
Ensure agent directory is committed to repository:

```bash
# Check .gitignore doesn't exclude .copilot-agents/
grep -r "copilot-agents" .gitignore

# Verify files are tracked
git ls-files .copilot-agents/
```

### Agent Works Locally But Not in CI

**Common causes:**

1. **Path differences:**
   ```yaml
   # Use relative paths from workspace root
   script: ./automation/copilot-cli.sh --agent my-agent
   ```

2. **Environment variables not set:**
   ```yaml
   env:
     COPILOT_AGENT_DIRECTORIES: "${CI_PROJECT_DIR}/.copilot-agents"
   ```

3. **Authentication missing:**
   ```yaml
   env:
     GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   ```

---

## Best Practices

### ✅ DO

- **Use `.copilot-agents/` directory** for project-specific agents
- **Commit agents to version control** so they're available in CI/CD
- **Write descriptive `description.txt`** files for each agent
- **Test agents locally** before using in CI/CD
- **Use specific, focused prompts** rather than generic ones
- **Include examples** in prompts for better results
- **Version agent configurations** alongside code

### ❌ DON'T

- **Don't use absolute paths** in agent configuration files
- **Don't commit sensitive tokens** in agent configs (use environment variables)
- **Don't create overly broad agents** - keep them focused
- **Don't skip the agent definition file** - it significantly improves results
- **Don't hardcode directory paths** - use discovery mechanisms

---

## Examples

### Example: Python Code Review Agent

```markdown
# .copilot-agents/python-review/user.prompt.md

Review this Python codebase for:

1. **Type Hints**
   - Missing type annotations on functions
   - Incorrect or incomplete types
   - Use of `Any` that should be more specific

2. **Async/Await Patterns**
   - Blocking I/O in async functions
   - Missing `await` keywords
   - Improper exception handling in async code

3. **Testing**
   - Functions without corresponding tests
   - Missing edge case coverage
   - Async test patterns

Provide specific file/line references and code examples for each issue.
```

### Example: Terraform Security Agent

```markdown
# .copilot-agents/terraform-security/user.prompt.md

Analyze Terraform configurations for security issues:

## Infrastructure Security
- [ ] Security groups with 0.0.0.0/0 access
- [ ] IAM policies with overly broad permissions
- [ ] Unencrypted storage resources
- [ ] Missing backup configurations
- [ ] Public access to databases

## Compliance
- [ ] Required tags (Environment, Owner, Cost Center)
- [ ] Naming convention adherence
- [ ] Region restrictions

Output findings in Markdown with severity levels and compliant examples.
```

---

## Additional Resources

- [Main README](README.md) - Quick start and overview
- [Automation README](automation/README.md) - Local script usage
- [GitHub Actions Integration](actions/README.md) - CI/CD workflows
- [Built-in Examples](automation/examples/README.md) - Example agents to learn from

---

## Contributing

Have a useful agent pattern to share? Submit a PR with:

1. Agent files in `automation/examples/your-agent/`
2. `description.txt` explaining use case
3. Example usage in `automation/examples/README.md`

---

**Need help?** Open an issue on GitHub or consult the troubleshooting section above.
