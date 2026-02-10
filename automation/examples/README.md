# GitHub Copilot CLI Agent Examples

> **Quick Access:** Run `./copilot-cli.sh --list-agents` from the `automation/` directory to see all available agents.
>
> **Use an Agent:** Run `./copilot-cli.sh --agent code-review` to use an agent directly.

This directory contains ready-to-use agent configuration examples for various Software Development Lifecycle (SDLC) tasks.

## 📁 Directory Structure

```
examples/
├── code-review/              - Code quality and best practices review
│   ├── code-review-agent.properties
│   ├── user.prompt.md
│   └── code-review.agent.md
├── security-analysis/        - Security vulnerability scanning
│   ├── security-analysis-agent.properties
│   ├── user.prompt.md
│   └── security-analysis.agent.md
├── test-generation/          - Unit and integration test generation
│   ├── test-generation-agent.properties
│   ├── user.prompt.md
│   └── test-generation.agent.md
├── documentation-generation/ - Technical documentation creation
│   ├── documentation-generation-agent.properties
│   ├── user.prompt.md
│   └── documentation-generation.agent.md
├── refactoring/              - Code structure improvements
│   ├── refactoring-agent.properties
│   ├── user.prompt.md
│   └── refactoring.agent.md
├── cicd-analysis/            - CI/CD pipeline optimization
│   ├── cicd-analysis-agent.properties
│   ├── user.prompt.md
│   └── cicd-analysis.agent.md
└── mcp-config.json           - MCP server configuration example
```

## � Multi-Stage Workflows

### **Multi-Stage Security Analysis Pipeline**
**Location:** `multi-stage-workflow/`

Demonstrates agents working together in sequence, with later stages consuming output from earlier stages.

**Workflow:**
1. **Stage 1: Scanner** - Scans codebase, writes `SECURITY_FINDINGS.md`
2. **Stage 2: Fixer** - Reads findings, generates fixes to `SECURITY_FIXES.md`

**Usage:**
```bash
# Run both stages sequentially
./copilot-cli.sh --agents "multi-stage-workflow/stage-1-scanner,multi-stage-workflow/stage-2-fixer"

# Run stages individually
./copilot-cli.sh --agent multi-stage-workflow/stage-1-scanner
./copilot-cli.sh --agent multi-stage-workflow/stage-2-fixer
```

**Learn More:** See [multi-stage-workflow/README.md](multi-stage-workflow/README.md) for complete documentation, customization guide, and CI/CD integration examples.

**Key Pattern:** Agents communicate through files, allowing:
- Audit trails of multi-step analysis
- Manual review between stages  
- Modular, reusable pipeline components

---

## �📁 Available Agents

### 1. **Code Review Agent**
**Location:** `code-review/code-review-agent.properties`

Performs comprehensive code quality and best practices review.

**Configuration:**
- Pre-configured user prompt and agent definition files
- Full tool permissions enabled
- 30-minute timeout
- Uses Claude Sonnet 4.5 model

**Focus Areas:**
- Code quality and maintainability
- Design patterns and best practices
- Performance optimization opportunities
- Error handling and edge cases
- Code consistency and style
- Potential bugs or logic errors

**Usage:**
```bash
# Bash
cd automation
./copilot-cli.sh --config examples/code-review/code-review-agent.properties

# PowerShell
cd automation
.\copilot-cli.ps1 -Config "examples\code-review\code-review-agent.properties"

# Override prompt if needed
./copilot-cli.sh --config examples/code-review/code-review-agent.properties --prompt "Focus on the authentication module"
```

---

### 2. **Security Analysis Agent**
**Location:** `security-analysis/security-analysis-agent.properties`

Conducts thorough security vulnerability scanning with severity ratings.

**Configuration:**
- Pre-configured security-focused prompts
- **Restricted tool permissions** (write, grep, find only)
- Denies shell/bash execution for safety
- 30-minute timeout
- Uses Claude Sonnet 4.5 model

**Focus Areas:**
- SQL injection, XSS, and CSRF vulnerabilities
- Authentication and authorization flaws
- Sensitive data exposure and encryption issues
- Insecure dependencies and known CVEs
- Input validation and sanitization gaps
- Security misconfigurations
- Hard-coded secrets, tokens, or credentials

