#!/bin/bash
# Installation script for Windows VM Auto-Monitor

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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="$SCRIPT_DIR/windows-vm-monitor.service"
MANAGE_SCRIPT="$SCRIPT_DIR/manage-windows-vm.sh"

print_info "Windows VM Auto-Monitor Installation Script"
echo ""

# Check if running as root (needed for systemd operations)
if [ "$EUID" -ne 0 ]; then 
    print_error "This script must be run with sudo"
    echo "Usage: sudo $0"
    exit 1
fi

# Check if service file exists
if [ ! -f "$SERVICE_FILE" ]; then
    print_error "Service file not found: $SERVICE_FILE"
    exit 1
fi

# Check if management script exists
if [ ! -f "$MANAGE_SCRIPT" ]; then
    print_error "Management script not found: $MANAGE_SCRIPT"
    exit 1
fi

# Make management script executable
print_info "Making management script executable..."
chmod +x "$MANAGE_SCRIPT"
print_success "Management script is now executable"

# Copy service file to systemd directory
print_info "Installing systemd service..."
cp "$SERVICE_FILE" /etc/systemd/system/windows-vm-monitor.service

if [ $? -eq 0 ]; then
    print_success "Service file installed to /etc/systemd/system/"
else
    print_error "Failed to copy service file"
    exit 1
fi

# Reload systemd daemon
print_info "Reloading systemd daemon..."
systemctl daemon-reload

if [ $? -eq 0 ]; then
    print_success "Systemd daemon reloaded"
else
    print_error "Failed to reload systemd daemon"
    exit 1
fi

# Enable the service
print_info "Enabling Windows VM auto-monitor service..."
systemctl enable windows-vm-monitor.service

if [ $? -eq 0 ]; then
    print_success "Service enabled (will start on boot)"
else
    print_error "Failed to enable service"
    exit 1
fi

# Start the service
print_info "Starting Windows VM auto-monitor service..."
systemctl start windows-vm-monitor.service

if [ $? -eq 0 ]; then
    print_success "Service started successfully"
else
    print_error "Failed to start service"
    exit 1
fi

# Wait a moment for service to initialize
sleep 2

# Check service status
print_info "Checking service status..."
systemctl status windows-vm-monitor.service --no-pager | head -15

echo ""
print_success "Installation complete!"
echo ""
echo "The Windows VM auto-monitor is now running and will:"
echo "  • Monitor the Windows VM for VNC connections"
echo "  • Auto-shutdown the VM after 60 seconds of no connections"
echo "  • Free up ~64GB of RAM when the VM is idle"
echo "  • Restart monitoring automatically if the VM starts again"
echo ""
echo "Useful commands:"
echo "  View status:  sudo systemctl status windows-vm-monitor"
echo "  View logs:    sudo journalctl -u windows-vm-monitor -f"
echo "  Stop monitor: sudo systemctl stop windows-vm-monitor"
echo "  Disable:      sudo systemctl disable windows-vm-monitor"
echo "  Manual VM:    $MANAGE_SCRIPT status|shutdown|force-stop"
echo ""
