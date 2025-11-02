#!/bin/bash

# NTFS Manager - GitHub Repository Setup Script
# This script helps set up the NTFS Manager repository for GitHub upload

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_NAME="ntfs-manager"
REPO_DESCRIPTION="Professional NTFS Drive Management for Linux"
GITHUB_USER="${GITHUB_USER:-magdrivex}"
GITHUB_EMAIL="${GITHUB_EMAIL:-sales@magdrivex.com}"

echo -e "${BLUE}🚀 NTFS Manager - GitHub Repository Setup${NC}"
echo "========================================"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "README.md" ]; then
    print_error "README.md not found. Please run this from the ntfs-manager root directory."
    exit 1
fi

print_status "Step 1: Initializing Git repository..."

# Initialize git repository if not already done
if [ ! -d ".git" ]; then
    git init
    print_status "Git repository initialized"
else
    print_status "Git repository already exists"
fi

# Configure git user
print_status "Step 2: Configuring Git user..."
git config user.name "$GITHUB_USER"
git config user.email "$GITHUB_EMAIL"

# Add remote origin
print_status "Step 3: Adding remote origin..."
git remote add origin https://github.com/$GITHUB_USER/$REPO_NAME.git

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    print_warning ".gitignore not found - this should have been created already"
fi

# Stage all files
print_status "Step 4: Staging files..."
git add .

# Create initial commit
print_status "Step 5: Creating initial commit..."
git commit -m "Initial commit: NTFS Manager v2.0.0

🚀 Features:
- Professional NTFS drive management for Linux
- Dual licensing model (Free + Commercial)
- Multi-language support (30+ languages)
- Enterprise-grade CI/CD pipeline
- Comprehensive documentation and sales materials

📁 Repository Structure:
- Complete source code with modular architecture
- Professional documentation and sales materials
- GitHub Actions workflows for CI/CD
- Docker containerization support
- Multi-language support framework

🔧 Technical Stack:
- Python 3.8+ with GTK+ 3.0
- NTFS-3g integration for drive operations
- PyInstaller for cross-platform binaries
- GitHub Actions for automation
- Docker for containerization

📄 Business Model:
- Free license for personal/educational/non-profit use
- Commercial licenses for business/enterprise use
- Professional support and services
- Partnership opportunities for distributors and OEMs

🌍 Internationalization:
- GNU gettext framework for translations
- 30+ language support with automatic detection
- Community translation workflow
- Multi-language documentation

🔒 Security & Quality:
- Automated security scanning (Trivy, Bandit)
- Code quality checks (flake8, black, mypy)
- Comprehensive testing (unit, integration, performance)
- Vulnerability reporting and patching

This commit includes:
- Complete source codebase
- Professional documentation
- CI/CD pipeline configuration
- Multi-language support framework
- Business and sales documentation
- Docker containerization
- GitHub templates and workflows

Ready for production deployment and community engagement!

📞 Contact:
- Developer: Darryl Bennett
- Company: MagDriveX (2023-2025)
- Email: sales@magdrivex.com
- Website: www.magdrivex.com

© 2023-2025 MagDriveX. All rights reserved.
NTFS Manager is a trademark of MagDriveX."

if [ $? -eq 0 ]; then
    print_status "Initial commit created successfully"
else
    print_error "Failed to create initial commit"
    exit 1
fi

# Create main branch if it doesn't exist
print_status "Step 6: Setting up main branch..."
if ! git show-ref --verify --quiet refs/heads/main; then
    git branch main
    print_status "Created and switched to main branch"
else
    print_status "Main branch already exists"
fi

# Instructions for next steps
echo ""
print_status "Repository setup complete!"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Create GitHub repository at https://github.com/new"
echo "   - Repository name: $REPO_NAME"
echo "   - Description: $REPO_DESCRIPTION"
echo "   - Make it PUBLIC"
echo ""
echo -e "${YELLOW}2. Push to GitHub:${NC}"
echo "   git push -u origin main"
echo ""
echo -e "${YELLOW}3. Configure GitHub:${NC}"
echo "   - Enable GitHub Actions"
echo "   - Set up branch protection"
echo "   - Configure GitHub Pages for documentation"
echo "   - Add repository topics: linux, ntfs, drive-management, gtk, python"
echo ""
echo -e "${YELLOW}4. Configure Secrets (for CI/CD):${NC}"
echo "   - CODECOV_TOKEN: For code coverage reporting"
echo "   - DOCKER_USERNAME: For Docker Hub access"
echo "   - DOCKER_PASSWORD: For Docker Hub access"
echo ""
echo -e "${GREEN}Repository is ready for GitHub upload!${NC}"
echo ""
echo -e "${BLUE}Repository URL: https://github.com/$GITHUB_USER/$REPO_NAME${NC}"
echo ""