**Security Features:**
- Restricted tool permissions (read-only tools only)
- No shell/bash execution allowed
- Safe file operations only

**Usage:**
```bash
# Bash
cd automation
./copilot-cli.sh --config examples/security-analysis/security-analysis-agent.properties

# PowerShell
cd automation
.\copilot-cli.ps1 -Config "examples\security-analysis\security-analysis-agent.properties"
```

---

### 3. **Test Generation Agent**
**Location:** `test-generation/test-generation-agent.properties`

Generates comprehensive unit and integration tests with high coverage.

**Configuration:**
- Pre-configured test generation prompts
- Full tool permissions enabled
- Includes test directories (./test, ./tests, ./spec)
- 45-minute timeout for complex test generation
- Uses Claude Sonnet 4.5 model

**Focus Areas:**
- Comprehensive unit tests with high code coverage
- Integration tests for critical workflows
- Testing best practices (AAA pattern, descriptive names)
- Edge cases, boundary conditions, and error scenarios
- Appropriate test doubles (mocks, stubs, fakes)
- Maintainable, readable test code
- Independent and repeatable tests

**Usage:**
```bash
# Bash
cd automation
./copilot-cli.sh --config examples/test-generation/test-generation-agent.properties

# PowerShell
cd automation
.\copilot-cli.ps1 -Config "examples\test-generation\test-generation-agent.properties"
```

---

### 4. **Documentation Generation Agent**
**Location:** `documentation-generation/documentation-generation-agent.properties`

Creates comprehensive technical documentation in Markdown format.

**Configuration:**
- Pre-configured documentation generation prompts
- Full tool permissions enabled
- Includes docs directories (./docs, ./README.md, ./CHANGELOG.md)
- 45-minute timeout for comprehensive documentation
- Uses Claude Sonnet 4.5 model

**Focus Areas:**
- Clear, concise, and accurate documentation
- Documentation best practices (structure, formatting)
- API documentation with examples
- Architecture and design decisions
- User-friendly setup and usage guides
- Code examples and diagrams
- Consistent style and terminology

**Generated Documentation:**
- README.md updates
- API documentation
- Architecture documentation
- Developer setup guides
- User guides with examples
- Configuration documentation
- CHANGELOG.md

**Usage:**
```bash
# Bash
cd automation
./copilot-cli.sh --config examples/documentation-generation/documentation-generation-agent.properties

# PowerShell
cd automation
.\copilot-cli.ps1 -Config "examples\documentation-generation\documentation-generation-agent.properties"
```

---

### 5. **Code Refactoring Agent**
**Location:** `refactoring/refactoring-agent.properties`

Improves code structure, quality, and maintainability.

**Configuration:**
- Pre-configured refactoring prompts
- Full tool permissions enabled
- 45-minute timeout for complex refactoring
- Uses Claude Sonnet 4.5 model

**Focus Areas:**
- Improving code structure and organization
- Eliminating code duplication (DRY principle)
- Simplifying complex logic and reducing cognitive load
- Applying design patterns appropriately
- Improving naming conventions for clarity
- Enhancing modularity and separation of concerns
- Maintaining backward compatibility

**Refactoring Activities:**
- Identifying code smells and technical debt
- Extracting reusable functions and modules
- Simplifying complex conditional logic
- Improving error handling patterns
- Standardizing naming conventions
- Breaking down large functions/classes
- Removing dead code and unused dependencies

**Usage:**
```bash
# Bash
cd automation
./copilot-cli.sh --config examples/refactoring/refactoring-agent.properties

# PowerShell
cd automation
.\copilot-cli.ps1 -Config "examples\refactoring\refactoring-agent.properties"
```

---

### 6. **CI/CD Pipeline Analysis Agent**
**Location:** `cicd-analysis/cicd-analysis-agent.properties`

Analyzes and optimizes CI/CD pipeline configurations.

