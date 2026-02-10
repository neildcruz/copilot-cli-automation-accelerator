# GitHub Copilot CLI Local Scripts - Reference

> **New here?** Start with the [Quick Start Guide](../README.md#-30-second-quick-start) in the main README.
> 
> **This document** is reference documentation for users already familiar with the basics.

Local automation scripts providing the same functionality as the GitHub Action for local execution. Supports configuration via properties files and command line arguments.

## 📁 Script Files

- **`copilot-cli.sh`** - Bash shell script for Linux/macOS
- **`copilot-cli.ps1`** - PowerShell script for Windows/cross-platform
- **`copilot-cli.properties`** - Sample configuration file
- **`user.prompt.md`** - Default user prompt template
- **`default.agent.md`** - Default agent definition file (YAML frontmatter + prompt body)

## 🚀 Quick Start

**Prerequisites:** Node.js 20+, GitHub authentication (`gh auth login` or `GITHUB_TOKEN`). See [../README.md](../README.md) for details.

**Having issues?** Run diagnostics: `./copilot-cli.sh --diagnose` (Bash) or `.\copilot-cli.ps1 -Diagnose` (PowerShell)

**Model Configuration:** Default model is `claude-sonnet-4.5`. To use a different model:
```bash
# Via command line
./copilot-cli.sh --model gpt-5 --agent code-review

# Via configuration file (copilot-cli.properties)
copilot.model=gpt-5

# Check available models
gh copilot models list
```

### Use a Pre-built Agent

```bash
# List available agents
./copilot-cli.sh --list-agents

# Run an agent
./copilot-cli.sh --agent code-review
./copilot-cli.sh --agent security-analysis
```

### Run Multiple Agents (Multi-Agent Composition)

Run multiple agents sequentially for comprehensive analysis:

```bash
# Bash - Run security analysis followed by code review
./copilot-cli.sh --agents "security-analysis,code-review"

# PowerShell
.\copilot-cli.ps1 -Agents "security-analysis,code-review"

# Control error behavior: 'continue' (default) runs all agents even if one fails
#                        'stop' aborts on first failure
./copilot-cli.sh --agents "security-analysis,code-review,test-generation" --agent-error-mode stop
.\copilot-cli.ps1 -Agents "security-analysis,code-review" -AgentErrorMode continue
```

**How it works:**
- Agents run sequentially in the order specified
- Each agent's output is saved to `~/.copilot-cli-automation/runs/{timestamp}/`
- A summary report shows pass/fail status and duration for each agent
- Agents share the working directory, so earlier agents can create files for later ones

**Output Location:**
Multi-agent run results are saved to:
```bash
~/.copilot-cli-automation/runs/{timestamp}/
├── agent-1-name.log
├── agent-2-name.log
├── agent-3-name.log
└── summary.md
```

**Designing prompts for sequential workflows:**
- Earlier agents can write marker files (e.g., `SECURITY_FINDINGS.md`)
- Later agents can check for and reference these files in their analysis
- Use `--agent-error-mode stop` if later agents depend on earlier ones succeeding

### Use Default Prompts (Zero-Config)

The default prompt files (`user.prompt.md` and `default.agent.md`) now include working defaults that provide immediate value. Run a general-purpose code analysis with:

```bash
# Bash - Use built-in default prompts
./copilot-cli.sh --use-defaults

# PowerShell
.\copilot-cli.ps1 -UseDefaults
```

The default prompts perform a comprehensive codebase analysis including:
- Project structure and architecture overview
- Code quality assessment and potential issues
- Security vulnerabilities and risky patterns
- Prioritized recommendations for improvement

---

## 🎯 Custom Agents

> **New!** Create your own specialized agents tailored to your codebase and team standards.

Custom agents are reusable configurations that combine prompts, settings, and tool permissions for specific analysis tasks. Perfect for CI/CD pipelines where you need consistent, repeatable code reviews.

### Quick Start: Create a Custom Agent

```bash
# Navigate to your project
cd /path/to/your/project

# Create a custom agent
./path/to/copilot-cli.sh --init --as-agent --agent-name "my-review"

# This creates:
# .copilot-agents/
#   my-review/
#     copilot-cli.properties
#     user.prompt.md
#     my-review.agent.md
#     description.txt

# Edit the prompts to match your needs
# Then run:
./path/to/copilot-cli.sh --agent my-review
```

```powershell
# PowerShell
.\path\to\copilot-cli.ps1 -Init -AsAgent -AgentName "my-review"
.\path\to\copilot-cli.ps1 -Agent my-review
```

### Agent Discovery

Agents are discovered in this order (first match wins):

1. **`--agent-directory` parameter** - Explicit primary directory
2. **`--additional-agent-directories`** - Additional search locations (comma-separated)
3. **`COPILOT_AGENT_DIRECTORIES` environment variable** - Colon(:) or semicolon(;) separated
4. **`.copilot-agents/` in current directory** - Recommended for project agents
5. **Built-in examples** - Fallback to bundled agents

### Using Custom Agents

```bash
# By name (searches directories)
./copilot-cli.sh --agent my-agent

# By relative path
./copilot-cli.sh --agent ./ci/agents/security-scan

# By absolute path
./copilot-cli.sh --agent /shared/company/agents/baseline

# List all available agents
./copilot-cli.sh --list-agents
```

### Configuration via Properties File

```properties
# copilot-cli.properties

# Custom agent directories
agent.directory=./.copilot-agents
additional.agent.directories=./team-agents,./ci-agents

# Other configuration...
```

### Complete Guide

For comprehensive documentation on creating and managing custom agents, see:
**[CUSTOM-AGENTS.md](../CUSTOM-AGENTS.md)**

Covers:
- Agent structure and anatomy
- CI/CD integration patterns
- Multi-project and organization-wide setups
- Advanced patterns and troubleshooting

---

### Basic Usage

#### Bash (Linux/macOS)
```bash
# Make script executable
chmod +x copilot-cli.sh

# Basic usage
./copilot-cli.sh --prompt "Review the code for issues"

# With an agent for guided behavior
./copilot-cli.sh --agent security-analysis --prompt "Review this code"
```

#### PowerShell (Windows/Cross-platform)
```powershell
# Basic usage
.\copilot-cli.ps1 -Prompt "Review the code for issues"

# Use a pre-built agent
.\copilot-cli.ps1 -Agent code-review
.\copilot-cli.ps1 -ListAgents
```

## � Authentication

GitHub Copilot CLI requires authentication to access the GitHub Copilot service. The scripts support multiple authentication methods for flexibility across different environments.

### Authentication Methods (Order of Precedence)

1. **Command Line Arguments** (highest priority)
   - Bash: `--github-token "ghp_xxxxxxxxxxxxxxxxxxxx"`
   - PowerShell: `-GithubToken "ghp_xxxxxxxxxxxxxxxxxxxx"`

2. **Properties File Configuration**
   - Add `github.token=ghp_xxxxxxxxxxxxxxxxxxxx` to your `.properties` file

3. **Environment Variables**
   - `GH_TOKEN` environment variable
   - `GITHUB_TOKEN` environment variable

4. **GitHub CLI Authentication** (lowest priority)
   - Existing authentication via `gh auth login`

### Setting Up a Personal Access Token (PAT)

1. **Create a fine-grained PAT:**
   - Visit [GitHub Personal Access Tokens](https://github.com/settings/personal-access-tokens/new)
   - Under "Permissions," click "add permissions" and select "Copilot Requests"
   - Generate your token

2. **Configure the token:**
   ```bash
   # Environment variable (recommended for CI/CD)
   export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
   export GH_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
   
   # Properties file (for project-specific configuration)
   echo "github.token=ghp_xxxxxxxxxxxxxxxxxxxx" >> copilot-cli.properties
   
   # Command line (for one-time use)
   ./copilot-cli.sh --github-token "ghp_xxxxxxxxxxxxxxxxxxxx" --prompt "Review code"
   ```

### Security Best Practices

- **Never commit tokens to version control**
- **Use environment variables in CI/CD pipelines**
- **Set minimal required permissions on PATs**
- **Rotate tokens regularly**
- **Use encrypted secrets management in production**

## �📖 Configuration

### Properties File Configuration

Create a `.properties` file with key=value pairs:

```properties
# Core settings
prompt.file=user.prompt.md
agent.file=default.agent.md
copilot.model=claude-sonnet-4.5
auto.install.cli=true

# GitHub Authentication
github.token=ghp_xxxxxxxxxxxxxxxxxxxx

# Tool permissions
allow.all.tools=true

# Working directory and path settings
working.directory=.
additional.directories=./src,./docs,./test

# MCP configuration
mcp.config.file=examples/mcp-config.json

# Tool permissions
allowed.tools=write,grep,find
denied.tools=shell,bash

# Directory access
additional.directories=./src,./docs,./test
working.directory=.

# Execution settings
log.level=info
timeout.minutes=30
```

### Command Line Arguments

All configuration options can be specified via command line arguments, which override properties file values.

#### Bash Script Options
```bash
./copilot-cli.sh [OPTIONS]

OPTIONS:
    -c, --config FILE               Configuration properties file
    -p, --prompt TEXT              The prompt to execute (required)
    -s, --agent-file FILE         Agent definition file (.agent.md) for AI behavior
    --use-defaults                 Use built-in default prompts for quick analysis
    -t, --github-token TOKEN       GitHub Personal Access Token for authentication
    -m, --model MODEL              AI model (gpt-5, claude-sonnet-4, claude-sonnet-4.5)
    --auto-install-cli BOOL        Automatically install Copilot CLI if not found (true/false)
    --mcp-config TEXT              MCP configuration as JSON string
    --mcp-config-file FILE         MCP configuration file path
    --allow-all-tools BOOL         Allow all tools (true/false)
    --allow-all-paths BOOL         Allow access to any path (true/false)
    --additional-dirs DIRS         Comma-separated directories
    --allowed-tools TOOLS          Comma-separated allowed tools
    --denied-tools TOOLS           Comma-separated denied tools
    --disable-builtin-mcps BOOL    Disable built-in MCP servers
    --disable-mcp-servers SERVERS  Comma-separated MCP servers to disable
    --enable-all-github-tools BOOL Enable all GitHub MCP tools
    --log-level LEVEL              Log level
    --working-dir DIR              Working directory
    --timeout MINUTES              Timeout in minutes
    --dry-run                      Show command without executing
    --verbose                      Enable verbose output
    -h, --help                     Show help
```

#### PowerShell Script Parameters
```powershell
.\copilot-cli.ps1 [PARAMETERS]

PARAMETERS:
    -Config FILE                    Configuration properties file
    -Prompt TEXT                   The prompt to execute (required)
    -AgentFile FILE                Agent definition file (.agent.md) for AI behavior
    -UseDefaults                   Use built-in default prompts for quick analysis
    -GithubToken TOKEN             GitHub Personal Access Token for authentication
    -Model MODEL                   AI model
    -AutoInstallCli BOOL           Automatically install Copilot CLI if not found (true/false)
    -McpConfig TEXT                MCP configuration as JSON string
    -McpConfigFile FILE            MCP configuration file path
    -AllowAllTools BOOL            Allow all tools
    -AllowAllPaths BOOL            Allow access to any path
    -AdditionalDirectories DIRS    Comma-separated directories
    -AllowedTools TOOLS            Comma-separated allowed tools
    -DeniedTools TOOLS             Comma-separated denied tools
    -DisableBuiltinMcps BOOL       Disable built-in MCP servers
    -DisableMcpServers SERVERS     Comma-separated MCP servers to disable
    -EnableAllGithubMcpTools BOOL  Enable all GitHub MCP tools
    -LogLevel LEVEL                Log level
    -WorkingDirectory DIR          Working directory
    -TimeoutMinutes MINUTES        Timeout in minutes
    -DryRun                        Show command without executing
    -Verbose                       Enable verbose output
    -Help                          Show help
```

## 🔧 MCP Server Integration

### Using External MCP Configuration File

1. **Create MCP configuration file** (e.g., `my-mcp-config.json`):
```json
{
  "mcpServers": {
    "database-tools": {
      "type": "local",
      "command": "python",
      "args": ["tools/db-analyzer.py"],
      "tools": ["analyze_schema", "query_data"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}",
        "API_KEY": "${API_KEY}"
      }
    },
    "api-client": {
      "type": "http",
      "url": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}"
      },
      "tools": ["*"]
    }
  }
}
```

2. **Configure in properties file**:
```properties
mcp.config.file=my-mcp-config.json
```

3. **Set environment variables**:
```bash
export DATABASE_URL="postgresql://localhost/mydb"
export API_KEY="your-secret-key"
export API_TOKEN="your-api-token"
```

### Using Inline MCP Configuration

```bash
# Bash
./copilot-cli.sh --prompt "Use custom tools" \
  --mcp-config '{"mcpServers":{"my-server":{"command":"node","args":["server.js"],"tools":["*"]}}}'

# PowerShell
.\copilot-cli.ps1 -Prompt "Use custom tools" `
  -McpConfig '{"mcpServers":{"my-server":{"command":"node","args":["server.js"],"tools":["*"]}}}'
```

## 🎯 Usage Examples

### 1. Basic Code Review
```bash
# Bash
./copilot-cli.sh --prompt "Review this codebase for quality and best practices"

# PowerShell
.\copilot-cli.ps1 -Prompt "Review this codebase for quality and best practices"
```

### 2. Security Analysis with Restricted Tools
```bash
# Bash
./copilot-cli.sh \
  --prompt "Scan for security vulnerabilities" \
  --allow-all-tools false \
  --allowed-tools "write,grep,find" \
  --denied-tools "shell,bash"

# PowerShell
.\copilot-cli.ps1 `
  -Prompt "Scan for security vulnerabilities" `
  -AllowAllTools false `
  -AllowedTools "write,grep,find" `
  -DeniedTools "shell,bash"
```

### 3. Documentation Generation
```bash
# Bash
./copilot-cli.sh \
  --prompt "Generate comprehensive documentation" \
  --additional-dirs "./docs,./README.md" \
  --working-dir "./src"

# PowerShell
.\copilot-cli.ps1 `
  -Prompt "Generate comprehensive documentation" `
  -AdditionalDirectories "./docs,./README.md" `
  -WorkingDirectory "./src"
```

### 4. Using Custom Configuration File
```bash
# Create custom config
cat > analysis-config.properties << EOF
prompt=Perform comprehensive code analysis
copilot.model=gpt-5
allow.all.tools=true
additional.directories=./src,./test
log.level=debug
timeout.minutes=45
EOF

# Use custom config
./copilot-cli.sh --config analysis-config.properties
```

### 5. MCP Integration with Database Tools
```properties
# db-analysis.properties
prompt=Analyze database schema and suggest optimizations
mcp.config.file=database-mcp-config.json
allow.all.tools=true
log.level=debug
```

```bash
# Set environment variables
export DATABASE_URL="postgresql://localhost:5432/myapp"
export DB_PASSWORD="secret"

# Run analysis
./copilot-cli.sh --config db-analysis.properties
```

### 6. Dry Run Mode
```bash
# See what command would be executed without running it
./copilot-cli.sh --prompt "Test prompt" --dry-run
```

## 🔒 Security Best Practices

### 1. Tool Permissions
Always use the principle of least privilege:
```properties
# Instead of
allow.all.tools=true

# Use specific permissions
allow.all.tools=false
allowed.tools=write,grep,find
denied.tools=shell,bash,rm
```

### 2. Path Access Control
Limit directory access:
```properties
# Instead of
allow.all.paths=true

# Use specific directories
allow.all.paths=false
additional.directories=./src,./docs,./test
```

### 3. Environment Variables
Store sensitive data in environment variables, not in properties files:
```bash
# Good - use environment variables
export API_KEY="secret-key"
export DATABASE_URL="postgresql://..."

# Avoid - don't put secrets in properties files
# api.key=secret-key  # Don't do this
```

### 4. MCP Configuration
Keep MCP configuration files secure and validate JSON:
```bash
# Validate MCP config before use
jq . my-mcp-config.json > /dev/null && echo "Valid JSON" || echo "Invalid JSON"
```

## 🐛 Troubleshooting

### Quick Diagnostics

Run the built-in diagnostic command to check all prerequisites at once:

```bash
# Bash
./copilot-cli.sh --diagnose

# PowerShell
.\copilot-cli.ps1 -Diagnose
```

The diagnostic command checks:
- Node.js version and installation
- npm availability
- GitHub Copilot CLI installation
- GitHub authentication (all token sources)
- Network connectivity to GitHub API
- Configuration files validity
- Built-in agents availability

Example output:
```
=========================================
  GitHub Copilot CLI - System Diagnostics
=========================================

Node.js:
  ✓ Version: v22.1.0 (meets requirement >=20)
  ✓ Path: /usr/local/bin/node

npm:
  ✓ Version: 10.2.0

GitHub Copilot CLI:
  ✓ Installed: 1.0.0

GitHub Authentication:
  ✓ GITHUB_TOKEN: Set (40 chars)
  ○ GH_TOKEN: Not set
  ✓ GitHub CLI: Authenticated

Network:
  ✓ GitHub API: Accessible

Configuration:
  ✓ Properties file: ./copilot-cli.properties
  ○ MCP config: Not found (will be skipped)

=========================================
  Ready to run: YES ✓
=========================================
```

### Common Issues

1. **Command not found: copilot**
   ```bash
   # Install Copilot CLI
   npm install -g @github/copilot
   ```

2. **Authentication errors**
   ```bash
   # Authenticate with GitHub
   gh auth login
   # Or set token
   export GITHUB_TOKEN="your-token"
   ```

3. **Node.js version errors**
   ```bash
   # Check Node.js version
   node --version
   # Upgrade if needed (requires Node.js 20+)
   ```

4. **MCP configuration errors**
   ```bash
   # Validate JSON syntax
   jq . your-mcp-config.json
   ```

5. **Permission denied (bash script)**
   ```bash
   # Make script executable
   chmod +x copilot-cli.sh
   ```

### Debug Mode

Enable verbose logging:
```bash
# Bash
./copilot-cli.sh --prompt "test" --verbose --log-level debug

# PowerShell
.\copilot-cli.ps1 -Prompt "test" -Verbose -LogLevel debug
```

### Environment Validation

Use the `--diagnose` command for comprehensive validation:
```bash
# Recommended: all-in-one check
./copilot-cli.sh --diagnose

# Or check components individually:
# Check Node.js
node --version

# Check Copilot CLI
copilot --version

# Check GitHub authentication
gh auth status

# Check jq (optional but recommended)
jq --version
```

## � Troubleshooting

### Run System Diagnostics

**First step for any issue:** Run the comprehensive diagnostic tool:

```bash
# Bash (Linux/macOS)
./copilot-cli.sh --diagnose
```

```powershell
# PowerShell (Windows)
.\copilot-cli.ps1 -Diagnose
```

**What it checks:**
- ✅ GitHub authentication status (all methods: `GITHUB_TOKEN`, `GH_TOKEN`, `gh` CLI)
- ✅ Node.js installation and version compatibility
- ✅ GitHub Copilot CLI installation status
- ✅ Agent discovery paths and directories
- ✅ Environment variables configuration
- ✅ MCP server configuration (if applicable)
- ✅ File permissions and accessibility

**Example output:**
```
SYSTEM DIAGNOSTICS
==================
✓ GitHub Authentication: GITHUB_TOKEN (configured)
✓ Node.js: v22.1.0 (compatible)
✓ Copilot CLI: Installed (v1.5.0)
✓ Agent Paths: .copilot-agents/ (found)
✓ MCP Config: Not configured (optional)
```

Share this output when reporting issues for faster resolution.

### Common Issues

**Agent not found:**
```bash
# List all available agents
./copilot-cli.sh --list-agents

# Verify agent directory structure
ls -la .copilot-agents/my-agent/
# Should contain: copilot-cli.properties, user.prompt.md, or *.agent.md
```

**Permission errors:**
```bash
# Make scripts executable (Linux/macOS)
chmod +x copilot-cli.sh

# PowerShell execution policy (Windows)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Authentication failures:**
```bash
# Verify GitHub authentication
gh auth status

# Or check environment variables
echo $GITHUB_TOKEN    # Bash
$env:GITHUB_TOKEN     # PowerShell
```

For more troubleshooting help, see [../INSTALL.md](../INSTALL.md#troubleshooting).
---

## 🌐 Shared Prompt Repositories

Pull pre-built prompts from GitHub repositories without downloading entire projects. This feature allows you to use community-created or organization-wide prompts.

### Use a Prompt from Default Repository

```bash
# List available prompts from default repo (github/awesome-copilot)
./copilot-cli.sh --list-prompts

# Use a specific prompt by name
./copilot-cli.sh --use-prompt code-review

# Search for prompts by keyword
./copilot-cli.sh --search-prompts "security"

# Get detailed information about a prompt
./copilot-cli.sh --prompt-info code-review
```

```powershell
# PowerShell equivalents
.\copilot-cli.ps1 -ListPrompts
.\copilot-cli.ps1 -UsePrompt "code-review"
.\copilot-cli.ps1 -SearchPrompts "security"
.\copilot-cli.ps1 -PromptInfo "code-review"
```

### Use Prompts from Custom Repositories

Specify a different repository using the format `owner/repo:prompt-name`:

```bash
# Use a prompt from your organization's repository
./copilot-cli.sh --use-prompt myorg/prompts:security-scan

# Use a prompt from a specific public repository
./copilot-cli.sh --use-prompt company/code-standards:python-review

# Set a different default repository for the session
./copilot-cli.sh --default-prompt-repo myorg/awesome-prompts --list-prompts
```

```powershell
# PowerShell
.\copilot-cli.ps1 -UsePrompt "myorg/prompts:security-scan"
.\copilot-cli.ps1 -DefaultPromptRepo "myorg/awesome-prompts" -ListPrompts
```

### Prompt Caching

Prompts are automatically cached locally to improve performance:

**Cache location:** `~/.copilot-cli-automation/prompt-cache/`

```bash
# Update cached prompts (refresh from repository)
./copilot-cli.sh --update-prompt-cache

# Use custom cache directory
./copilot-cli.sh --prompt-cache-dir /path/to/cache --use-prompt code-review
```

```powershell
# PowerShell
.\copilot-cli.ps1 -UpdatePromptCache
.\copilot-cli.ps1 -PromptCacheDir "C:\cache" -UsePrompt "code-review"
```

### Creating Shareable Prompts

To create prompts that others can use:

1. **Create a GitHub repository** with your prompts
2. **Organize prompts** in directories (e.g., `prompts/security/`, `prompts/code-review/`)
3. **Add description files** (`description.txt`) for each prompt
4. **Share the repository** with your team or make it public

Others can then use: `./copilot-cli.sh --use-prompt yourorg/yourrepo:prompt-name`

---

## 🔌 MCP Server Integration

**Model Context Protocol (MCP)** servers extend GitHub Copilot CLI with custom tools and capabilities beyond the built-in functionality.

### What Are MCP Servers?

MCP servers provide additional context and tools to the AI model during analysis:
- **Database Access** - Query application databases for schema or data context
- **API Integration** - Call internal APIs to gather system state
- **Custom Tools** - Add company-specific analysis or transformation tools
- **External Services** - Integrate with issue trackers, monitoring systems, documentation

### Quick Example: Python MCP Server

**1. Create a simple MCP server** (`tools/mcp-server.py`):

```python
# Example Python MCP server implementation
# See: https://modelcontextprotocol.io for full specification

import sys
import json
from mcp import MCPServer

server = MCPServer()

@server.tool("query_database")
def query_database(query: str) -> dict:
    """Query the application database"""
    # Your database query logic here
    return {"results": [], "message": "Query executed"}

if __name__ == "__main__":
    server.run()
```

**2. Configure MCP server** (`mcp-config.json`):

```json
{
  "mcpServers": {
    "database-tool": {
      "command": "python",
      "args": ["tools/mcp-server.py"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

**3. Run with MCP server:**

```bash
# Set environment variables
export DATABASE_URL="postgresql://localhost/mydb"

# Run with MCP configuration
./copilot-cli.sh --mcp-config-file mcp-config.json --agent code-review
```

### MCP Configuration Examples

See [examples/mcp-config.json](examples/mcp-config.json) for comprehensive examples including:
- Local Python servers
- Local Node.js servers  
- HTTP/REST endpoints
- Server-Sent Events (SSE) streams

### Available MCP Server Types

| Type | Use Case | Example |
|------|----------|---------|
| **Python Local** | Custom scripts, database access | `{"command": "python", "args": ["server.py"]}` |
| **Node.js Local** | JavaScript tools, file processing | `{"command": "node", "args": ["server.js"]}` |
| **HTTP/REST** | Remote APIs, cloud services | `{"url": "https://api.example.com/mcp"}` |
| **SSE Stream** | Real-time data, monitoring | `{"url": "...", "transport": "sse"}` |

### Security Considerations

- ⚠️ **Validate MCP server sources** before use
- ⚠️ **Review server permissions** and capabilities
- ⚠️ **Use environment variables** for sensitive configuration (not hardcoded)
- ⚠️ **Test MCP servers** in isolated environments first
- ✅ **Disable servers** when not needed: `--disable-mcp-servers server-name`

For more on MCP security, see [../SECURITY.md](../SECURITY.md#4-mcp-server-security).

---
## 💡 Tips and Best Practices

1. **Use configuration files** for repeated tasks
2. **Start with dry-run mode** to verify commands
3. **Use specific tool permissions** instead of allowing all tools
4. **Keep MCP configurations in separate files** for reusability
5. **Set appropriate timeouts** for complex analyses
6. **Use environment variables** for sensitive data
7. **Validate JSON configurations** before use
8. **Test with small prompts first** before running complex analyses

## 🔄 Integration with CI/CD

These scripts can be integrated into local development workflows or CI/CD pipelines:

```bash
# Pre-commit hook example
#!/bin/bash
./copilot-cli.sh --prompt "Quick security check of staged files" --timeout 5
```

```yaml
# GitHub Actions example
- name: Run local Copilot analysis
  run: |
    chmod +x copilot-cli.sh
    ./copilot-cli.sh --prompt "Analyze changes" --config ci-config.properties
```