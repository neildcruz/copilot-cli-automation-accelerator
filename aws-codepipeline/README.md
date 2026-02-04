# AWS CodePipeline Integration

> 🚧 **Coming Soon** - This folder will contain AWS CodePipeline and CodeBuild templates for Copilot CLI automation.

## Planned Contents

| File | Description |
|------|-------------|
| `buildspec.yml` | CodeBuild buildspec for Copilot CLI automation |
| `buildspec-code-review.yml` | Code review buildspec example |
| `buildspec-documentation.yml` | Documentation generation buildspec example |
| `buildspec-security-analysis.yml` | Security analysis buildspec example |
| `pipeline.yml` | CloudFormation template for CodePipeline setup |

## Configuration

AWS CodeBuild uses `buildspec.yml` files. The templates in this folder can be referenced in your CodeBuild project configuration:

```yaml
# buildspec.yml
version: 0.2

phases:
  install:
    runtime-versions:
      nodejs: 18
    commands:
      - npm install -g @githubnext/github-copilot-cli
  build:
    commands:
      - ./automation/copilot-cli.sh

artifacts:
  files:
    - output/**
```

## Related

- See [`actions/`](../actions/) for GitHub Actions examples
- See [`automation/`](../automation/) for core Copilot CLI scripts and configuration
- See [`automation/examples/`](../automation/examples/) for prompt templates

## Contributing

Contributions are welcome! If you have AWS CodePipeline/CodeBuild templates to share, please submit a pull request.