**Configuration:**
- Pre-configured DevOps/CI/CD analysis prompts
- Full tool permissions enabled
- Includes CI/CD directories (.github, .gitlab, azure-pipelines.yml, Jenkinsfile)
- 30-minute timeout
- Uses Claude Sonnet 4.5 model

**Focus Areas:**
- Pipeline efficiency and build times
- Security issues in CI/CD configurations
- Caching and dependency management optimization
- Pipeline parallelization improvements
- Deployment strategies and rollback procedures
- Secrets management best practices
- Test coverage and quality gates validation

**Supported Platforms:**
- GitHub Actions (.github/workflows)
- GitLab CI (.gitlab-ci.yml)
- Azure Pipelines (azure-pipelines.yml)
- Jenkins (Jenkinsfile)

**Usage:**
```bash
# Bash
cd automation
./copilot-cli.sh --config examples/cicd-analysis/cicd-analysis-agent.properties

# PowerShell
cd automation
.\copilot-cli.ps1 -Config "examples\cicd-analysis\cicd-analysis-agent.properties"
```

---

## 🚀 Quick Start

**Prerequisites:** Node.js 20+, GitHub authentication. See [../../README.md](../../README.md) for details.

### Running an Agent

**Option 1: Use --agent flag (Recommended)**
```bash
# List available agents
./copilot-cli.sh --list-agents

# Run an agent by name
./copilot-cli.sh --agent code-review
./copilot-cli.sh --agent security-analysis
./copilot-cli.sh --agent test-generation
```

**Option 2: Using Properties Files Directly**
```bash
# Bash
cd automation
./copilot-cli.sh --config examples/code-review/copilot-cli.properties

# PowerShell
cd automation
.\copilot-cli.ps1 -Config "examples\code-review\copilot-cli.properties"
```

---

## ⚙️ Customization

### Modifying Agent Definition Files

Agent definition files (`.agent.md`) define the AI's behavior, expertise, and available tools using YAML frontmatter. Edit them in the `{name}.agent.md` files to:
- Add specific focus areas
- Change tone or style
- Add domain-specific knowledge
- Modify output format
- Configure available tools

**Example:**
```markdown
# Custom Agent Definition

You are an expert code reviewer specializing in Python.
Focus on Pythonic patterns, PEP 8 compliance, and type hints.
Provide specific examples with PEP references where applicable.
```

### Modifying User Prompts

User prompts define the specific task. Customize them in the `user.prompt.md` files to:
- Target specific files or directories
- Focus on particular aspects
- Change scope or depth of analysis
- Add project-specific requirements

**Example:**
```markdown
# Custom User Prompt

Review only the authentication module in src/auth/.
Focus on JWT implementation and session management.
Check for OAuth 2.0 best practices.
```

### Creating Custom Properties Files

Create a new `.properties` file with your custom configuration:

```properties
# custom-agent.properties

# Core configuration
prompt.file=user.prompt.md
agent.file=custom-agent.agent.md

# Model selection
copilot.model=claude-sonnet-4.5

# Tool permissions
allow.all.tools=true
# or restrict tools
# allow.all.tools=false
# allowed.tools=write,grep,find

# Additional directories
additional.directories=./src,./lib,./custom-dir

# Execution settings
log.level=info
timeout.minutes=30

# GitHub authentication
github.token=ghp_xxxxxxxxxxxxxxxxxxxx
```

Then use it:
```bash
./copilot-cli.sh --config custom-agent.properties
```

---

## 🔐 Authentication

All agents require GitHub authentication to access the Copilot service.

### Setting Up Authentication

**Option 1: Environment Variables (Recommended for CI/CD)**
```bash
# Bash/Linux/macOS
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
export GH_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx

# PowerShell
$env:GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
$env:GH_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
```

**Option 2: Properties File (Recommended for Local Development)**
```properties
github.token=ghp_xxxxxxxxxxxxxxxxxxxx
```

**Option 3: Command Line (One-time Use)**
```bash
# Bash
./agent.sh  # Will use env var or properties file

# PowerShell
.\agent.ps1  # Will use env var or properties file
```

### Creating a Personal Access Token

