# GitHub Copilot CLI Local Scripts

> **New here?** Start with [../README.md](../README.md) for a 30-second quick start guide.

Local automation scripts providing the same functionality as the GitHub Action for local execution. Supports configuration via properties files and command line arguments.

## 📁 Script Files

- **`copilot-cli.sh`** - Bash shell script for Linux/macOS
- **`copilot-cli.ps1`** - PowerShell script for Windows/cross-platform
- **`copilot-cli.properties`** - Sample configuration file
- **`user.prompt.md`** - Default user prompt template
- **`system.prompt.md`** - Default system prompt template

## 🚀 Quick Start

**Prerequisites:** Node.js 20+, GitHub authentication (`gh auth login` or `GITHUB_TOKEN`). See [../README.md](../README.md) for details.

### Use a Pre-built Agent

```bash
# List available agents
./copilot-cli.sh --list-agents

# Run an agent
./copilot-cli.sh --agent code-review
./copilot-cli.sh --agent security-analysis
```

### Use Default Prompts (Zero-Config)

The default prompt files (`user.prompt.md` and `system.prompt.md`) now include working defaults that provide immediate value. Run a general-purpose code analysis with:

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

### Basic Usage

#### Bash (Linux/macOS)
```bash
# Make script executable
chmod +x copilot-cli.sh

# Basic usage
./copilot-cli.sh --prompt "Review the code for issues"

# With system prompt for guided behavior
./copilot-cli.sh --system-prompt "Focus only on security vulnerabilities" --prompt "Review this code"
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
system.prompt.file=system.prompt.md
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
    -s, --system-prompt TEXT       System instructions to guide AI behavior
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
    -SystemPrompt TEXT             System instructions to guide AI behavior
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

Check your environment:
```bash
# Check Node.js
node --version

# Check Copilot CLI
copilot --version

# Check GitHub authentication
gh auth status

# Check jq (optional but recommended)
jq --version
```

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