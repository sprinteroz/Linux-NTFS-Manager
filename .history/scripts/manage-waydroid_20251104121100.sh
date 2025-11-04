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
    if pgrep -u $USER -f "waydroid.*android" > /dev/null; then
        return 0
    else
        return 1
    fi
}

show_waydroid_status() {
    print_info "Checking Waydroid status..."
    echo ""
    
    # Container status
    if check_waydroid_running; then
        print_success "Waydroid container is RUNNING"
        local container_pid=$(pgrep -f "waydroid.*container")
        echo "  Container PID: $container_pid"
    else
        print_info "Waydroid container is NOT running"
    fi
    
    # Session status
    if check_waydroid_session; then
        print_success "Waydroid session is ACTIVE"
        local session_count=$(pgrep -u $USER -f "waydroid" | wc -l)
        echo "  Active processes: $session_count"
    else
        print_info "Waydroid session is NOT active"
    fi
    
    # Memory usage
    local total_mem=$(ps aux | grep waydroid | grep -v grep | awk '{sum+=$6} END {print sum/1024}')
    if [ -n "$total_mem" ] && [ "$total_mem" != "0" ]; then
        printf "  Total Memory Usage: %.0f MB\n" $total_mem
    fi
    
    # Show running services
    echo ""
    print_info "Waydroid processes:"
