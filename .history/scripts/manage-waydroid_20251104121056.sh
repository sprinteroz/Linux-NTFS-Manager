#!/bin/bash
# Waydroid Management Script
# Handles Waydroid session lifecycle and fixes icon/crash issues

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_waydroid_running() {
    if pgrep -f "waydroid.*container" > /dev/null; then
        return 0
    else
        return 1
    fi
}

check_waydroid_session() {
