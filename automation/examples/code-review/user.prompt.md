# Code Review Request

Perform a comprehensive code review of this repository and generate a detailed report.

## Required Output Format

### Executive Summary
- Repository overview (language, framework, purpose)
- Overall code quality assessment (1-10 scale)
- Top 3 strengths
- Top 3 areas for improvement

### Top 10 Critical Issues

For each issue, provide:

**Issue #X: [Brief Title]**
- **Severity**: [CRITICAL/HIGH/MEDIUM/LOW]
- **Category**: [Security/Bug/Performance/Design/Maintainability/etc.]
- **Location**: `[file path:line numbers]`
- **Description**: Clear explanation of the problem
- **Impact**: What happens if this isn't fixed
- **Current Code**:
  ```language
  [problematic code snippet]
  ```
- **Recommended Fix**:
  ```language
  [improved code snippet]
  ```
- **Effort Estimate**: [Low/Medium/High]

### Additional Findings

List 5-10 additional issues worth noting (brief format):
- [Issue description] - `[location]` - [Severity]

### Security Analysis
- Authentication/authorization concerns
- Input validation and sanitization
- Dependency vulnerabilities
- Secrets management
- Security best practices violations

### Code Metrics Summary
- Approximate lines of code
- Code duplication estimate
- Cyclomatic complexity concerns
- Test coverage observations

### Recommendations

**Immediate Actions** (Fix within 1 week):
1. [Action item with rationale]

**Short-term Improvements** (Fix within 1 month):
1. [Action item with rationale]

**Long-term Enhancements** (Plan for next quarter):
1. [Action item with rationale]

### Positive Highlights
- What the codebase does well
- Good patterns to maintain
- Strengths to build upon

---

**Note**: Focus on actionable, specific feedback. Prioritize issues that pose security risks, could cause production incidents, or significantly impact maintainability.