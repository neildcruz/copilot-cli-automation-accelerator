# GitHub Actions Cost Analysis Platform Instructions

## Repository Overview
This repository contains a GitHub Actions workflow that analyzes the cost of GitHub Actions usage in target repositories and generates HTML reports with optimization recommendations.

## Key Components
- **Workflow**: `.github/workflows/cost-analyzer-main.yml` - Main cost analysis workflow
- **Trigger**: Manual workflow_dispatch only
- **Output**: HTML report artifact with 30-day retention

## Cost Analysis Context
When working with this repository, consider GitHub Actions pricing:
- ubuntu-latest: $0.008/minute
- windows-latest: $0.016/minute  
- macos-latest: $0.08/minute
- macos-14: $0.12/minute

## Development Guidelines

### When modifying the cost analysis workflow:
- Always validate repository input format (owner/repo)
- Use ubuntu-latest for the analyzer itself to minimize costs
- Calculate costs based on runner type and estimated runtime
- Consider matrix strategies for parallel analysis if needed

### When suggesting optimizations:
- Prioritize runner selection (ubuntu is 10x cheaper than macOS)
- Always recommend caching for dependencies
- Suggest path filters to skip unnecessary runs
- Recommend concurrency controls to cancel redundant runs
- Consider workflow consolidation opportunities

### Cost Optimization Priorities:
1. **Quick Wins** (implement immediately):
   - Switch expensive runners to ubuntu-latest where possible
   - Add caching for package managers (npm, pip, maven, etc.)
   - Implement path filters for docs-only changes

2. **Medium-term** (1-2 week implementation):
   - Consolidate similar workflows
   - Add concurrency groups
   - Optimize matrix strategies

3. **Long-term** (requires refactoring):
   - Move long-running tests to scheduled workflows
   - Implement conditional job execution
   - Use self-hosted runners for expensive operations

### HTML Report Requirements:
- Include interactive charts using Chart.js
- Display costs in USD with 2 decimal places
- Show both current costs and potential savings
- Provide actionable recommendations with estimated savings percentages
- Use gradient backgrounds for visual appeal


## Common Issues and Solutions:
- **No workflows found**: Check if target repo has .github/workflows directory
- **Cost calculation errors**: Ensure bc command is available for floating-point math
- **AI analysis fails**: Verify COPILOT_TOKEN secret is set
- **Report generation fails**: Check that all workflow outputs are properly set

## Build and Validation:
No build steps required - this is a GitHub Actions workflow only.
To validate changes:
1. Run workflow manually with a test repository
2. Download and review the HTML report artifact
3. Verify cost calculations are accurate
4. Check that all recommendations are actionable