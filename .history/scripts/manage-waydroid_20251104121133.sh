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
    ps aux | grep waydroid | grep -v grep | grep -v "manage-waydroid"
}

graceful_stop() {
    print_info "Stopping Waydroid session gracefully..."
    
    if ! check_waydroid_session; then
        print_warning "Waydroid session is not running"
    else
        print_info "Stopping user session..."
        waydroid session stop 2>/dev/null
        sleep 2
    fi
    
    if ! check_waydroid_running; then
        print_info "Waydroid container is not running"
    else
        print_info "Stopping container..."
        sudo waydroid container stop 2>/dev/null
        sleep 2
    fi
    
    # Verify stopped
    if ! check_waydroid_running && ! check_waydroid_session; then
        print_success "Waydroid stopped successfully"
        return 0
    else
        print_warning "Waydroid may not have stopped completely"
        return 1
    fi
}

force_stop() {
    print_warning "Force stopping all Waydroid processes..."
    
    # Kill all waydroid processes
    pkill -9 -f waydroid
    sudo pkill -9 -f waydroid
    
    # Kill LXC container
    sudo pkill -9 -f "lxc-start.*waydroid"
    
    # Stop dnsmasq for waydroid
    sudo pkill -9 -f "dnsmasq.*waydroid"
    
    sleep 2
    
    if ! check_waydroid_running && ! check_waydroid_session; then
        print_success "All Waydroid processes terminated"
        return 0
    else
        print_error "Some Waydroid processes may still be running"
        return 1
    fi
}

start_waydroid() {
    print_info "Starting Waydroid..."
    
    if check_waydroid_running; then
        print_warning "Waydroid container is already running"
    else
        print_info "Starting container..."
        sudo waydroid container start &
        sleep 3
    fi
    
    if check_waydroid_session; then
        print_warning "Waydroid session is already active"
    else
        print_info "Starting session..."
        waydroid session start &
        sleep 3
    fi
    
    if check_waydroid_running && check_waydroid_session; then
        print_success "Waydroid started successfully"
        return 0
    else
        print_warning "Waydroid may not have started properly"
        return 1
    fi
}

restart_waydroid() {
    print_info "Restarting Waydroid..."
    graceful_stop
    sleep 2
    start_waydroid
}

