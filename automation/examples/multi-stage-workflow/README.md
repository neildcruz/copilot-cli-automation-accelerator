# Multi-Stage Agent Workflow Example

This example demonstrates how to create agents that work together sequentially, with later agents consuming output from earlier agents.

## Overview

This workflow consists of two stages:

1. **Stage 1: Security Scanner** - Analyzes codebase for vulnerabilities and writes findings to `SECURITY_FINDINGS.md`
2. **Stage 2: Fix Generator** - Reads the findings file and generates fixes for Critical/High priority issues

## Use Case

This pattern is useful when you want to:
- Break complex tasks into specialized steps
- Pass structured data between agents via files
- Create audit trails of multi-step analysis
- Allow manual review between stages

## Directory Structure

```
multi-stage-workflow/
├── README.md (this file)
├── stage-1-scanner/
│   ├── copilot-cli.properties
│   ├── user.prompt.md
│   ├── system.prompt.md
│   └── description.txt
└── stage-2-fixer/
    ├── copilot-cli.properties
    ├── user.prompt.md
    ├── system.prompt.md
    └── description.txt
```

## Usage

### Run Both Stages Sequentially

```bash
# Bash (Linux/macOS)
cd /path/to/your/project
/path/to/copilot-cli.sh --agents "multi-stage-workflow/stage-1-scanner,multi-stage-workflow/stage-2-fixer"

# PowerShell (Windows)
cd C:\path\to\your\project
\path\to\copilot-cli.ps1 -Agents "multi-stage-workflow/stage-1-scanner,multi-stage-workflow/stage-2-fixer"
```

### Run Stages Individually

```bash
# Stage 1 only (scan for issues)
./copilot-cli.sh --agent multi-stage-workflow/stage-1-scanner

# Review SECURITY_FINDINGS.md manually

# Stage 2 only (generate fixes)
./copilot-cli.sh --agent multi-stage-workflow/stage-2-fixer
```

### With Error Control

```bash
# Stop if Stage 1 fails (recommended)
./copilot-cli.sh --agents "multi-stage-workflow/stage-1-scanner,multi-stage-workflow/stage-2-fixer" --agent-error-mode stop

# Continue even if Stage 1 has issues
./copilot-cli.sh --agents "multi-stage-workflow/stage-1-scanner,multi-stage-workflow/stage-2-fixer" --agent-error-mode continue
```

## How It Works

### Stage 1: Scanner

1. Analyzes the codebase for security vulnerabilities
2. Categorizes findings by severity (Critical, High, Medium, Low)
3. **Writes results to `SECURITY_FINDINGS.md`** in the current directory
4. Exits, allowing Stage 2 to proceed

### Stage 2: Fix Generator

1. **Reads `SECURITY_FINDINGS.md`** created by Stage 1
2. Filters for Critical and High priority items only
3. Generates complete code fixes for each vulnerability
4. **Writes fixes to `SECURITY_FIXES.md`**

### Output Files

After running both stages, you'll have:

```
your-project/
├── SECURITY_FINDINGS.md  (from Stage 1)
└── SECURITY_FIXES.md     (from Stage 2)
```

## Customization

### Modify Stage 1 Scanner

Edit `stage-1-scanner/user.prompt.md` to change:
- Scanning focus areas (add compliance checks, performance issues, etc.)
- Severity criteria
- Output format

### Modify Stage 2 Fixer

Edit `stage-2-fixer/user.prompt.md` to:
- Change which severity levels get fixes
- Adjust fix format or detail level
- Add additional output (like test cases)

### Alternative Workflows

Create your own multi-stage workflows:

```
code-analyzer/
├── stage-1-structure/    # Analyze architecture
├── stage-2-patterns/     # Identify design patterns
└── stage-3-recommendations/ # Generate improvement plan
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Security Analysis Pipeline

on: [pull_request]

jobs:
  security-pipeline:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Security Analysis Pipeline
        run: |
          ./copilot-cli.sh --agents "multi-stage-workflow/stage-1-scanner,multi-stage-workflow/stage-2-fixer" --agent-error-mode stop
      
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: security-reports
          path: |
            SECURITY_FINDINGS.md
            SECURITY_FIXES.md
```

### Azure Pipelines Example

```yaml
- task: Bash@3
  displayName: 'Security Analysis Pipeline'
  inputs:
    targetType: 'inline'
    script: |
      ./copilot-cli.sh --agents "multi-stage-workflow/stage-1-scanner,multi-stage-workflow/stage-2-fixer"
      
- task: PublishBuildArtifacts@1
  inputs:
    pathToPublish: '$(Build.SourcesDirectory)/SECURITY_FINDINGS.md'
    artifactName: 'security-reports'
```

## Best Practices

1. **File-Based Communication**
   - Use markdown files for human-readable output
   - Use JSON for structured data between stages
   - Document the expected file format in prompts

2. **Error Handling**
   - Use `--agent-error-mode stop` if later stages depend on earlier ones
   - Check for output file existence at start of dependent stages
   - Include clear error messages in prompts

3. **Stage Independence**
   - Each stage should be runnable independently (with input files present)
   - Don't hardcode file paths - use relative paths
   - Include validation in prompts (e.g., "verify FINDINGS.md exists")

4. **Prompt Design**
   - Be explicit about input/output file names
   - Specify exact format for inter-stage files
   - Include examples in system prompts

## Troubleshooting

**Stage 2 can't find SECURITY_FINDINGS.md:**
- Verify Stage 1 completed successfully
- Check current working directory
- Look for errors in Stage 1 output

**Fixes not generated:**
- Ensure SECURITY_FINDINGS.md has Critical/High items
- Check Stage 2 logs for parsing errors
- Verify file format matches expected structure

**Performance issues:**
- Adjust timeouts in copilot-cli.properties
- Split into more smaller stages
- Use `--log-level debug` to identify bottlenecks

## Related Documentation

- [CUSTOM-AGENTS.md](../../CUSTOM-AGENTS.md#multi-stage-agents) - Advanced agent patterns
- [automation/README.md](../README.md#run-multiple-agents) - Multi-agent execution
- [SECURITY.md](../../SECURITY.md) - Security best practices

---

**Created:** February 2026  
**Example of:** Multi-stage agent collaboration pattern
