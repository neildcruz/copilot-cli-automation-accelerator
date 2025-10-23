# GitHub Copilot CLI Action - Quick Start Guide

This guide will help you get started with the GitHub Copilot CLI Action for automating code analysis, generation, and review tasks.

## 📋 Prerequisites

1. **GitHub Copilot Subscription**: Active Copilot subscription
2. **Repository Access**: Push access to configure workflows
3. **GitHub Token**: Ensure appropriate permissions for the workflow

## 🚀 Quick Start

### 1. Basic Setup

Copy the `copilot-cli-action.yml` file to your repository's `.github/workflows/` directory.

### 2. Simple Usage Example

Create a workflow file (e.g., `.github/workflows/code-review.yml`):

```yaml
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  ai-review:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Review this pull request for code quality, potential bugs, and best practices"
      allow_all_tools: true
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 📖 Common Use Cases

### Code Quality Analysis

```yaml
jobs:
  quality-check:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Analyze code quality and suggest improvements"
      copilot_model: "claude-sonnet-4.5"
      allow_all_tools: true
      log_level: "info"
```

### Security Vulnerability Scan

```yaml
jobs:
  security-scan:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      system_prompt: "Focus exclusively on security issues. Be thorough and provide specific CVE references where applicable."
      prompt: "Scan for security vulnerabilities and provide remediation suggestions"
      copilot_model: "gpt-5"
      allow_all_tools: false
      allowed_tools: "write,grep,find"
      denied_tools: "shell,bash"
```

### Documentation Generation

```yaml
jobs:
  generate-docs:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      system_prompt: "Write documentation in a clear, concise style following industry best practices. Include code examples and usage patterns."
      prompt: "Generate missing documentation and improve existing docs"
      allow_all_tools: true
      additional_directories: "./docs,./README.md"
```

### Test Generation

```yaml
jobs:
  generate-tests:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Analyze the code and generate comprehensive unit tests"
      allow_all_tools: true
      additional_directories: "./test,./tests"
      timeout_minutes: 25
```

## 🔧 MCP Server Integration

### Using Inline MCP Configuration

```yaml
jobs:
  custom-analysis:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Use custom tools to analyze the database schema"
      mcp_config: |
        {
          "mcpServers": {
            "db-analyzer": {
              "type": "local",
              "command": "python",
              "args": ["tools/db-analyzer.py"],
              "tools": ["*"],
              "env": {
                "DB_URL": "${DATABASE_URL}"
              }
            }
          }
        }
    secrets:
      MCP_ENV_VARS: |
        {
          "DATABASE_URL": "${{ secrets.DATABASE_URL }}"
        }
```

### Using External MCP Configuration File

1. Create `mcp-config.json` in your repository (see `examples/mcp-config.json` for reference)
2. Reference it in your workflow:

```yaml
jobs:
  external-mcp:
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Use external MCP configuration for analysis"
      mcp_config: "@examples/mcp-config.json"
    secrets:
      MCP_ENV_VARS: |
        {
          "API_TOKEN": "${{ secrets.API_TOKEN }}",
          "DATABASE_URL": "${{ secrets.DATABASE_URL }}"
        }
```

## 🔒 Security Best Practices

### 1. Tool Permissions

Always use the principle of least privilege:

```yaml
# ❌ Too permissive
allow_all_tools: true

# ✅ Specific permissions
allow_all_tools: false
allowed_tools: "write,grep,find"
denied_tools: "shell,bash,rm"
```

### 2. Path Access Control

Limit directory access:

```yaml
# ❌ Too broad
allow_all_paths: true

# ✅ Specific directories
allow_all_paths: false
additional_directories: "./src,./docs,./test"
```

### 3. Environment Variables

Store sensitive data in GitHub Secrets:

```yaml
secrets:
  MCP_ENV_VARS: |
    {
      "API_KEY": "${{ secrets.API_KEY }}",
      "DATABASE_URL": "${{ secrets.DATABASE_URL }}"
    }
```

## 🐛 Troubleshooting

### Common Issues

1. **Authentication Error**
   ```
   Error: No authentication information found
   ```
   **Solution**: Ensure `GITHUB_TOKEN` is properly configured

2. **MCP Server Failed to Start**
   ```
   Error: MCP server 'my-server' failed to start
   ```
   **Solution**: Check MCP configuration JSON syntax and environment variables

3. **Tool Permission Denied**
   ```
   Error: Tool 'shell' permission denied
   ```
   **Solution**: Add the tool to `allowed_tools` or use `allow_all_tools: true`

4. **Timeout Error**
   ```
   Error: The operation was canceled
   ```
   **Solution**: Increase `timeout_minutes` parameter

### Debugging Steps

1. **Enable Debug Logging**
   ```yaml
   with:
     log_level: "debug"
   ```

2. **Check Uploaded Artifacts**
   - Logs are automatically uploaded as artifacts
   - Review the "copilot-cli-logs" artifact after workflow completion

3. **Validate MCP Configuration**
   ```bash
   # Test MCP config locally
   cat mcp-config.json | jq .
   ```

4. **Test Tool Permissions**
   ```yaml
   # Start with minimal permissions and add as needed
   allowed_tools: "write"
   denied_tools: "shell,bash"
   ```

## 📊 Monitoring and Observability

### Workflow Summary

The action automatically creates a summary with:
- Executed prompt
- Model used
- Working directory
- Execution status
- Generated command

### Log Analysis

Access detailed logs through:
1. Workflow run logs in GitHub Actions
2. Uploaded log artifacts
3. Step-by-step execution details

### Performance Optimization

1. **Adjust Timeout**: Set appropriate `timeout_minutes`
2. **Use Specific Tools**: Avoid `allow_all_tools` when possible
3. **Limit Scope**: Use `working_directory` and `additional_directories`
4. **Choose Right Model**: Different models have different performance characteristics

## 📚 Advanced Examples

See the `example-copilot-usage.yml` file for comprehensive examples including:
- Multi-job workflows
- Conditional execution
- Custom MCP server integration
- Tool permission management
- Environment variable handling

## 🔄 Continuous Integration

Integrate with your CI/CD pipeline:

```yaml
name: CI with AI Analysis

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: npm test

  ai-analysis:
    needs: test
    if: success()
    uses: ./.github/workflows/copilot-cli-action.yml
    with:
      prompt: "Analyze test results and code coverage, suggest improvements"
      allow_all_tools: true
```

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review GitHub Actions logs
3. Validate your configuration syntax
4. Test with minimal permissions first

## 🤝 Contributing

When extending this action:
1. Test with various parameter combinations
2. Update documentation
3. Maintain backward compatibility
4. Add appropriate error handling