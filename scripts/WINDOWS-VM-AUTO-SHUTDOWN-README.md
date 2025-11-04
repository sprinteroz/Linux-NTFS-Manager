# Windows VM Auto-Shutdown Monitor

## Overview

This system automatically monitors your Windows VM (QEMU) and shuts it down when it's idle (no VNC connections), freeing up **~64GB of RAM** when the VM is not in use.

## Problem Solved

Your system showed **71.6GB RAM usage (57%)** but Stacer's process list didn't show what was using it. The culprit was:
- **Windows VM (qemu-system-x86_64)** running as root
- **64GB RAM allocated** to the VM
- VM was pre-loaded at system startup (for winboot integration)
- Running continuously even when not actively being used

## Solution Implemented

An automatic monitoring service that:
1. **Monitors** the Windows VM continuously
2. **Detects** when no VNC connections are present (idle VM)
3. **Waits** 60 seconds to confirm the VM is truly idle
4. **Shuts down** the VM gracefully to free RAM
5. **Continues monitoring** in case the VM starts again later

## Current Status

✅ **Service Installed**: `windows-vm-monitor.service`
✅ **Service Enabled**: Will start automatically on boot
✅ **Currently Running**: Monitoring in the background

## Management Commands

### Check Service Status
```bash
sudo systemctl status windows-vm-monitor
```

### View Live Monitoring Logs
```bash
sudo journalctl -u windows-vm-monitor -f
```

### Stop the Auto-Monitor (temporarily)
```bash
sudo systemctl stop windows-vm-monitor
```

### Restart the Auto-Monitor
```bash
sudo systemctl start windows-vm-monitor
```

### Disable Auto-Monitor (won't start on boot)
```bash
sudo systemctl disable windows-vm-monitor
```

### Re-enable Auto-Monitor
```bash
sudo systemctl enable windows-vm-monitor
```

## Manual VM Management

You can also manually control the VM using the management script:

```bash
# Check if VM is running and see memory usage
./scripts/manage-windows-vm.sh status

# Manually shutdown the VM (graceful)
./scripts/manage-windows-vm.sh shutdown

# Force stop the VM (if graceful shutdown fails)
./scripts/manage-windows-vm.sh force-stop

# View system memory statistics
./scripts/manage-windows-vm.sh memory-stats

# View all available commands
./scripts/manage-windows-vm.sh help
```

## How It Works

1. **Continuous Monitoring**: The service runs every 30 seconds
2. **VM Detection**: Checks if Windows VM is running
3. **Connection Check**: Looks for active VNC connections on port 5900
4. **Idle Detection**: If no connections found, waits 60 seconds
5. **Auto-Shutdown**: After confirming idle state, sends ACPI shutdown command
6. **Memory Recovery**: ~64GB RAM is freed when VM shuts down
7. **Resume Monitoring**: Continues watching for VM restart

## Expected Behavior

### When VM is Active (VNC connected)
- Monitor detects connections
- Logs: "Active connections: X - VM staying up"
- VM continues running
- RAM remains allocated

### When VM is Idle (No VNC connections)
- Monitor detects no connections
- Waits 60 seconds to confirm
- Gracefully shuts down VM
- ~64GB RAM is freed
- Monitor continues running (watching for VM restart)

### When VM is Not Running
- Monitor waits silently
- No action taken
- Minimal resource usage
- Ready to detect when VM starts

## Memory Impact

**Before Auto-Shutdown:**
- Total RAM: 125 GiB
- Used: 71.6 GiB (57%)
- VM Allocation: 64 GiB
- Available: 52 GiB

**After VM Shutdown:**
- Total RAM: 125 GiB
- Used: ~7-10 GiB (6-8%)
- VM Allocation: 0 GiB
- Available: 115-118 GiB

## Files Created

- `scripts/windows-vm-monitor.service` - Systemd service definition
- `scripts/install-vm-auto-monitor.sh` - Installation script
- `scripts/manage-windows-vm.sh` - Enhanced VM management script
- `scripts/WINDOWS-VM-AUTO-SHUTDOWN-README.md` - This documentation

## Troubleshooting

### Service Not Running?
```bash
sudo systemctl status windows-vm-monitor
sudo journalctl -u windows-vm-monitor -n 50
```

### VM Won't Shutdown?
```bash
# Try manual shutdown
./scripts/manage-windows-vm.sh shutdown

# If that fails, force stop
./scripts/manage-windows-vm.sh force-stop
```

### Want to Check Current Memory?
```bash
free -h
# or
./scripts/manage-windows-vm.sh memory-stats
```

### Want to Uninstall?
```bash
sudo systemctl stop windows-vm-monitor
sudo systemctl disable windows-vm-monitor
sudo rm /etc/systemd/system/windows-vm-monitor.service
sudo systemctl daemon-reload
```

## Notes

- The monitor runs as **root** (required for VM shutdown commands)
- Service auto-restarts if it crashes
- Logs are stored in systemd journal
- VNC port 5900 is used for connection detection
- 60-second idle timeout helps prevent false shutdowns
- Monitor continues running even when VM is off (ready for restart)

## Future Enhancements (Optional)

If you want to further optimize:

1. **Reduce VM Memory Allocation**
   - Current: 64GB
   - Could reduce to: 32GB or 16GB
   - Edit VM startup config and change `-m 64G` parameter

2. **Adjust Idle Timeout**
   - Current: 60 seconds
   - Edit `scripts/manage-windows-vm.sh`
   - Change `sleep 60` in the auto_shutdown_monitor function

3. **Monitor Multiple Ports**
   - Add additional connection checks
   - Useful if VM has other network services

## Support

For issues or questions:
- Check logs: `sudo journalctl -u windows-vm-monitor -f`
- Check VM status: `./scripts/manage-windows-vm.sh status`
- Review this documentation

---

**Installation Date**: November 4, 2025  
**System**: Ubuntu 24.04.3 LTS  
**Memory**: 125 GiB RAM  
**VM**: Windows (QEMU/KVM)
