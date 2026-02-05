# Stage 1: Security Vulnerability Scanner

Perform a comprehensive security scan of this codebase and **write findings to `SECURITY_FINDINGS.md`**.

## Scan Focus Areas

### 1. Authentication & Authorization
- JWT token handling and validation
- Session management vulnerabilities
- Role-based access control (RBAC) issues
- OAuth/OIDC implementation flaws

### 2. Input Validation
- SQL injection vulnerabilities
- Cross-site scripting (XSS) risks
- Command injection points
- Path traversal vulnerabilities
- XML/JSON injection

### 3. Data Protection
- Sensitive data exposure in logs/errors
- Inadequate encryption usage
- Hardcoded secrets and credentials
- API key management issues
- PII handling concerns

### 4. Security Headers & Configuration
- Missing security headers
- CORS misconfigurations
- Insecure defaults
- Debug mode in production

## Output Format

**Write your findings to `SECURITY_FINDINGS.md` with this structure:**

```markdown
# Security Scan Results

## Executive Summary
[High-level overview of findings count by severity]

## Critical Findings
### [CRITICAL-001] Issue Title
**Location:** `path/to/file.ext:line`
**Severity:** Critical
**Description:** [Detailed explanation]
**Risk:** [What could happen if exploited]
**Remediation:** [Specific fix with code example]

## High Priority Findings
[Same format as critical]

## Medium Priority Findings
[Same format]

## Low Priority Findings
[Same format]

## Summary Statistics
- Critical: X
- High: X
- Medium: X
- Low: X
```

**Important:** Ensure each finding includes:
- Specific file path and line number
- Clear severity rating
- Actionable remediation steps with code examples
