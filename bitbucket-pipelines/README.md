# Bitbucket Pipelines Integration

> 🚧 **Coming Soon** - This folder will contain Bitbucket Pipelines templates for Copilot CLI automation.

## Planned Contents

| File | Description |
|------|-------------|
| `copilot-cli-bitbucket.yml` | Reusable pipeline definition for Copilot CLI automation |
| `code-review.yml` | Code review pipeline example |
| `documentation.yml` | Documentation generation pipeline example |
| `security-analysis.yml` | Security analysis pipeline example |

## Configuration

Bitbucket Pipelines use `bitbucket-pipelines.yml` at the repository root. The templates in this folder can be referenced using YAML anchors or custom pipes:

```yaml
# bitbucket-pipelines.yml
definitions:
  steps:
    - step: &copilot-cli-step
        name: Copilot CLI Analysis
        script:
          - ./automation/copilot-cli.sh
        artifacts:
          - output/**

pipelines:
  default:
    - step: *copilot-cli-step
```

## Related

- See [`actions/`](../actions/) for GitHub Actions examples
- See [`automation/`](../automation/) for core Copilot CLI scripts and configuration
- See [`automation/examples/`](../automation/examples/) for prompt templates

## Contributing

Contributions are welcome! If you have Bitbucket Pipelines templates to share, please submit a pull request.
