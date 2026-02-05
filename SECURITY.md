# Security Policy

## Supported Versions

We actively maintain and provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please report it responsibly.

### How to Report

**Do NOT open a public issue for security vulnerabilities.**

Instead, please report security issues by:

1. **Email**: Contact the maintainer directly (check GitHub profile for contact information)
2. **GitHub Security Advisories**: Use the "Security" tab in the repository to report privately
3. **Provide details**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: We'll acknowledge receipt within 48 hours
- **Assessment**: We'll assess the vulnerability and determine severity
- **Updates**: We'll keep you informed of progress
- **Resolution**: We'll work on a fix and coordinate disclosure
- **Credit**: You'll be credited for the discovery (unless you prefer to remain anonymous)

## Security Best Practices

### For Users of This Automation Suite

#### 1. GitHub Token Security

- **Never commit tokens** to version control
- **Use GitHub Secrets** for Actions workflows
- **Use environment variables** for local scripts
- **Rotate tokens regularly**
- **Use minimal permissions** (principle of least privilege)

#### 2. Tool Permissions

The automation suite provides granular control over tool permissions:

```yaml
# Restrictive configuration
allowed_tools: "read,grep,find"
denied_tools: "shell,bash,write"
```

- **Review tool permissions** before running
- **Deny dangerous tools** unless necessary
- **Use allow lists** instead of deny lists when possible

#### 3. Path Restrictions

Limit filesystem access to specific directories:

```yaml
additional_directories: "./src,./docs"
```

- **Restrict access** to necessary paths only
- **Avoid root directory** access
- **Use absolute paths** for clarity

#### 4. MCP Server Security

When using Model Context Protocol servers:

- **Validate MCP server sources** before use
- **Review server permissions** and capabilities
- **Use environment variables** for sensitive configuration
- **Avoid hardcoded credentials** in MCP configs
- **Test MCP servers** in isolated environments first

#### 5. Environment Variables

```yaml
secrets:
  MCP_ENV_VARS: |
    {
      "DATABASE_URL": "${{ secrets.DATABASE_URL }}",
      "API_TOKEN": "${{ secrets.API_TOKEN }}"
    }
```

- **Use GitHub Secrets** for sensitive data
- **Never log** environment variable values
- **Validate input** from environment variables
- **Limit variable scope**

#### 6. Workflow Security

For GitHub Actions:

- **Pin action versions** to specific commits or tags
- **Review workflow changes** in pull requests
- **Use CODEOWNERS** for workflow files
- **Enable branch protection** for main branches
- **Require PR reviews** for workflow changes

#### 7. Code Review and AI Automation

- **Review AI-generated changes** before committing
- **Validate suggestions** against security best practices
- **Test changes** in non-production environments
- **Use version control** for all changes
- **Keep audit trails** of automated changes

### For Contributors

- **Follow secure coding practices**
- **Validate all inputs**
- **Handle errors gracefully**
- **Avoid shell injection vulnerabilities**
- **Use parameterized commands**
- **Review dependencies** for known vulnerabilities
- **Test security-related changes** thoroughly

## Known Security Considerations

### 1. GitHub Copilot CLI Access

The automation suite executes GitHub Copilot CLI with configured permissions. The CLI can:

- Read and write files (if permitted)
- Execute shell commands (if permitted)
- Access environment variables
- Interact with the filesystem

**Mitigation**: Use tool restrictions and path limitations to control access.

### 2. MCP Server Execution

MCP servers can execute arbitrary code based on configuration.

**Mitigation**: 
- Only use trusted MCP servers
- Review server code before use
- Limit server permissions
- Run in isolated environments when possible

### 3. Secrets in Logs

Automation logs may inadvertently contain sensitive information.

**Mitigation**:
- Avoid logging sensitive data
- Use GitHub's automatic secret masking
- Review logs before sharing
- Implement log filtering for known patterns

### 4. Third-Party Dependencies

The suite depends on external packages and tools.

**Mitigation**:
- Keep dependencies updated
- Monitor security advisories
- Use dependency scanning tools
- Review dependency changes

## Security Update Process

1. **Vulnerability discovered** or reported
2. **Assessment and verification**
3. **Fix developed** and tested
4. **Security advisory** published (if applicable)
5. **Fix released** with version bump
6. **Users notified** via GitHub releases
7. **Documentation updated**

## Additional Resources

- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE/SANS Top 25](https://www.sans.org/top25-software-errors/)

## Questions?

For general security questions about using this automation suite, please open a GitHub Discussion. For vulnerability reports, follow the reporting process above.

---

**Last Updated**: February 2026
