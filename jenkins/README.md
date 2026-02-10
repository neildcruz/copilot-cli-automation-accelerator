# Jenkins Integration

> 🚧 **Coming Soon** - This folder will contain Jenkins pipeline templates for Copilot CLI automation.

## Planned Contents

| File | Description |
|------|-------------|
| `Jenkinsfile` | Reusable pipeline for Copilot CLI automation |
| `Jenkinsfile.code-review` | Code review pipeline example |
| `Jenkinsfile.documentation` | Documentation generation pipeline example |
| `Jenkinsfile.security-analysis` | Security analysis pipeline example |

## Configuration

Jenkins pipelines use `Jenkinsfile` at the repository root. The templates in this folder can be loaded using Jenkins shared libraries or pipeline includes:

```groovy
// Jenkinsfile
@Library('copilot-cli-automation') _

pipeline {
    agent any
    stages {
        stage('Copilot CLI Analysis') {
            steps {
                copilotCliAnalysis(
                    agent: 'default',
                    userPrompt: 'automation/user.prompt.md'
                )
            }
        }
    }
}
```

## Related

- See [`actions/`](../actions/) for GitHub Actions examples
- See [`automation/`](../automation/) for core Copilot CLI scripts and configuration
- See [`automation/examples/`](../automation/examples/) for prompt templates

## Contributing

Contributions are welcome! If you have Jenkins pipeline templates to share, please submit a pull request.
