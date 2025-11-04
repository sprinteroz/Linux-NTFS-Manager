#!/bin/bash
# System Resource Monitor
# Monitors memory, CPU, and identifies resource-hungry processes

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  System Resource Monitor${NC}"
    echo -e "${CYAN}================================${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[CRITICAL]${NC} $1"
}

get_memory_percentage() {
    free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}'
}

get_swap_percentage() {
    free | grep Swap | awk '{if ($2 > 0) printf "%.1f", ($3/$2) * 100.0; else print "0.0"}'
}

check_memory_status() {
    local mem_percent=$(get_memory_percentage)
    local mem_int=${mem_percent%.*}
    
    if [ "$mem_int" -ge 90 ]; then
        print_error "Memory usage: ${mem_percent}% (CRITICAL)"
        return 2
    elif [ "$mem_int" -ge 80 ]; then
        print_warning "Memory usage: ${mem_percent}% (High)"
        return 1
    else
        print_success "Memory usage: ${mem_percent}% (Normal)"
        return 0
    fi
}

show_memory_details() {
    echo -e "\n${CYAN}=== Memory Overview ===${NC}"
    free -h
    echo ""
    
    check_memory_status
    echo ""
    
    local swap_percent=$(get_swap_percentage)
    local swap_int=${swap_percent%.*}
    
    if [ "$swap_int" -gt 0 ]; then
        print_warning "Swap usage: ${swap_percent}% (System is swapping)"
    else
        print_success "Swap usage: ${swap_percent}% (No swapping)"
    fi
}

show_top_memory_consumers() {
    echo -e "\n${CYAN}=== Top 10 Memory Consumers ===${NC}"
    echo ""
    ps aux --sort=-%mem | head -11 | awk 'BEGIN {printf "%-10s %-8s %-8s %-8s %s\n", "USER", "PID", "%MEM", "RSS(MB)", "COMMAND"} NR>1 {printf "%-10s %-8s %-8s %-8.0f %s\n", $1, $2, $4, $6/1024, $11}'
}

show_top_cpu_consumers() {
    echo -e "\n${CYAN}=== Top 10 CPU Consumers ===${NC}"
    echo ""
    ps aux --sort=-%cpu | head -11 | awk 'BEGIN {printf "%-10s %-8s %-8s %-8s %s\n", "USER", "PID", "%CPU", "%MEM", "COMMAND"} NR>1 {printf "%-10s %-8s %-8s %-8s %s\n", $1, $2, $3, $4, $11}'
}

analyze_problem_processes() {
    echo -e "\n${CYAN}=== Problem Process Analysis ===${NC}"
    echo ""
    
    # Check VS Code instances
    local vscode_count=$(ps aux | grep -c "[c]ode --")
    local vscode_mem=$(ps aux | grep "[c]ode" | awk '{sum+=$6} END {printf "%.0f", sum/1024}')
    if [ "$vscode_count" -gt 5 ]; then
        print_warning "VS Code: $vscode_count instances, ${vscode_mem}MB total memory"
        echo "  Consider closing unused VS Code windows"
    else
        print_success "VS Code: $vscode_count instances, ${vscode_mem}MB"
    fi
    
    # Check Windows VM
    if pgrep -f "qemu-system.*windows" > /dev/null; then
        local vm_mem=$(ps aux | grep "qemu-system.*windows" | grep -v grep | awk '{printf "%.0f", $6/1024}')
        local vm_allocated=$(ps aux | grep "qemu-system.*windows" | grep -o '\-m [0-9]*[GM]' | awk '{print $2}')
        print_warning "Windows VM: Running (${vm_mem}MB used, ${vm_allocated} allocated)"
        echo "  Use: ./manage-windows-vm.sh shutdown"
    else
        print_success "Windows VM: Not running"
    fi
    
    # Check Waydroid
    if pgrep -f "waydroid" > /dev/null; then
        local waydroid_mem=$(ps aux | grep waydroid | grep -v grep | awk '{sum+=$6} END {printf "%.0f", sum/1024}')
        local waydroid_procs=$(pgrep -f "waydroid" | wc -l)
        print_info "Waydroid: Running ($waydroid_procs processes, ${waydroid_mem}MB)"
        echo "  Use: ./manage-waydroid.sh stop"
    else
        print_success "Waydroid: Not running"
    fi
    
    # Check NTFS Manager
    if pgrep -f "ntfs-manager" > /dev/null; then
        local ntfs_mem=$(ps aux | grep "ntfs-manager" | grep -v grep | awk '{sum+=$6} END {printf "%.0f", sum/1024}')
        print_info "NTFS Manager: Running (${ntfs_mem}MB)"
    else
        print_info "NTFS Manager: Not running"
    fi
}

