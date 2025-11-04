# Contributing Guidelines

Thank you for your interest in contributing to NTFS Manager! This document provides guidelines for contributing to the project.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)
- [Translation Contributions](#translation-contributions)
- [License](#license)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of experience level, background, or identity.

### Expected Behavior

- Be respectful and considerate
- Use welcoming and inclusive language
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discriminatory language
- Personal attacks or trolling
- Publishing private information
- Spam or off-topic discussions
- Any conduct that would be inappropriate in a professional setting

### Enforcement

Violations may result in temporary or permanent ban from the project. Report issues to: support_ntfs@magdrivex.com.au

---

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- Git installed
- Python 3.8+ installed
- Basic knowledge of Python and GTK
- GitHub account
- Familiarity with the project

### First-Time Contributors

New to open source? Welcome! Here's how to start:

1. **Browse issues labeled "good first issue"**
   - These are beginner-friendly tasks
   - Ask questions if unclear

2. **Read the documentation**
   - [Installation Guide](Installation-Guide)
   - [User Guide](User-Guide)
   - [Development Setup](#development-setup)

3. **Join the community**
   - [GitHub Discussions](https://github.com/sprinteroz/Linux-NTFS-Manager/discussions)
   - Ask questions, introduce yourself

---

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

#### 🐛 Bug Reports
- Found a bug? Report it!
- See [Issue Guidelines](#issue-guidelines)

#### 💡 Feature Requests
- Have an idea? Suggest it!
- Open a discussion first for major features

#### 💻 Code Contributions
- Fix bugs
- Implement features
- Improve performance
- Refactor code

#### 📝 Documentation
- Improve README
- Write tutorials
- Add code comments
- Update wiki pages

#### 🌐 Translations
- Add new languages
- Improve existing translations
- See [Translation Guide](Translation-Guide)

#### 🧪 Testing
- Write unit tests
- Perform manual testing
- Report test results

---

## Development Setup

### 1. Fork the Repository

```bash
# Visit GitHub and click "Fork" button
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/Linux-NTFS-Manager.git
cd Linux-NTFS-Manager
```

### 2. Set Up Remote

```bash
# Add upstream remote
git remote add upstream https://github.com/sprinteroz/Linux-NTFS-Manager.git

# Verify remotes
git remote -v
```

### 3. Install Dependencies

```bash
# Ubuntu/Debian
sudo apt install python3 python3-gi python3-gi-cairo gir1.2-gtk-3.0 \
    ntfs-3g policykit-1 python3-pytest python3-pip

# Install Python development packages
pip install --user -r ntfs-manager-production/requirements.txt
pip install --user pytest pytest-cov black flake8 mypy bandit
```

### 4. Create Development Branch

```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name
# Or for bug fix
git checkout -b fix/bug-description
```

### 5. Run the Application

```bash
# Run from source (without installing)
cd ntfs-manager-production
python3 standalone-gui/main.py
```

---

## Coding Standards

### Python Style Guide

We follow [PEP 8](https://pep8.org/) with minor exceptions:

#### General Rules

- **Line length:** Maximum 100 characters
- **Indentation:** 4 spaces (no tabs)
- **Encoding:** UTF-8
- **Imports:** Organized alphabetically, grouped by type

#### Example

```python
"""Module docstring explaining purpose."""

import os
import sys
from typing import List, Optional

from gi.repository import Gtk, GLib

class NTFSManager:
    """Class for managing NTFS drives.
    
    Attributes:
        drive_path: Path to the NTFS drive
        mount_point: Where the drive is mounted
    """
    
    def __init__(self, drive_path: str) -> None:
        """Initialize NTFS Manager.
        
        Args:
            drive_path: Path to NTFS drive (e.g., /dev/sdb1)
        """
        self.drive_path = drive_path
        self.mount_point: Optional[str] = None
    
    def mount_drive(self) -> bool:
        """Mount the NTFS drive.
        
        Returns:
            True if successful, False otherwise.
        """
        # Implementation here
        pass
```

### Code Formatting

#### Use Black

```bash
# Format all Python files
black ntfs-manager-production/

# Check without modifying
black --check ntfs-manager-production/
```

#### Use isort

```bash
# Sort imports
isort ntfs-manager-production/

# Check without modifying
isort --check-only ntfs-manager-production/
```

### Linting

#### Run Flake8

```bash
# Check code quality
flake8 ntfs-manager-production/

# Ignore specific errors if needed
flake8 --ignore=E501,W503 ntfs-manager-production/
```

#### Run MyPy

```bash
# Type checking
mypy ntfs-manager-production/backend/
```

### Security Checks

#### Run Bandit

```bash
# Security linting
bandit -r ntfs-manager-production/
```

---

## Testing

### Running Tests

```bash
# Run all tests
cd ntfs-manager-production
pytest tests/

# Run with coverage
pytest --cov=backend --cov-report=html tests/

# Run specific test file
pytest tests/test_drive_manager.py

# Run specific test
pytest tests/test_drive_manager.py::test_mount_drive
```

### Writing Tests

#### Unit Test Example

```python
"""Tests for drive manager module."""

import pytest
from backend.drive_manager import DriveManager

class TestDriveManager:
    """Test cases for DriveManager class."""
    
    def test_detect_drives(self):
        """Test drive detection."""
        manager = DriveManager()
        drives = manager.detect_ntfs_drives()
        assert isinstance(drives, list)
    
    def test_invalid_drive_path(self):
        """Test handling of invalid drive path."""
        manager = DriveManager()
        with pytest.raises(ValueError):
            manager.mount_drive("/dev/invalid")
```

### Test Coverage

Maintain at least 70% code coverage:

```bash
# Generate coverage report
pytest --cov=backend --cov-report=term-missing tests/

# Generate HTML report
pytest --cov=backend --cov-report=html tests/
# Open htmlcov/index.html in browser
```

---

## Pull Request Process

### Before Submitting

1. **Test your changes**
   ```bash
   pytest tests/
   flake8 ntfs-manager-production/
   black --check ntfs-manager-production/
   ```

2. **Update documentation**
   - Update README if needed
   - Add docstrings to new functions
   - Update wiki if applicable

3. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: Add new feature description"
   ```

### Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting)
- `refactor:` Code refactoring
- `test:` Adding/updating tests
- `chore:` Maintenance tasks

**Examples:**
```
feat(mount): Add support for exFAT filesystems

Implement exFAT detection and mounting capabilities.
Includes new mount options specific to exFAT.

Closes #123
```

```
fix(unmount): Prevent data loss on forced unmount

Add safety check before forced unmount operation.
Display warning dialog to user.

Fixes #456
```

### Submitting Pull Request

1. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create pull request**
   - Go to GitHub
   - Click "New Pull Request"
   - Select your branch
   - Fill in the template

3. **PR template**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Code refactoring
   
   ## Testing
   - [ ] Tests pass locally
   - [ ] New tests added
   - [ ] Manual testing performed
   
   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Comments added to complex code
   - [ ] Documentation updated
   - [ ] No new warnings
   
   ## Related Issues
   Closes #issue_number
   ```

### Review Process

1. **Automated checks**
   - CI tests must pass
   - CodeQL security scan
   - Code coverage check

2. **Code review**
   - Maintainer will review
   - Address feedback promptly
   - Make requested changes

3. **Approval and merge**
   - Requires 1 approval
   - Squash merge preferred
   - Branch deleted after merge

---

## Issue Guidelines

### Reporting Bugs

Use this template:

```markdown
**Describe the bug**
Clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
- OS: [e.g. Ubuntu 22.04]
- Version: [e.g. 1.0.2]
- Python: [e.g. 3.11.0]

**Additional context**
Any other relevant information.
```

### Feature Requests

Before requesting:
1. Check if it already exists
2. Search closed issues
3. Discuss in Discussions first

Template:
```markdown
**Is your feature request related to a problem?**
Clear description of the problem.

**Describe the solution you'd like**
Clear description of what you want.

**Describe alternatives considered**
Other solutions you've considered.

**Additional context**
Mockups, examples, etc.
```

---

## Translation Contributions

### Adding a New Language

1. **Create translation file**
   ```bash
   cp translations/en.json translations/XX.json
   # Replace XX with language code (e.g., es, fr, de)
   ```

2. **Translate strings**
   - Keep placeholders like `{0}`, `{1}`
   - Maintain formatting
   - Use native language conventions

3. **Test translation**
   ```bash
   # Set language environment
   export LANG=XX_XX.UTF-8
   python3 ntfs-manager-production/standalone-gui/main.py
   ```

4. **Submit PR**
   - Include language code in PR title
   - Add language to LANGUAGES.md

See [Translation Guide](Translation-Guide) for details.

---

## License

### Dual License Model

By contributing, you agree that your contributions will be licensed under:

- **LICENSE-PERSONAL** for personal use
- **LICENSE-COMMERCIAL** for commercial use

### Contributor License Agreement

By submitting a pull request, you certify that:

1. You have the right to submit the contribution
2. You grant the project maintainers perpetual rights to use your contribution
3. You understand the dual license model
4. Your contribution is your original work

### Copyright Notice

Add this to new files:

```python
"""
NTFS Manager - Professional NTFS Drive Management for Linux
Copyright (c) 2023-2025 NTFS Manager Project

This software is licensed under a Dual License model:
- Personal use: LICENSE-PERSONAL
- Commercial use: LICENSE-COMMERCIAL
"""
```

---

## Recognition

### Contributors

All contributors are recognized in:
- [Contributors list](https://github.com/sprinteroz/Linux-NTFS-Manager/graphs/contributors)
- Release notes (for significant contributions)
- README acknowledgments

### Hall of Fame

Outstanding contributors may be featured in the project README.

---

## Additional Resources

### Documentation
- [Installation Guide](Installation-Guide)
- [User Guide](User-Guide)
- [API Documentation](API-Reference)
- [Security Policy](https://github.com/sprinteroz/Linux-NTFS-Manager/blob/main/SECURITY.md)

### Development
- [Python Documentation](https://docs.python.org/3/)
- [GTK Documentation](https://www.gtk.org/docs/)
- [NTFS-3G Documentation](https://www.tuxera.com/community/ntfs-3g-manual/)

### Tools
- [Black Formatter](https://black.readthedocs.io/)
- [Pytest](https://docs.pytest.org/)
- [MyPy](http://mypy-lang.org/)

---

## Questions?

- **General questions:** [GitHub Discussions](https://github.com/sprinteroz/Linux-NTFS-Manager/discussions)
- **Bug reports:** [GitHub Issues](https://github.com/sprinteroz/Linux-NTFS-Manager/issues)
- **Security issues:** support_ntfs@magdrivex.com.au

---

## Thank You!

Your contributions make NTFS Manager better for everyone. We appreciate your time and effort! 🎉

**Ready to contribute?** Start by:
1. [Forking the repository](#1-fork-the-repository)
2. [Setting up your development environment](#3-install-dependencies)
3. [Finding an issue to work on](https://github.com/sprinteroz/Linux-NTFS-Manager/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

Happy coding! 💻