1. Visit [GitHub Personal Access Tokens](https://github.com/settings/personal-access-tokens/new)
2. Under "Permissions," click "add permissions"
3. Select "Copilot Requests"
4. Generate your token
5. Configure it using one of the methods above

---

## 🎯 Usage Patterns

### 1. Development Workflow Integration

**Pre-Commit Code Review:**
```bash
#!/bin/bash
# .git/hooks/pre-commit
cd automation
./copilot-cli.sh --config examples/code-review/code-review-agent.properties
```

**Automated Security Scans:**
```bash
# Daily security scan via cron
0 9 * * * cd /path/to/project/automation && ./copilot-cli.sh --config examples/security-analysis/security-analysis-agent.properties
```

### 2. CI/CD Integration

**GitHub Actions Example:**
```yaml
name: Code Review Agent

on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - name: Run Code Review
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          cd automation
          chmod +x copilot-cli.sh
          ./copilot-cli.sh --config examples/code-review/code-review-agent.properties
```

### 3. Running Multiple Agents

**Sequential Execution:**
```bash
#!/bin/bash
# run-all-agents.sh

cd automation

echo "Running Code Review..."
./copilot-cli.sh --config examples/code-review/code-review-agent.properties

echo "Running Security Analysis..."
./copilot-cli.sh --config examples/security-analysis/security-analysis-agent.properties

echo "Running Test Generation..."
./copilot-cli.sh --config examples/test-generation/test-generation-agent.properties

echo "All agents completed!"
```

---

## 📊 Agent Comparison

| Agent | Runtime | Tool Access | Output Type | Best For |
|-------|---------|-------------|-------------|----------|
| Code Review | 30 min | Full | Analysis Report | PR reviews, quality audits |
| Security Analysis | 30 min | Restricted | Security Report | Security audits, compliance |
| Test Generation | 45 min | Full | Test Files | Coverage improvement |
| Documentation | 45 min | Full | Markdown Files | Documentation updates |
| Refactoring | 45 min | Full | Code Changes | Technical debt reduction |
| CI/CD Analysis | 30 min | Full | Analysis Report | Pipeline optimization |

---

## 🔧 Troubleshooting

### Common Issues

**1. Agent Not Running**
```bash
# Check Node.js version
node --version  # Should be 20+

# Check Copilot CLI installation
copilot --version

# Install if missing
npm install -g @github/copilot
```

**2. Authentication Errors**
```bash
# Verify token is set
echo $GITHUB_TOKEN  # Bash
echo $env:GITHUB_TOKEN  # PowerShell

# Test GitHub CLI auth
gh auth status

# Re-authenticate if needed
gh auth login
```

**3. Permission Errors (Bash)**
```bash
# Make scripts executable
chmod +x *.sh
```

**4. Script Not Found**
```bash
# Ensure you're in the correct directory
cd automation/examples
pwd
```

### Debug Mode

Enable verbose logging for troubleshooting:

**Bash:**
```bash
./agent.sh --verbose --log-level debug
```

**PowerShell:**
```powershell
.\agent.ps1 -Verbose -LogLevel debug
```

---

## 💡 Best Practices

### 1. Start Small
Begin with a single agent on a small codebase to understand output and behavior.

### 2. Review Agent Output
Always review agent suggestions before implementing changes.

### 3. Customize Prompts
Tailor system and user prompts to your project's specific needs.

### 4. Use Appropriate Timeouts
Increase timeout for larger codebases:
```properties
timeout.minutes=60
```

### 5. Leverage Properties Files
Create reusable configurations for consistent results.

### 6. Combine with Manual Review
Use agents to augment, not replace, human expertise.

### 7. Iterate on Prompts
Refine prompts based on output quality and relevance.

---

## 🔄 Using These Examples as Templates

> **Important:** These examples are **built-in agents** that work out-of-the-box. To create your own **custom agents** for CI/CD, see the guide below.

You can use these examples as starting points for your own custom agents:

### Option 1: Create Custom Agent from Scratch (Recommended)

```bash
# Navigate to your project
cd /path/to/your/project

# Create a new custom agent with templates
./path/to/copilot-cli.sh --init --as-agent --agent-name "my-agent"

# This creates .copilot-agents/my-agent/ with:
#   - copilot-cli.properties
#   - user.prompt.md
#   - my-agent.agent.md
#   - description.txt

# Edit the prompts to match your needs
# Run your custom agent
./path/to/copilot-cli.sh --agent my-agent
```

```powershell
# PowerShell (Windows)
.\path\to\copilot-cli.ps1 -Init -AsAgent -AgentName "my-agent"
.\path\to\copilot-cli.ps1 -Agent my-agent
```

### Option 2: Copy Example as Starting Point

```bash
# Copy an example to your project's .copilot-agents/ directory
mkdir -p .copilot-agents/
cp -r path/to/automation/examples/code-review/ .copilot-agents/my-code-review/

# Customize for your needs
cd .copilot-agents/my-code-review/
nano user.prompt.md
nano my-code-review.agent.md

# Use your customized agent
cd ../..
./path/to/copilot-cli.sh --agent my-code-review
```

### Option 3: Reference by Path

```bash
# Use any agent from any location without moving files
./copilot-cli.sh --agent ./path/to/custom/agent/directory
./copilot-cli.sh --agent /absolute/path/to/agent
```

### For CI/CD Pipelines

Custom agents in your project's `.copilot-agents/` directory are automatically discovered and perfect for CI/CD:

```yaml
# .github/workflows/review.yml
name: Code Review
on: [pull_request]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install
        run: curl -fsSL https://... | bash
      - name: Run Custom Agent
        run: |
          # Your agent in .copilot-agents/ is auto-discovered
          ./copilot-cli-automation-accelerator/automation/copilot-cli.sh \
            --agent my-custom-review
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Complete Custom Agent Guide

For comprehensive documentation on creating, organizing, and using custom agents:

**See [CUSTOM-AGENTS.md](../../CUSTOM-AGENTS.md)**

Covers:
- Agent structure and file anatomy
- Discovery priority and search paths
- CI/CD integration examples
- Multi-project and organization-wide patterns
- Advanced usage and troubleshooting

---

### Template Structure

**Bash Script Template:**
```bash
#!/bin/bash

# [Agent Name] - Bash Script
# [Description]

cd "$(dirname "$0")/.."

./copilot-cli.sh \
  --prompt-file "examples/[agent-folder]/user.prompt.md" \
  --agent-file "examples/[agent-folder]/[agent-name].agent.md" \
  --model claude-sonnet-4.5 \
  --allow-all-tools true \
  --log-level info \
  --timeout 30 \
  --verbose
```

**PowerShell Script Template:**
```powershell
# [Agent Name] - PowerShell Script
# [Description]

Set-Location (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
Set-Location ".\automation"

.\copilot-cli.ps1 `
  -PromptFile "examples\[agent-folder]\user.prompt.md" `
  -AgentFile "examples\[agent-folder]\[agent-name].agent.md" `
  -Model "claude-sonnet-4.5" `
  -AllowAllTools "true" `
  -LogLevel "info" `
  -TimeoutMinutes 30 `
  -Verbose
```

**Properties File Template:**
```properties
# [Agent Name] Configuration
# [Description]

prompt.file=user.prompt.md
agent.file=[agent-name].agent.md

copilot.model=claude-sonnet-4.5
allow.all.tools=true
log.level=info
timeout.minutes=30

# github.token=ghp_xxxxxxxxxxxxxxxxxxxx
```

---

## 📚 Additional Resources

- [Parent README](../README.md) - Main documentation for copilot-cli scripts
- [GitHub Actions README](../../actions/README.md) - GitHub Actions integration
- [GitHub Copilot CLI Documentation](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line)
- [MCP Configuration Example](./mcp-config.json) - Custom tool integration

---

## 🤝 Contributing

To add new agent examples:

1. Create the agent scripts (`.sh` and `.ps1`)
2. Create the properties file (`.properties`)
3. Add documentation to this README
4. Test on multiple platforms
5. Submit a pull request

---

## 📝 License

These examples are part of the copilot-cli-automation-accelerator project.
See the main repository for license information.
