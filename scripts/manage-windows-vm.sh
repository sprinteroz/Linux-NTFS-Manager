#!/bin/bash
# Windows VM Management Script
# Handles proper shutdown and resource management for QEMU Windows VM

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VM_NAME="windows"
QMP_PORT=7149
PIDFILE="/run/shm/qemu.pid"
LOGFILE="/run/shm/qemu.log"

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

check_vm_running() {
    if pgrep -f "qemu-system-x86_64.*name=$VM_NAME" > /dev/null; then
        return 0
    else
        return 1
    fi
}

get_vm_memory() {
    local mem_mb=$(ps aux | grep "qemu-system-x86_64.*name=$VM_NAME" | grep -v grep | awk '{print $6}')
    if [ -n "$mem_mb" ]; then
        echo "$((mem_mb / 1024))MB"
    else
        echo "0MB"
    fi
}

show_vm_status() {
    print_info "Checking Windows VM status..."
    
    if check_vm_running; then
        local pid=$(pgrep -f "qemu-system-x86_64.*name=$VM_NAME")
        local mem=$(get_vm_memory)
        print_success "Windows VM is RUNNING"
        echo "  PID: $pid"
        echo "  Memory Usage: $mem"
        echo "  QMP Port: $QMP_PORT"
        
        # Show memory allocation
        local allocated=$(ps aux | grep "qemu-system-x86_64.*name=$VM_NAME" | grep -o '\-m [0-9]*[GM]' | awk '{print $2}')
        echo "  Allocated Memory: $allocated"
    else
        print_info "Windows VM is NOT running"
    fi
}

graceful_shutdown() {
    print_info "Initiating graceful shutdown of Windows VM..."
    
    if ! check_vm_running; then
        print_warning "VM is not running"
        return 1
    fi
    
    # Try QMP command first
    print_info "Sending ACPI shutdown command via QMP..."
    echo '{ "execute": "system_powerdown" }' | nc localhost $QMP_PORT > /dev/null 2>&1
    
    # Wait for shutdown (max 30 seconds)
    local count=0
    while check_vm_running && [ $count -lt 30 ]; do
        sleep 1
        count=$((count + 1))
        echo -n "."
    done
    echo ""
    
    if check_vm_running; then
        print_warning "VM did not shutdown gracefully within 30 seconds"
        return 1
    else
        print_success "VM shutdown successfully"
        return 0
    fi
}

force_shutdown() {
    print_warning "Force shutting down Windows VM..."
    
    if ! check_vm_running; then
        print_info "VM is not running"
        return 0
    fi
    
    local pid=$(pgrep -f "qemu-system-x86_64.*name=$VM_NAME")
    
    # Try SIGTERM first
    print_info "Sending SIGTERM to PID $pid..."
    sudo kill -TERM $pid
    
    sleep 3
    
    if check_vm_running; then
        print_warning "SIGTERM failed, sending SIGKILL..."
        sudo kill -9 $pid
        sleep 1
    fi
    
    if ! check_vm_running; then
        print_success "VM terminated"
        
        # Cleanup
        [ -f "$PIDFILE" ] && sudo rm -f "$PIDFILE"
        
        return 0
    else
        print_error "Failed to terminate VM"
        return 1
    fi
}

auto_shutdown_monitor() {
    print_info "Starting auto-shutdown monitor..."
    print_info "Will monitor VM and shutdown when no active connections detected"
    print_warning "This monitor runs continuously - use systemctl to stop"
    
    local vm_was_running=false
    
    while true; do
        if check_vm_running; then
            vm_was_running=true
            # Check if VNC has active connections
            local vnc_connections=$(netstat -tn | grep ":5900 " | grep ESTABLISHED | wc -l)
            
            if [ $vnc_connections -eq 0 ]; then
                print_info "No active VNC connections detected"
                print_info "Waiting 60 seconds before shutdown..."
                sleep 60
                
                # Check again
                vnc_connections=$(netstat -tn | grep ":5900 " | grep ESTABLISHED | wc -l)
                if [ $vnc_connections -eq 0 ]; then
                    print_info "Still no connections, shutting down VM..."
                    graceful_shutdown
                    # Continue monitoring in case VM starts again
                    vm_was_running=false
                fi
            else
                print_info "Active connections: $vnc_connections - VM staying up"
            fi
        else
            if [ "$vm_was_running" = true ]; then
                print_info "VM has stopped"
                vm_was_running=false
            fi
            # Wait and check again - VM might start later
        fi
        
        sleep 30
    done
}

reduce_memory() {
    print_error "Cannot dynamically reduce memory of running VM"
    print_info "To reduce memory allocation:"
    print_info "1. Shutdown the VM: $0 shutdown"
    print_info "2. Find the VM startup script and modify the '-m 64G' parameter"
    print_info "3. Recommended: Use '-m 32G' or '-m 16G' instead"
}

show_memory_stats() {
    print_info "System Memory Statistics:"
    echo ""
    free -h
    echo ""
    
    if check_vm_running; then
        print_info "Windows VM Memory Usage:"
        local vm_pid=$(pgrep -f "qemu-system-x86_64.*name=$VM_NAME")
        ps aux | head -1
        ps aux | grep $vm_pid | grep -v grep
    fi
}

show_help() {
    cat << EOF
Windows VM Management Script
Usage: $0 [COMMAND]

Commands:
    status          Show VM status and resource usage
    shutdown        Gracefully shutdown the VM (ACPI powerdown)
    force-stop      Force terminate the VM (kill process)
    monitor         Start auto-shutdown monitor (stops when no VNC connections)
    memory-stats    Show system and VM memory usage
    reduce-memory   Show instructions for reducing VM memory allocation
    help            Show this help message

Examples:
    $0 status
    $0 shutdown
    $0 monitor
    $0 memory-stats

EOF
}

# Main script logic
case "${1:-help}" in
    status)
        show_vm_status
        ;;
    shutdown)
        if graceful_shutdown; then
            exit 0
        else
            print_warning "Graceful shutdown failed, use 'force-stop' if needed"
            exit 1
        fi
        ;;
    force-stop)
        force_shutdown
        ;;
    monitor)
        auto_shutdown_monitor
        ;;
    memory-stats)
        show_memory_stats
        ;;
    reduce-memory)
        reduce_memory
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
