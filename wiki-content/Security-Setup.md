# Security Setup Guide

Complete guide for configuring GitHub security features for NTFS Manager.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Security Features](#security-features)
- [Enabling GitHub Security](#enabling-github-security)
- [CodeQL Setup](#codeql-setup)
- [Dependabot Configuration](#dependabot-configuration)
- [Dependency Review](#dependency-review)
- [Security Advisories](#security-advisories)
- [Best Practices](#best-practices)
- [Monitoring and Alerts](#monitoring-and-alerts)

---

## Overview

NTFS Manager implements comprehensive security measures through GitHub's built-in security features. This guide explains how to configure and use these features.

### What's Included

- ✅ **CodeQL Analysis** - Automated code security scanning
- ✅ **Dependabot** - Automated dependency updates
- ✅ **Dependency Review** - PR vulnerability checking
- ✅ **Security Policy** - Vulnerability reporting process
- ✅ **Security Advisories** - Public disclosure management

---

## Security Features

### Already Configured

The repository includes pre-configured security workflows:

| Feature | File | Purpose |
|---------|------|---------|
| **CodeQL** | `.github/workflows/codeql.yml` | Python security analysis |
| **Dependabot** | `.github/dependabot.yml` | Dependency updates |
| **Dependency Review** | `.github/workflows/dependency-review.yml` | PR checks |
| **Security Policy** | `SECURITY.md` | Reporting guidelines |

### Security Workflows

All workflows are automatically triggered on:
- Push to `main` or `develop` branches
- Pull requests
- Scheduled intervals (weekly for CodeQL)
- Manual dispatch

---

## Enabling GitHub Security

### Step 1: Access Security Settings

1. Go to your repository on GitHub
2. Click **Settings** tab
3. Click **Code security and analysis** in the left sidebar

### Step 2: Enable Security Features

Enable the following features:

#### Dependency Graph
- ✅ **Dependency graph** - Enable this first (required for other features)

#### Dependabot
- ✅ **Dependabot alerts** - Get notified of vulnerable dependencies
- ✅ **Dependabot security updates** - Auto-create PRs for security fixes

#### Code Scanning
- ✅ **Code scanning** - Will use the CodeQL workflow we've provided

#### Secret Scanning
- ✅ **Secret scanning** - Detect accidentally committed secrets
- ✅ **Push protection** - Block commits with secrets

### Step 3: Configure Branch Protection

Protect the `main` branch:

1. Go to **Settings** → **Branches**
2. Click **Add rule** for `main` branch
3. Enable:
   - ✅ Require pull request reviews
   - ✅ Require status checks to pass (select CodeQL, CI)
   - ✅ Require conversation resolution
   - ✅ Do not allow bypassing the above settings

---

## CodeQL Setup

### What is CodeQL?

CodeQL is GitHub's semantic code analysis engine that finds security vulnerabilities and coding errors.

### Current Configuration

The repository includes a comprehensive CodeQL workflow at `.github/workflows/codeql.yml` that:

- Analyzes Python code
- Uses `security-and-quality` query suite
- Runs on push, PR, and weekly schedule
- Uploads results to GitHub Security tab
- Includes additional security scanning (Bandit, Safety, pip-audit)

### Viewing CodeQL Results

1. Go to **Security** tab
2. Click **Code scanning alerts**
3. Review any findings
4. Click on an alert to see details and suggestions

### CodeQL Query Suites

The workflow uses the `security-and-quality` suite which includes:

- **Security queries:** SQL injection, XSS, path traversal, etc.
- **Quality queries:** Code smells, best practices
- **Precision:** High-confidence findings

### Manual CodeQL Runs

Trigger CodeQL analysis manually:

1. Go to **Actions** tab
2. Select **CodeQL Security Analysis** workflow
3. Click **Run workflow**
4. Select branch and click **Run workflow**

### Troubleshooting CodeQL

#### Issue: CodeQL workflow fails

**Check:**
```bash
# Verify Python syntax
python3 -m py_compile ntfs-manager-production/backend/*.py

# Check dependencies
cd ntfs-manager-production
pip install -r requirements.txt
```

#### Issue: False positives

**Solution:**
- Review the finding in detail
- If it's truly a false positive, dismiss it with explanation
- Consider adding CodeQL suppression comment:
  ```python
  # codeql[py/path-injection]
  path = user_input  # Validated elsewhere
  ```

---

## Dependabot Configuration

### What is Dependabot?

Dependabot automatically checks for dependency updates and creates PRs to keep packages secure and up-to-date.

### Current Configuration

The repository includes `.github/dependabot.yml` that monitors:

- **Python packages** (pip) - Weekly updates
- **GitHub Actions** - Weekly updates  
- **Docker images** - Weekly updates
- **Security patches** - Daily checks

### Configuration Details

```yaml
version: 2
updates:
  # Python dependencies (weekly)
  - package-ecosystem: "pip"
    directory: "/ntfs-manager-production"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "03:00"
      timezone: "Australia/Melbourne"
    
  # Security updates (daily)
  - package-ecosystem: "pip"
    schedule:
      interval: "daily"
    labels:
      - "security"
      - "priority-high"
```

### Managing Dependabot PRs

When Dependabot creates a PR:

1. **Review the changes:**
   - Check release notes
   - Review changelog
   - Look for breaking changes

2. **Run automated tests:**
   - CI workflow runs automatically
   - CodeQL scans the changes
   - Dependency review checks vulnerabilities

3. **Merge or close:**
   - Merge if tests pass and changes are safe
   - Close if update causes issues (document why)

### Dependabot Commands

In PR comments, you can use:

```
@dependabot rebase       # Rebase the PR
@dependabot recreate     # Recreate the PR
@dependabot merge        # Merge when CI passes
@dependabot squash and merge
@dependabot cancel merge
@dependabot close        # Close without merging
@dependabot ignore this dependency
@dependabot ignore this major version
@dependabot ignore this minor version
```

### Customizing Dependabot

Edit `.github/dependabot.yml`:

```yaml
# Change update frequency
schedule:
  interval: "daily"    # or "weekly", "monthly"

# Limit PR count
open-pull-requests-limit: 5

# Pin versions
ignore:
  - dependency-name: "package-name"
    versions: ["1.x", "2.x"]
```

---

## Dependency Review

### What is Dependency Review?

The Dependency Review action scans PRs for new vulnerable or malicious dependencies before they're merged.

### Current Configuration

The workflow at `.github/workflows/dependency-review.yml` performs:

- **Vulnerability scanning** - Checks for known CVEs
- **License compliance** - Verifies license compatibility
- **Supply chain security** - Detects malicious packages
- **Outdated package detection** - Finds outdated dependencies

### Configured Thresholds

```yaml
fail-on-severity: moderate    # Fail on moderate+ severity
allow-licenses: MIT, Apache-2.0, BSD-3-Clause, GPL-3.0, LGPL-3.0
deny-licenses: AGPL-1.0, AGPL-3.0
```

### Reading Dependency Review Results

The workflow creates PR comments with:

- ✅ **Approved dependencies** - Safe to merge
- ⚠️ **Warnings** - Review carefully
- ❌ **Failures** - Must fix before merging

### Handling Failures

If Dependency Review fails:

1. **Check the PR comment** for specific issues
2. **Review the vulnerability** details
3. **Options:**
   - Update to patched version
   - Remove the dependency
   - Document the risk and accept
   - Wait for upstream fix

---

## Security Advisories

### Creating a Security Advisory

When a vulnerability is discovered:

1. Go to **Security** tab
2. Click **Advisories**
3. Click **New draft security advisory**
4. Fill in details:
   - **Summary:** Brief description
   - **Severity:** Critical, High, Medium, Low
   - **CWE:** Select vulnerability type
   - **Affected versions:** Version range
   - **Patched versions:** Fixed versions
   - **Description:** Full details
   - **References:** CVEs, links

5. Click **Create draft security advisory**

### Private Vulnerability Reporting

GitHub allows users to privately report vulnerabilities:

1. **Enable private reporting:**
   - Go to **Settings** → **Code security and analysis**
   - Enable **Private vulnerability reporting**

2. **Users can report via:**
   - Security tab's **Report a vulnerability** button
   - Email to `support_ntfs@magdrivex.com.au`

### Publishing Advisories

After fixing a vulnerability:

1. Draft the advisory with all details
2. Request a CVE identifier (if applicable)
3. Publish the advisory
4. Tag a new release with the fix

---

## Best Practices

### For Repository Owners

1. **Review alerts promptly:**
   - Check Dependabot alerts weekly
   - Respond to CodeQL findings within 5 days
   - Address critical vulnerabilities within 24-48 hours

2. **Keep workflows updated:**
   ```bash
   # Check for action updates
   git pull origin main
   # Review .github/workflows/ for outdated actions
   ```

3. **Monitor security tab:**
   - Check Security Overview weekly
   - Review Code Scanning results
   - Check Secret Scanning alerts

4. **Document security decisions:**
   - Why certain alerts are dismissed
   - Risk acceptance rationale
   - Mitigation strategies

### For Contributors

1. **Before submitting PRs:**
   - Run security checks locally
   - Update dependencies
   - Fix any CodeQL warnings

2. **Run local security scans:**
   ```bash
   # Run Bandit
   pip install bandit
   bandit -r ntfs-manager-production/
   
   # Check for vulnerabilities
   pip install safety
   safety check -r ntfs-manager-production/requirements.txt
   
   # Audit dependencies
   pip install pip-audit
   pip-audit -r ntfs-manager-production/requirements.txt
   ```

3. **Never commit secrets:**
   - Use `.gitignore` for sensitive files
   - Use environment variables
   - Use GitHub Secrets for CI/CD

### Security Checklist

Before merging code:

- [ ] CodeQL scan passed
- [ ] Dependency Review approved
- [ ] No new security warnings
- [ ] Tests pass
- [ ] Code reviewed by maintainer
- [ ] Secrets not committed
- [ ] License compliance verified

---

## Monitoring and Alerts

### Email Notifications

Configure notifications:

1. Go to **Settings** (your profile) → **Notifications**
2. Under **Watching:**
   - ✅ Enable Security alerts
   - ✅ Enable Dependabot alerts
3. Choose notification method:
   - Email
   - Web + Mobile

### Security Overview

View security status:

1. Go to **Insights** tab
2. Click **Security** (Beta)
3. View:
   - Open security alerts
   - Dismissed alerts
   - Fixed alerts
   - Alert trends over time

### Setting Up Alerts

GitHub sends alerts for:

- **Critical vulnerabilities** - Immediately
- **High severity** - Within 24 hours
- **Dependabot updates** - Weekly summary
- **Code scanning** - Per scan completion

### Integration with External Tools

Monitor security with external services:

```bash
# Check with GitHub API
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/repos/sprinteroz/Linux-NTFS-Manager/code-scanning/alerts

# Use gh CLI
gh api repos/sprinteroz/Linux-NTFS-Manager/dependabot/alerts
```

---

## Advanced Configuration

### Custom CodeQL Queries

Add custom queries to `.github/workflows/codeql.yml`:

```yaml
- name: Initialize CodeQL
  uses: github/codeql-action/init@v3
  with:
    queries: +security-and-quality,your-org/your-custom-queries
```

### Integration with SAST Tools

Add additional security scanners:

```yaml
# .github/workflows/security-scan.yml
- name: Run Snyk
  uses: snyk/actions/python@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### Automated Issue Creation

Auto-create issues from security alerts:

```yaml
- name: Create issue from alert
  uses: actions/github-script@v6
  with:
    script: |
      github.rest.issues.create({
        owner: context.repo.owner,
        repo: context.repo.repo,
        title: 'Security Alert: ...',
        body: 'Details...',
        labels: ['security']
      })
```

---

## Troubleshooting

### Common Issues

#### Issue: CodeQL taking too long

**Solution:**
- Reduce analyzed paths in workflow
- Use `trap-caching` for faster builds
- Split analysis into multiple jobs

#### Issue: Too many Dependabot PRs

**Solution:**
```yaml
# In dependabot.yml
open-pull-requests-limit: 3
groups:
  python-dependencies:
    patterns: ["*"]
```

#### Issue: False positive alerts

**Solution:**
- Review carefully
- Dismiss with detailed explanation
- Add to allow list if appropriate

---

## Additional Resources

- [GitHub Security Documentation](https://docs.github.com/en/code-security)
- [CodeQL Documentation](https://codeql.github.com/docs/)
- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [NTFS Manager Security Policy](https://github.com/sprinteroz/Linux-NTFS-Manager/blob/main/SECURITY.md)

---

## Next Steps

1. **[Configure branch protection](#step-3-configure-branch-protection)**
2. **[Enable all security features](#enabling-github-security)**
3. **[Review existing alerts](#monitoring-and-alerts)**
4. **[Set up notifications](#email-notifications)**

---

**Security setup complete!** 🔒

Your repository now has enterprise-grade security monitoring and automated vulnerability detection.
