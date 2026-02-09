# Code Review Request

Perform a comprehensive code review of this repository and generate a detailed report.

**IMPORTANT INSTRUCTIONS**:
- This review is running in **asynchronous/automated mode**
- **DO NOT ask any follow-up questions** or request clarification from the user
- **DO NOT ask for permission** to proceed with any actions
- Make reasonable assumptions based on the codebase context and proceed autonomously
- **GENERATE THE COMPLETE REPORT** in the format below in your response
- Include all sections: Executive Summary, Top 10 Critical Issues (with full details for each), Additional Findings, Security Analysis, Code Metrics Summary, Recommendations, and Positive Highlights
- This is a **single-response deliverable** - provide the full analysis now, not a summary followed by questions

## Required Output Format

YOU MUST generate a report following this EXACT structure:

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

**CRITICAL REMINDER**: You MUST provide the complete report above in your response. Do NOT provide a brief summary and ask if the user wants more details. Generate the FULL report with ALL sections populated now. This is an automated workflow - there is no opportunity for follow-up interaction.

## Issue Creation Workflow

**CRITICAL INSTRUCTIONS FOR GITHUB INTEGRATION**:

After generating the complete code review report above, proceed with the following automated workflow:

1. **DO NOT call `list_issues` or any other listing/search tools** - this wastes tokens and time
2. **Directly create GitHub issues** for each of the top 10 critical issues using the `create_issue` tool
3. **Create issues in sequence**, one at a time, to ensure proper tracking

For each issue you create:
- **Title**: Use format "Code Review - Issue #X: [Brief Title]" (e.g., "Code Review - Issue #1: SQL Injection in User Query")
- **Body**: Include full details in markdown format:
  ```markdown
  ## Severity: [CRITICAL/HIGH/MEDIUM/LOW]
  ## Category: [Security/Bug/Performance/Design/Maintainability/etc.]
  ## Location
  `[file path:line numbers]`
  
  ## Description
  [Clear explanation of the problem]
  
  ## Impact
  [What happens if this isn't fixed]
  
  ## Current Code
  ```language
  [problematic code snippet]
  ```
  
  ## Recommended Fix
  ```language
  [improved code snippet]
  ```
  
  ## Effort Estimate
  [Low/Medium/High]
  ```
- **Labels**: Apply based on severity and category:
  - Severity: `security`, `bug`, `performance`, `design`, `tech-debt`, `maintainability`
  - Priority: `priority-critical`, `priority-high`, `priority-medium`, `priority-low`
  - Effort: `effort-low`, `effort-medium`, `effort-high`

**Error Handling**: If issue creation fails (e.g., GitHub MCP server not available, authentication issues), include a note at the end of your report with the issue details that couldn't be created, but DO NOT stop the review process.

This ensures all critical findings are tracked in GitHub and can be assigned to team members for resolution.