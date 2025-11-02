#!/bin/bash

# NTFS Manager - GitHub Deployment Script
# Simple script to help deploy NTFS Manager to GitHub

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
GITHUB_USER="${GITHUB_USER:-magdrivex}"
REPO_NAME="ntfs-manager"

echo -e "${GREEN}🚀 NTFS Manager - GitHub Deployment Helper${NC}"
echo "========================================"

# Check if we're in the right directory
if [ ! -f "README.md" ]; then
    print_error "README.md not found. Please run this from the ntfs-manager root directory."
    exit 1
fi

# Check if setup script exists
if [ ! -f "setup-github-repo.sh" ]; then
    print_error "setup-github-repo.sh not found. Please run the setup script first."
    exit 1
fi

print_status "Step 1: Checking current Git status..."

# Check current git status
if [ -d ".git" ]; then
    print_status "Git repository already initialized"
    
    # Check if remote exists
    if git remote get-url origin >/dev/null 2>&1; then
        print_status "Remote origin already configured"
    else
        print_warning "No remote origin configured"
        echo -e "${YELLOW}Would you like to add remote origin now? (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy] ]]; then
            print_status "Adding remote origin..."
            git remote add origin https://github.com/$GITHUB_USER/$REPO_NAME.git
        fi
    fi
else
    print_warning "Git repository not initialized"
    echo -e "${YELLOW}Would you like to initialize Git repository now? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy] ]]; then
        print_status "Running setup script..."
        ./setup-github-repo.sh
    else
        print_status "Skipping Git initialization"
    fi
fi

print_status "Step 2: Staging files for commit..."

# Stage files
git add .

print_status "Step 3: Checking what's staged..."

# Show staged files
git status --porcelain

print_status "Step 4: Ready to create commit"
echo ""
echo -e "${GREEN}Files are staged and ready for commit.${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Create commit: git commit -m 'Your commit message'"
echo "2. Push to GitHub: git push origin main"
echo ""
echo -e "${GREEN}Repository is ready for GitHub operations!${NC}"
echo ""
echo -e "${BLUE}Repository URL: https://github.com/$GITHUB_USER/$REPO_NAME${NC}"
echo ""

# Optional: Create commit automatically
if [ "$1" = "--commit" ]; then
    print_status "Creating automatic commit..."
    git commit -m "NTFS Manager v2.0.0 - Ready for GitHub deployment"
    print_status "Commit created successfully"
    
    print_status "Pushing to GitHub..."
    git push origin main
    
    if [ $? -eq 0 ]; then
        print_status "Successfully pushed to GitHub!"
        echo -e "${GREEN}Your repository is now live at: https://github.com/$GITHUB_USER/$REPO_NAME${NC}"
    else
        print_error "Failed to push to GitHub"
    fi
fi

echo ""
echo -e "${YELLOW}Usage:${NC}"
echo "  $0 ./deploy-to-github.sh              # Check status"
echo "  $0 ./deploy-to-github.sh --commit       # Commit and push"
echo ""
echo -e "${GREEN}Repository is ready for deployment!${NC}"
