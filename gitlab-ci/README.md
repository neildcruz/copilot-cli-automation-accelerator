# GitLab CI Integration

> 🚧 **Coming Soon** - This folder will contain GitLab CI pipeline templates for Copilot CLI automation.

## Planned Contents

| File | Description |
|------|-------------|
| `copilot-cli-gitlab.yml` | Reusable pipeline template for Copilot CLI automation |
| `code-review.yml` | Code review pipeline example |
| `documentation.yml` | Documentation generation pipeline example |
| `security-analysis.yml` | Security analysis pipeline example |

## Configuration

GitLab CI pipelines use `.gitlab-ci.yml` at the repository root. The templates in this folder can be included using GitLab's `include` directive:

```yaml
include:
  - local: 'gitlab-ci/copilot-cli-gitlab.yml'
```

## Related

- See [`actions/`](../actions/) for GitHub Actions examples
- See [`automation/`](../automation/) for core Copilot CLI scripts and configuration
- See [`automation/examples/`](../automation/examples/) for prompt templates

## Contributing

Contributions are welcome! If you have GitLab CI templates to share, please submit a pull request.
