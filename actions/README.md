# GitHub Copilot CLI Action

A reusable GitHub Action workflow that integrates the GitHub Copilot CLI with configurable parameters for automated code assistance, analysis, and generation.

## Features

- ✅ **Flexible Prompt Execution**: Execute any prompt with the Copilot CLI
- ✅ **MCP Server Support**: Configure custom MCP servers via JSON
- ✅ **Model Selection**: Choose between GPT-5, Claude Sonnet models
- ✅ **Tool Permission Management**: Fine-grained control over tool access
- ✅ **Path Access Control**: Configurable directory access permissions
- ✅ **Environment Variable Support**: Secure handling of MCP environment variables
- ✅ **Comprehensive Logging**: Detailed logs with configurable levels
- ✅ **Artifact Upload**: Automatic upload of logs and configuration files

## Usage

### As a Reusable Workflow

```yaml
name: Code Review with Copilot CLI

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  code-review:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Review the changes in this pull request and provide feedback on code quality, potential issues, and suggestions for improvement"
      copilot_model: "claude-sonnet-4.5"
      allow_all_tools: true
      log_level: "info"
      timeout_minutes: 15
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Manual Workflow Dispatch

You can also trigger the workflow manually from the GitHub Actions tab with custom parameters.

## Configuration Parameters

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| `prompt` | The prompt to execute with Copilot CLI | string |

### Optional Parameters

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `system_prompt` | System instructions to guide AI behavior (combined with prompt) | string | '' |
| `mcp_config` | MCP server configuration as JSON string or file path (prefix with @) | string | '' |
| `copilot_model` | AI model to use (gpt-5, claude-sonnet-4, claude-sonnet-4.5) | string | 'claude-sonnet-4.5' |
| `allow_all_tools` | Allow all tools to run automatically | boolean | true |
| `allow_all_paths` | Allow access to any path | boolean | false |
| `additional_directories` | Comma-separated list of additional directories to allow | string | '' |
| `allowed_tools` | Comma-separated list of allowed tools | string | '' |
| `denied_tools` | Comma-separated list of denied tools | string | '' |
| `disable_builtin_mcps` | Disable all built-in MCP servers | boolean | false |
| `disable_mcp_servers` | Comma-separated list of MCP servers to disable | string | '' |
| `enable_all_github_mcp_tools` | Enable all GitHub MCP tools | boolean | false |
| `log_level` | Log level (none, error, warning, info, debug, all, default) | string | 'info' |
| `working_directory` | Working directory to run the CLI from | string | '.' |
| `node_version` | Node.js version to use | string | '22' |
| `timeout_minutes` | Timeout for execution in minutes | number | 30 |

### Secrets

| Secret | Description | Required |
|--------|-------------|----------|
| `GITHUB_TOKEN` | GitHub token for authentication | No (uses default) |
| `MCP_ENV_VARS` | JSON object of environment variables for MCP servers | No |

## Examples

### 1. Simple Code Analysis

```yaml
jobs:
  analyze:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Analyze the codebase for potential security vulnerabilities"
      copilot_model: "gpt-5"
      allow_all_tools: true
```

### 2. Guided Analysis with System Prompt

```yaml
jobs:
  security-focused-review:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      system_prompt: "Focus only on security vulnerabilities and performance issues. Provide specific line numbers and actionable recommendations."
      prompt: "Review the changes in this pull request"
      copilot_model: "claude-sonnet-4.5"
      allow_all_tools: true
```

### 3. Custom MCP Server Integration

```yaml
jobs:
  custom-analysis:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Use the database tools to analyze the schema and suggest optimizations"
      mcp_config: |
        {
          "mcpServers": {
            "database-tools": {
              "type": "local",
              "command": "python",
              "args": ["database_mcp_server.py"],
              "tools": ["query_db", "analyze_schema"],
              "env": {
                "DB_CONNECTION": "${DATABASE_URL}"
              }
            }
          }
        }
      allow_all_tools: true
    secrets:
      MCP_ENV_VARS: |
        {
          "DATABASE_URL": "${{ secrets.DATABASE_URL }}"
        }
```

### 3. Restricted Tool Access

```yaml
jobs:
  safe-review:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Review the code changes and suggest improvements"
      allow_all_tools: false
      allowed_tools: "write,MyMCP(safe_tool)"
      denied_tools: "shell,MyMCP(dangerous_tool)"
      additional_directories: "./src,./docs"
```

### 4. Using External MCP Configuration File

First, create `mcp-config.json` in your repository:

```json
{
  "mcpServers": {
    "api-client": {
      "type": "http",
      "url": "https://api.mycompany.com/mcp",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}"
      },
      "tools": ["fetch_data", "update_records"]
    },
    "local-tools": {
      "type": "local",
      "command": "node",
      "args": ["tools/mcp-server.js"],
      "tools": ["*"]
    }
  }
}
```

Then use it in your workflow:

```yaml
jobs:
  api-integration:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Fetch latest data from the API and update our local files"
      mcp_config: "@mcp-config.json"
      allow_all_tools: true
    secrets:
      MCP_ENV_VARS: |
        {
          "API_TOKEN": "${{ secrets.API_TOKEN }}"
        }
```

### 5. PR Analysis with Custom Working Directory

```yaml
on:
  pull_request:
    paths:
      - 'backend/**'

jobs:
  backend-review:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Review the backend changes for performance and security issues"
      working_directory: "./backend"
      copilot_model: "claude-sonnet-4.5"
      log_level: "debug"
      timeout_minutes: 20
```

## MCP Server Environment Variables

When using MCP servers that require environment variables, use the `MCP_ENV_VARS` secret:

```yaml
secrets:
  MCP_ENV_VARS: |
    {
      "DATABASE_URL": "${{ secrets.DATABASE_URL }}",
      "API_KEY": "${{ secrets.API_KEY }}",
      "SECRET_TOKEN": "${{ secrets.SECRET_TOKEN }}"
    }
```

These variables will be available to your MCP servers using the standard environment variable expansion syntax:
- `${VAR}` or `$VAR`: Direct expansion
- `${VAR:-default}`: Use default if VAR is not set

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Ensure `GITHUB_TOKEN` has appropriate permissions
2. **MCP Server Failures**: Check MCP configuration JSON syntax and environment variables
3. **Tool Permission Errors**: Verify tool names and permission patterns
4. **Timeout Issues**: Increase `timeout_minutes` for complex prompts

### Debugging

Enable debug logging:

```yaml
with:
  log_level: "debug"
```

Logs are automatically uploaded as artifacts for review.

## Security Considerations

- **Tool Permissions**: Use specific tool allowlists instead of `allow_all_tools` when possible
- **Path Access**: Limit directory access with `additional_directories` instead of `allow_all_paths`
- **Environment Variables**: Store sensitive data in GitHub Secrets
- **MCP Servers**: Validate external MCP server configurations and endpoints

## Contributing

When modifying this action:

1. Test changes with various parameter combinations
2. Update documentation for new parameters
3. Ensure backward compatibility
4. Add appropriate error handling