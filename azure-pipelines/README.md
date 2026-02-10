# Azure Pipelines Integration

> 🚧 **Coming Soon** - This folder will contain Azure DevOps pipeline templates for Copilot CLI automation.

## Planned Contents

| File | Description |
|------|-------------|
| `copilot-cli-azure.yml` | Reusable pipeline template for Copilot CLI automation |
| `code-review.yml` | Code review pipeline example |
| `documentation.yml` | Documentation generation pipeline example |
| `security-analysis.yml` | Security analysis pipeline example |

## Configuration

Azure Pipelines use `azure-pipelines.yml` at the repository root. The templates in this folder can be referenced using Azure's template syntax:

```yaml
stages:
  - template: azure-pipelines/copilot-cli-azure.yml
    parameters:
      agent: 'default'
      userPrompt: 'automation/user.prompt.md'
```

## Related

- See [`actions/`](../actions/) for GitHub Actions examples
- See [`automation/`](../automation/) for core Copilot CLI scripts and configuration
- See [`automation/examples/`](../automation/examples/) for prompt templates

## Contributing

Contributions are welcome! If you have Azure Pipelines templates to share, please submit a pull request.