suggest_actions() {
    local mem_percent=$(get_memory_percentage)
    local mem_int=${mem_percent%.*}
    
    echo -e "\n${CYAN}=== Recommended Actions ===${NC}"
    echo ""
    
    if [ "$mem_int" -ge 90 ]; then
        echo -e "${RED}URGENT:${NC} System resources critically low!"
        echo "  1. Close unnecessary applications immediately"
        echo "  2. ./manage-windows-vm.sh shutdown"
        echo "  3. ./manage-waydroid.sh stop"
        echo "  4. Close unused VS Code windows"
        echo "  5. Restart system if problems persist"
    elif [ "$mem_int" -ge 80 ]; then
        echo -e "${YELLOW}High memory usage detected${NC}"
        echo "  1. Consider shutting down Windows VM if not in use"
        echo "  2. Stop Waydroid if not needed"
        echo "  3. Close unused browser tabs and applications"
        echo "  4. Review VS Code extensions and open projects"
    else
        echo -e "${GREEN}System resources are healthy${NC}"
        echo "  No immediate action required"
    fi
}

continuous_monitor() {
    print_info "Starting continuous monitoring (Ctrl+C to stop)..."
    print_info "Updates every 5 seconds"
    echo ""
    
    while true; do
        clear
        print_header
        
        # Quick stats
        local mem_pct=$(get_memory_percentage)
        local swap_pct=$(get_swap_percentage)
        local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
        
        echo "Time: $(date '+%H:%M:%S')"
        echo "Memory: ${mem_pct}% | Swap: ${swap_pct}% | Load: ${load}"
        echo ""
        
        # Top processes
        echo -e "${CYAN}Top 5 Memory Consumers:${NC}"
        ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "  %-20s %6s%%  %8.0fMB\n", $11, $4, $6/1024}'
        
        sleep 5
    done
}

quick_check() {
    print_header
    
    local mem_percent=$(get_memory_percentage)
    local mem_int=${mem_percent%.*}
    
    if [ "$mem_int" -ge 80 ]; then
        show_memory_details
        analyze_problem_processes
        suggest_actions
        return 1
    else
        print_success "System resources are healthy"
        echo "  Memory: ${mem_percent}%"
        echo "  Run with 'full' for detailed report"
        return 0
    fi
}

full_report() {
    print_header
    show_memory_details
    show_top_memory_consumers
    show_top_cpu_consumers
    analyze_problem_processes
    suggest_actions
}

export_report() {
    local filename="${1:-/tmp/system-report-$(date +%Y%m%d-%H%M%S).txt}"
    
    print_info "Generating system report..."
    
    {
        echo "System Resource Report"
        echo "Generated: $(date)"
        echo "========================================"
        echo ""
        
        echo "=== System Information ==="
        uname -a
        echo ""
        
        echo "=== Memory Status ==="
        free -h
        echo ""
        
        echo "=== Top Memory Consumers ==="
        ps aux --sort=-%mem | head -20
        echo ""
        
        echo "=== Top CPU Consumers ==="
        ps aux --sort=-%cpu | head -20
        echo ""
        
        echo "=== Disk Usage ==="
        df -h
        echo ""
        
        echo "=== System Load ==="
        uptime
        echo ""
        
        echo "=== Running Services ==="
        systemctl list-units --type=service --state=running
        
    } > "$filename"
    
    print_success "Report saved to: $filename"
}

show_help() {
    cat << EOF
System Resource Monitor
Monitors and analyzes system resource usage

Usage: $0 [COMMAND]

Commands:
    quick       Quick check (default) - Shows alert if memory >80%
    full        Full detailed report
    monitor     Continuous monitoring (updates every 5s)
    export      Export detailed report to file [filename]
    help        Show this help message

Examples:
    $0                          # Quick check
    $0 full                     # Full report
    $0 monitor                  # Live monitoring
    $0 export /tmp/report.txt   # Export report

Related Scripts:
    ./manage-windows-vm.sh      # Manage Windows VM
    ./manage-waydroid.sh        # Manage Waydroid

EOF
}

# Main script logic
case "${1:-quick}" in
    quick)
        quick_check
        ;;
    full)
        full_report
        ;;
    monitor)
        continuous_monitor
        ;;
    export)
        export_report "$2"
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
