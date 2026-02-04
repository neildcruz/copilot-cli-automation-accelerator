# Contributing to GitHub Copilot CLI Automation Suite

Thank you for your interest in contributing to the GitHub Copilot CLI Automation Suite! We welcome contributions from the community.

## 🤝 How to Contribute

### Reporting Issues

If you find a bug or have a feature request:

1. Check if the issue already exists in the [Issues](https://github.com/neildcruz/copilot-cli-automation-accelerator/issues) section
2. If not, create a new issue with:
   - A clear, descriptive title
   - Detailed description of the issue or feature request
   - Steps to reproduce (for bugs)
   - Expected vs. actual behavior
   - Your environment details (OS, Node.js version, etc.)

### Submitting Changes

1. **Fork the Repository**
   - Fork the project to your GitHub account
   - Clone your fork locally

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Make Your Changes**
   - Follow the existing code style and patterns
   - Add tests if applicable
   - Update documentation as needed
   - Ensure your changes don't break existing functionality

4. **Test Your Changes**
   - Test locally on your platform
   - Verify that existing examples still work
   - Test cross-platform compatibility if applicable

5. **Commit Your Changes**
   - Use clear, descriptive commit messages
   - Follow conventional commit format when possible:
     ```
     feat: Add new MCP server integration
     fix: Resolve timeout issue in automation script
     docs: Update README with new examples
     ```

6. **Submit a Pull Request**
   - Push your changes to your fork
   - Create a Pull Request to the main repository
   - Provide a clear description of your changes
   - Link any related issues

## 📋 Development Guidelines

### Code Style

- **Shell Scripts (Bash)**: Follow standard bash conventions
- **PowerShell Scripts**: Follow PowerShell best practices
- **GitHub Actions YAML**: Use clear, well-commented workflows
- **Documentation**: Use Markdown with clear formatting

### Documentation

- Update README files when adding features
- Include examples for new functionality
- Keep documentation clear and concise
- Use consistent formatting across all docs

### Security

- Never commit sensitive information (tokens, passwords, API keys)
- Follow security best practices
- Report security vulnerabilities privately (see [SECURITY.md](SECURITY.md))
- Test security-related changes thoroughly

## 🧪 Testing

- Test your changes on the target platform(s)
- Verify backward compatibility
- Ensure existing examples still work
- Add new examples if introducing major features

## 📝 License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

## 💬 Questions?

If you have questions about contributing:
- Check existing documentation
- Review closed issues and PRs
- Open a new issue with the "question" label

## 🌟 Recognition

Contributors will be recognized in the project. Thank you for helping improve the GitHub Copilot CLI Automation Suite!
