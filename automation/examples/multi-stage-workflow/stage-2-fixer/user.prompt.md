# Stage 2: Security Fix Generator

Read the security findings from `SECURITY_FINDINGS.md` (created by Stage 1) and generate fixes for all **Critical** and **High** priority vulnerabilities.

## Instructions

### 1. Read Previous Stage Output

First, read the file `SECURITY_FINDINGS.md` which contains security vulnerabilities identified in Stage 1.

### 2. Generate Fixes

For each **Critical** and **High** priority finding:
- Analyze the vulnerability and its context
- Create a complete, working fix
- Ensure the fix doesn't break existing functionality
- Follow security best practices

### 3. Create Fix Documentation

Write your fixes to `SECURITY_FIXES.md` with this structure:

```markdown
# Security Fixes

Generated from: SECURITY_FINDINGS.md
Date: [Current date]
Scope: Critical and High priority vulnerabilities

---

## Fix 001: [Issue Title from findings]

**Original Finding:** [CRITICAL/HIGH-XXX]
**File:** `path/to/file.ext:line`
**Vulnerability:** [Brief description]

### Current Code
```[language]
[Show vulnerable code]
```

### Fixed Code
```[language]
[Show secure code with complete fix]
```

### Explanation
[Explain what was changed and why it's secure]

### Testing Considerations
[How to verify the fix works]

---

[Repeat for each Critical/High finding]

---

## Summary

- Total fixes generated: X
- Critical issues fixed: X
- High priority issues fixed: X
- Files modified: [list of files]

## Next Steps

1. Review each fix carefully
2. Test in development environment
3. Run security scan again to verify fixes
4. Deploy to staging for validation
```

## Important Notes

- Generate fixes ONLY for Critical and High priority items
- Medium and Low priority items can be addressed in a separate sprint
- Provide complete, copy-paste ready code fixes
- Include comments explaining security improvements
- Consider performance implications of fixes
