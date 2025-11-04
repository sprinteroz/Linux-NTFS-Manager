# Security Policy

## 🔒 Security Overview

NTFS Manager takes security seriously. This document outlines our security policies, supported versions, and how to report vulnerabilities.

---

## 📋 Supported Versions

We actively support and provide security updates for the following versions:

| Version | Supported          | End of Support     |
| ------- | ------------------ | ------------------ |
| 1.0.x   | ✅ Yes (Current)   | TBD                |
| < 1.0   | ❌ No              | November 2024      |

**Note:** Only the latest stable release receives security updates. We recommend always using the most recent version.

---

## 🐛 Reporting a Vulnerability

If you discover a security vulnerability in NTFS Manager, please report it responsibly. We appreciate your efforts to improve the security of our software.

### Reporting Process

**For Security Issues:**
1. **Do NOT** open a public GitHub issue
2. **Email us directly** at: `support_ntfs@magdrivex.com.au`
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact and severity
   - Suggested fix (if available)
   - Your contact information

**Subject Line Format:**
```
[SECURITY] Brief description of the vulnerability
```

### Response Timeline

We are committed to addressing security issues promptly:

- **Initial Response:** Within 48 hours of report
- **Vulnerability Confirmation:** Within 5 business days
- **Fix Development:** 7-14 days (depending on severity)
- **Patch Release:** Within 21 days for critical issues
- **Public Disclosure:** After patch is released and users have time to update

### Severity Levels

| Severity | Description | Response Time |
|----------|-------------|---------------|
| **Critical** | Remote code execution, privilege escalation | 24-48 hours |
| **High** | Data exposure, authentication bypass | 3-7 days |
| **Medium** | Information disclosure, DoS attacks | 7-14 days |
| **Low** | Minor security improvements | 14-30 days |

---

## 🛡️ Security Features

NTFS Manager includes several security features:

### Current Security Measures

- ✅ **Input Validation:** All user inputs are validated and sanitized
- ✅ **Permission Checks:** Proper privilege escalation handling with PolicyKit
- ✅ **Audit Logging:** Comprehensive logging of all operations
- ✅ **Secure File Operations:** Safe handling of NTFS filesystem operations
- ✅ **Code Scanning:** Automated security analysis with CodeQL
- ✅ **Dependency Monitoring:** Automated vulnerability scanning with Dependabot
- ✅ **License Compliance:** Automated license checking

### Security Testing

We employ multiple layers of security testing:

- **Static Analysis:** CodeQL, Bandit, and custom security rules
- **Dependency Scanning:** Regular updates and vulnerability checks
- **Code Review:** All changes undergo security-focused review
- **Automated Testing:** Security test suite in CI/CD pipeline

---

## 🔐 Security Best Practices

### For Users

1. **Keep Updated:** Always use the latest version
2. **Download from Official Sources:** Only download from GitHub releases or official repositories
3. **Verify Integrity:** Check SHA256 checksums of downloaded files
4. **Use Secure Systems:** Keep your Linux system and dependencies updated
5. **Review Permissions:** Understand what permissions the software requires

### For Developers

1. **Follow Secure Coding Practices:** Adhere to OWASP guidelines
2. **Validate All Input:** Never trust user-provided data
3. **Use Parameterized Commands:** Avoid shell injection vulnerabilities
4. **Handle Errors Securely:** Don't expose sensitive information in error messages
5. **Review Security Implications:** Consider security in all code changes

---

## 📊 Security Audits

### Automated Scans

- **CodeQL Analysis:** Weekly comprehensive security analysis
- **Dependency Checks:** Daily security update monitoring
- **Code Quality:** Continuous linting and best practice enforcement

### Manual Reviews

- **Code Reviews:** All pull requests reviewed for security implications
- **External Audits:** Periodic third-party security assessments (as resources permit)

---

## 🔄 Security Update Process

### Update Distribution

Security updates are distributed through:

1. **GitHub Releases:** Tagged releases with security fixes
2. **Dependabot:** Automated dependency updates
3. **Security Advisories:** Published for critical issues
4. **Release Notes:** Detailed changelog of security fixes

### Notification Channels

Stay informed about security updates:

- **GitHub Watch:** Watch repository for release notifications
- **Security Advisories:** Enable GitHub security alerts
- **Release Feed:** Subscribe to release RSS feed
- **Email Updates:** Available for commercial license holders

---

## 🤝 Responsible Disclosure

We believe in responsible disclosure and will:

- Acknowledge your report promptly
- Keep you informed of progress
- Credit you in release notes (if desired)
- Coordinate public disclosure timing with you
- Not take legal action against good-faith security researchers

### Hall of Fame

We maintain a list of security researchers who have helped improve NTFS Manager's security:

<!-- Security researchers will be listed here after responsible disclosure -->
*No vulnerabilities reported yet*

---

## 📝 Security Checklist for Contributors

Before submitting code, ensure:

- [ ] No hardcoded credentials or secrets
- [ ] All user input is validated
- [ ] SQL queries use parameterization (if applicable)
- [ ] File operations check permissions
- [ ] Error messages don't expose sensitive data
- [ ] Dependencies are up-to-date and secure
- [ ] Security tests pass
- [ ] Code review completed

---

## 🔗 Additional Resources

### Security Documentation

- [OWASP Top Ten](https://owasp.org/www-project-top-ten/)
- [Python Security Best Practices](https://python.readthedocs.io/en/latest/library/security_warnings.html)
- [GTK Security Guidelines](https://wiki.gnome.org/Projects/GTK/SecurityPolicy)
- [Linux Security Modules](https://www.kernel.org/doc/html/latest/admin-guide/LSM/index.html)

### Security Tools We Use

- **CodeQL:** Advanced semantic code analysis
- **Bandit:** Python security linter
- **Safety:** Python dependency vulnerability scanner
- **pip-audit:** PyPI package vulnerability auditing
- **Dependabot:** Automated dependency updates

---

## 📞 Contact Information

### Security Contact

- **Email:** support_ntfs@magdrivex.com.au
- **Subject:** `[SECURITY] Your Issue Description`
- **Response Time:** Within 48 hours

### General Support

- **Issues:** [GitHub Issues](https://github.com/sprinteroz/Linux-NTFS-Manager/issues)
- **Discussions:** [GitHub Discussions](https://github.com/sprinteroz/Linux-NTFS-Manager/discussions)
- **Documentation:** [Wiki](https://github.com/sprinteroz/Linux-NTFS-Manager/wiki)

---

## 📜 License and Compliance

This project uses a **Dual License** model:

- **Personal Use:** Free under LICENSE-PERSONAL
- **Commercial Use:** Paid license required (LICENSE-COMMERCIAL)

Security updates are provided for both license types.

---

**Last Updated:** November 4, 2025  
**Version:** 1.0  
**Next Review:** February 2026

---

*Thank you for helping keep NTFS Manager and its users safe!*