fix_gnome_shell_crash() {
    print_info "Attempting to fix GNOME Shell/Waydroid icon crashes..."
    echo ""
    
    # Stop Waydroid first
    print_info "Step 1: Stopping Waydroid..."
    graceful_stop
    sleep 2
    
    # Restart GNOME Shell (X11 only - won't work on Wayland)
    if [ "$XDG_SESSION_TYPE" = "x11" ]; then
        print_info "Step 2: Restarting GNOME Shell (X11)..."
        killall -HUP gnome-shell
        sleep 3
    else
        print_warning "Step 2: Cannot restart GNOME Shell on Wayland"
        print_info "You need to log out and log back in, or restart the system"
    fi
    
    # Clear Waydroid cache
    print_info "Step 3: Clearing Waydroid cache..."
    rm -rf ~/.local/share/waydroid/cache/* 2>/dev/null
    rm -rf ~/.cache/waydroid/* 2>/dev/null
    
    # Restart Waydroid
    print_info "Step 4: Starting Waydroid fresh..."
    sleep 2
    start_waydroid
    
    echo ""
    print_success "Fix attempt complete"
    print_info "If icons are still missing, you need to:"
    print_info "1. Close all applications"
    print_info "2. Log out completely"
    print_info "3. Log back in"
    echo ""
    print_info "Alternative: Full system restart usually fixes icon issues"
}

full_system_fix() {
    print_warning "FULL SYSTEM FIX - This will stop Waydroid and clear all caches"
    print_warning "Press Ctrl+C within 5 seconds to cancel..."
    sleep 5
    
    print_info "Stage 1: Force stopping Waydroid..."
    force_stop
    
    print_info "Stage 2: Clearing all Waydroid data caches..."
    rm -rf ~/.local/share/waydroid/cache/* 2>/dev/null
    rm -rf ~/.cache/waydroid/* 2>/dev/null
    rm -rf /tmp/waydroid* 2>/dev/null
    
    print_info "Stage 3: Clearing GNOME Shell caches..."
    rm -rf ~/.cache/gnome-shell/* 2>/dev/null
    
    print_info "Stage 4: Resetting Waydroid network..."
    sudo ip link delete waydroid0 2>/dev/null
    
    print_success "System cleaned"
    echo ""
    print_warning "IMPORTANT: You must now:"
    print_info "1. Close this terminal"
    print_info "2. Log out completely"
    print_info "3. Log back in"
    print_info "4. Start Waydroid normally"
    echo ""
    print_info "This should fix icon and crash issues"
}

auto_stop_when_idle() {
    print_info "Starting idle monitoring..."
    print_info "Will stop Waydroid after 5 minutes of no Android app activity"
    print_warning "Press Ctrl+C to stop monitoring"
    echo ""
    
    local idle_threshold=300  # 5 minutes
    local idle_count=0
    
    while true; do
        if check_waydroid_session; then
            # Count Android processes (excluding system services)
            local app_count=$(ps aux | grep -E "android.*app_process" | grep -v grep | wc -l)
            
            if [ $app_count -le 5 ]; then  # Only system processes
                idle_count=$((idle_count + 30))
                print_info "Idle for ${idle_count}s (apps: $app_count) - Threshold: ${idle_threshold}s"
                
                if [ $idle_count -ge $idle_threshold ]; then
                    print_warning "Idle threshold reached, stopping Waydroid..."
                    graceful_stop
                    print_success "Waydroid stopped due to inactivity"
                    break
                fi
            else
                idle_count=0
                print_info "Active apps detected: $app_count - Resetting idle counter"
            fi
        else
            print_info "Waydroid is not running"
            break
        fi
        
        sleep 30
    done
}

show_memory_usage() {
    print_info "Waydroid Memory Usage:"
    echo ""
    
    if ! check_waydroid_running; then
        print_info "Waydroid is not running - No memory usage"
        return
    fi
    
    echo "Process Details:"
    ps aux | head -1
    ps aux | grep waydroid | grep -v grep | grep -v "manage-waydroid"
    echo ""
    
    local total_mem=$(ps aux | grep waydroid | grep -v grep | awk '{sum+=$6} END {print sum/1024}')
    printf "Total Waydroid Memory: %.0f MB\n" $total_mem
}

show_help() {
    cat << EOF
Waydroid Management Script
Handles session lifecycle and fixes GNOME Shell crashes

Usage: $0 [COMMAND]

Commands:
    status          Show Waydroid status and resource usage
    start           Start Waydroid session
    stop            Stop Waydroid gracefully
    restart         Restart Waydroid
    force-stop      Force kill all Waydroid processes
    
    fix-icons       Fix GNOME Shell icon crashes (restarts shell)
    full-fix        Full system fix (clears all caches, requires logout)
    monitor         Auto-stop when idle (5 minutes)
    memory          Show memory usage details
    
    help            Show this help message

Examples:
    $0 status
    $0 stop
    $0 fix-icons
    $0 monitor
    $0 full-fix

Notes:
    - Icon issues usually require logout/login or system restart
    - Use 'full-fix' for persistent problems
    - Use 'monitor' to auto-stop when not in use

EOF
}

# Main script logic
case "${1:-help}" in
    status)
        show_waydroid_status
        ;;
    start)
        start_waydroid
        ;;
    stop)
        graceful_stop
        ;;
    restart)
        restart_waydroid
        ;;
    force-stop)
        force_stop
        ;;
    fix-icons)
        fix_gnome_shell_crash
        ;;
    full-fix)
        full_system_fix
        ;;
    monitor)
        auto_stop_when_idle
        ;;
    memory)
        show_memory_usage
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
