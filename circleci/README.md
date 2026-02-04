# CircleCI Integration

> 🚧 **Coming Soon** - This folder will contain CircleCI configuration templates for Copilot CLI automation.

## Planned Contents

| File | Description |
|------|-------------|
| `copilot-cli-circleci.yml` | Reusable orb/config for Copilot CLI automation |
| `code-review.yml` | Code review job example |
| `documentation.yml` | Documentation generation job example |
| `security-analysis.yml` | Security analysis job example |

## Configuration

CircleCI uses `.circleci/config.yml` at the repository root. The templates in this folder can be referenced using CircleCI orbs or config includes:

```yaml
# .circleci/config.yml
version: 2.1

orbs:
  copilot-cli: your-org/copilot-cli@1.0.0

workflows:
  analysis:
    jobs:
      - copilot-cli/analyze:
          system-prompt: automation/system.prompt.md
          user-prompt: automation/user.prompt.md
```

## Related

- See [`actions/`](../actions/) for GitHub Actions examples
- See [`automation/`](../automation/) for core Copilot CLI scripts and configuration
- See [`automation/examples/`](../automation/examples/) for prompt templates

## Contributing

Contributions are welcome! If you have CircleCI configuration templates to share, please submit a pull request.
