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
