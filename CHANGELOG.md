# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- MIT License
- Contributing guidelines (CONTRIBUTING.md)
- Security policy (SECURITY.md)
- This changelog
- EditorConfig for consistent coding styles
- Enhanced .gitignore with comprehensive patterns
- CODEOWNERS for automatic PR reviewer assignment

## [1.0.0] - Initial Release

### Added
- GitHub Actions reusable workflow for Copilot CLI automation
- Cross-platform automation scripts (Bash and PowerShell)
- Configuration management via properties files
- System and user prompt templates
- MCP (Model Context Protocol) server integration support
- Comprehensive documentation and examples
- Example agent configurations:
  - Code review automation
  - Security analysis
  - Test generation
  - Documentation generation
  - Code refactoring
  - CI/CD analysis
- CI/CD platform integration guides:
  - GitHub Actions
  - Azure Pipelines
  - AWS CodePipeline
  - GitLab CI
  - CircleCI
  - Jenkins
  - Bitbucket Pipelines
- One-line installation scripts for Windows and Unix-based systems
- Tool permission management
- Path restriction capabilities
- Environment variable support
- Sample CLI agents:
  - Issue-to-PR automation
  - GitHub Actions cost analysis

### Features
- **GitHub Actions Integration**
  - Reusable workflow configuration
  - Manual dispatch support
  - Pull request triggers
  - Scheduled execution
  - Multi-job workflow support

- **Local Automation**
  - Properties-based configuration
  - Command-line parameter overrides
  - MCP server configuration (JSON and external files)
  - Auto-installation of Copilot CLI
  - Cross-platform compatibility

- **Security**
  - Granular tool permissions (allow/deny lists)
  - Path restrictions
  - Environment variable validation
  - GitHub token management
  - Secret handling via GitHub Secrets

- **Flexibility**
  - Multiple AI model support (GPT-5, Claude Sonnet)
  - Configurable timeouts
  - Custom system prompts
  - MCP server integration (Python, Node.js, HTTP, SSE)
  - Comprehensive logging

---

## How to Update This Changelog

When contributing changes, please update this file following these guidelines:

### Categories
- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security vulnerability fixes

### Format
```markdown
## [Version] - YYYY-MM-DD

### Category
- Description of change (#PR-number)
- Another change (#PR-number)
```

### Unreleased Section
Add changes to the `[Unreleased]` section as they are merged. When releasing a new version:
1. Change `[Unreleased]` to `[Version] - Date`
2. Add a new `[Unreleased]` section at the top
3. Update version comparison links at the bottom

---

[Unreleased]: https://github.com/neildcruz/copilot-cli-automation-accelerator/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/neildcruz/copilot-cli-automation-accelerator/releases/tag/v1.0.0
