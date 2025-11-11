# NTFS Enhancement Implementation Plan v1.0.7

## Executive Summary

This document outlines the detailed implementation strategy for comprehensive NTFS mounting improvements in Linux NTFS Manager v1.0.7, based on community best practices and addressing critical gaps identified in Phase 1 audit.

## Critical Issues Identified

### Current Implementation Problems
1. **No default mount options** - Empty string passed to udisksctl
2. **No driver detection** - No awareness of ntfs3 vs ntfs-3g vs lowntfs-3g
3. **No driver fallback** - Single mount attempt with no retry logic
4. **Generic error messages** - Users get unhelpful errors for dirty volumes
5. **No filesystem optimization** - Same approach for all filesystems

## Phase 2: Documentation Strategy

### 2.1 Create NTFS Mounting Guide (`docs/NTFS-MOUNTING-GUIDE.md`)

**Content Structure:**
```markdown
# NTFS Mounting Guide for Linux

## Overview
- NTFS driver landscape (ntfs3, ntfs-3g, lowntfs-3g)
- Driver availability by kernel version
- Performance characteristics

## Recommended Mount Options

### For ntfs3 (Kernel 5.15+)
- nofail: Continue boot if drive unavailable
- users: Allow non-root mounting
- prealloc: Enable file preallocation (performance)
- windows_names: Enforce Windows filename rules
- nocase: Case-insensitive filenames (Windows compatibility)

### For ntfs-3g/lowntfs-3g (FUSE drivers)
- nofail: Continue boot if drive unavailable  
- noexec: Prevent execution for security
- windows_names: Enforce Windows filename rules

## Common Issues

### Dirty Volume (Most Common)
- Cause: Improper Windows shutdown, Fast Startup enabled
- Symptoms: "NTFS is marked dirty" error
- Solutions:
  1. Boot Windows and shut down properly
  2. Disable Windows Fast Startup
  3. Use ntfsfix (READ RISKS FIRST)
  4. Mount read-only temporarily

### Windows Fast Startup Warning
**CRITICAL**: Disabling Fast Startup is essential for dual-boot systems
- Location: Control Panel → Power Options → Choose what power buttons do
- Effect: Ensures clean NTFS unmount on shutdown
- Prevents: Dirty volumes, data corruption, mount failures

### Driver Selection
- Automatic detection and fallback
- Manual override when needed
- Performance vs compatibility trade-offs

## Advanced Topics
- fstab configuration examples
- Custom mount options
- Troubleshooting workflows
```

**Implementation:**
- Create comprehensive guide covering all scenarios
- Include command examples and screenshots
- Add warning boxes for critical information
- Reference from main README and Installation Guide

### 2.2 Update Troubleshooting Guide

**Additions to `wiki-content/Troubleshooting.md`:**
```markdown
## NTFS Mounting Issues

### "NTFS is marked dirty" Error

This error occurs when Windows did not unmount the NTFS filesystem cleanly.

**Common Causes:**
1. Windows Fast Startup enabled (most common in dual-boot)
2. Improper Windows shutdown (power loss, forced shutdown)
3. System crash while NTFS was mounted

**Solutions (in order of safety):**

1. **Best Solution: Boot Windows and shut down properly**
   - Boot into Windows
   - Shutdown (not restart) properly
   - Boot back to Linux

2. **Disable Windows Fast Startup** (Prevents future issues)
   - Control Panel → Power Options
   - Choose what the power buttons do
   - Change settings currently unavailable
   - Uncheck "Turn on fast startup"
   - Save changes

3. **Use ntfsfix** (Use with caution)
   - Linux NTFS Manager provides guided repair
   - Run CHKDSK in Windows for better results
   - See NTFS Mounting Guide for details

4. **Temporary read-only access**
   - Mount with -o ro flag
   - Access files without modifications
   - Plan proper repair in Windows

### Driver Detection Issues

If automatic driver detection fails:
- Check installed drivers: `modprobe -l | grep ntfs`
- Verify ntfs-3g package: `dpkg -l | grep ntfs-3g`
- Review logs: Check application logs for driver detection results

### Performance Issues

If NTFS performance is slow:
- Ensure ntfs3 kernel driver is being used (5.15+ kernels)
- Check mount options: `mount | grep ntfs`
- Consider defragmentation in Windows
- Verify drive health with SMART data
```

### 2.3 Update Main README

**Add section after Installation:**
```markdown
## NTFS Support

Linux NTFS Manager provides intelligent NTFS mounting with:

- **Automatic driver detection**: Selects best available driver (ntfs3, lowntfs-3g, ntfs-3g)
- **Optimized mount options**: Driver-specific options for safety and performance
- **Driver fallback**: Automatic retry with alternative drivers
- **Dirty volume detection**: Helps diagnose and fix improperly unmounted drives
- **Troubleshooting wizard**: Step-by-step guidance for common NTFS issues

For detailed information, see:
- [NTFS Mounting Guide](docs/NTFS-MOUNTING-GUIDE.md)
- [Troubleshooting Guide](wiki-content/Troubleshooting.md)

**Important for dual-boot users**: Disable Windows Fast Startup to prevent mount issues.
```

## Phase 3: Code Implementation

### 3.1 Driver Detection System

**New Method: `_detect_ntfs_driver()`**

Location: `ntfs-complete-manager-gui/backend/drive_manager.py`

```python
def _detect_ntfs_driver(self) -> str:
    """
    Detect best available NTFS driver
    Priority: ntfs3 > lowntfs-3g > ntfs-3g
    
    Returns:
        str: Driver name ('ntfs3', 'lowntfs-3g', 'ntfs-3g', or 'unknown')
    """
    # Check for ntfs3 kernel module (kernel 5.15+)
    try:
        result = subprocess.run(
            ["modprobe", "-l", "ntfs3"],
            capture_output=True, text=True
        )
        if result.returncode == 0 and "ntfs3" in result.stdout:
            # Verify kernel version
            kernel_info = subprocess.run(
                ["uname", "-r"],
                capture_output=True, text=True, check=True
            )
            kernel_version = kernel_info.stdout.strip()
            # Parse version (e.g., "5.15.0-53-generic" -> 5.15)
            major, minor = kernel_version.split('.')[:2]
            if int(major) > 5 or (int(major) == 5 and int(minor) >= 15):
                return "ntfs3"
    except (subprocess.CalledProcessError, ValueError):
        pass
    
    # Check for lowntfs-3g (preferred FUSE driver)
    try:
        result = subprocess.run(
            ["which", "lowntfs-3g"],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            return "lowntfs-3g"
    except subprocess.CalledProcessError:
        pass
    
    # Check for ntfs-3g (fallback FUSE driver)
    try:
        result = subprocess.run(
            ["which", "ntfs-3g"],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            return "ntfs-3g"
    except subprocess.CalledProcessError:
        pass
    
    return "unknown"
```

**Implementation Notes:**
- Run once at initialization, cache result
- Provide method to force re-detection
- Log detection result for debugging

### 3.2 Mount Options Configuration

**New Method: `_get_ntfs_mount_options(driver: str)`**

```python
def _get_ntfs_mount_options(self, driver: str) -> str:
    """
    Get recommended mount options for NTFS based on driver
    
    Args:
        driver: NTFS driver name ('ntfs3', 'lowntfs-3g', 'ntfs-3g')
    
    Returns:
        str: Comma-separated mount options
    """
    if driver == "ntfs3":
        # Kernel driver - optimized for performance and compatibility
        return "nofail,users,prealloc,windows_names,nocase"
    
    elif driver in ["lowntfs-3g", "ntfs-3g"]:
        # FUSE drivers - prioritize safety
        return "nofail,noexec,windows_names"
    
    else:
        # Unknown driver - minimal safe options
        return "nofail"
```

**Configuration File Support:**

Create `~/.config/ntfs-manager/mount-options.conf`:
```ini
[ntfs3]
options = nofail,users,prealloc,windows_names,nocase

[ntfs-3g]
options = nofail,noexec,windows_names

[lowntfs-3g]
options = nofail,noexec,windows_names

[fallback]
options = nofail
```

**Config Loading Method:**
```python
def _load_mount_options_config(self) -> Dict[str, str]:
    """Load mount options from config file or use defaults"""
    config_path = Path.home() / ".config/ntfs-manager/mount-options.conf"
    
    if config_path.exists():
        # Parse INI file
        config = configparser.ConfigParser()
        config.read(config_path)
        return {section: config[section].get('options', '') 
                for section in config.sections()}
    
    # Return defaults if no config
    return {
        'ntfs3': 'nofail,users,prealloc,windows_names,nocase',
        'lowntfs-3g': 'nofail,noexec,windows_names',
        'ntfs-3g': 'nofail,noexec,windows_names',
        'fallback': 'nofail'
    }
```

### 3.3 Enhanced Mount Method with Fallback

**Updated: `mount_drive()` method**

```python
def mount_drive(self, drive_name: str, mount_point: str = None, options: str = "") -> bool:
    """
    Mount a drive with intelligent driver detection and fallback
    
    Args:
        drive_name: Device name (e.g., 'sda1')
        mount_point: Optional custom mount point
        options: Optional custom mount options (overrides defaults)
    
    Returns:
        bool: True if mounted successfully
    """
    device_path = f"/dev/{drive_name}"
    fstype = self._get_filesystem_type(device_path)
    
    # For NTFS, use enhanced mounting with driver detection and fallback
    if fstype == "ntfs":
        return self._mount_ntfs_with_fallback(drive_name, mount_point, options)
    
    # For other filesystems, use standard mounting
    try:
        mount_cmd = ["udisksctl", "mount", "-b", device_path]
        if options:
            mount_cmd.extend(["-o", options])
        
        result = subprocess.run(mount_cmd, capture_output=True, text=True, check=True)
        
        # Update internal state
        if "Mounted" in result.stdout:
            parts = result.stdout.split(" at ")
            if len(parts) > 1:
                actual_mount_point = parts[1].strip().rstrip('.')
                if drive_name in self.drives:
                    self.drives[drive_name].mountpoint = actual_mount_point
                    self.notify_callbacks("mounted", self.drives[drive_name])
        
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"Error mounting {drive_name}: {e}")
        return False

def _mount_ntfs_with_fallback(self, drive_name: str, mount_point: str = None, 
                                options: str = "") -> bool:
    """
    Mount NTFS with driver detection, optimized options, and fallback
    
    Strategy:
    1. Detect available NTFS drivers
    2. Try primary driver with recommended options
    3. If dirty volume error, provide troubleshooting
    4. Try fallback drivers if mount fails
    5. Try read-only as last resort
    """
    device_path = f"/dev/{drive_name}"
    
    # Step 1: Detect available drivers
    if not hasattr(self, '_ntfs_driver'):
        self._ntfs_driver = self._detect_ntfs_driver()
    
    driver = self._ntfs_driver
    
    # Step 2: Get mount options (custom or defaults)
    if not options:
        if not hasattr(self, '_mount_options_config'):
            self._mount_options_config = self._load_mount_options_config()
        options = self._mount_options_config.get(driver, 'nofail')
    
    # Step 3: Try primary driver
    print(f"Attempting NTFS mount with driver: {driver}, options: {options}")
    
    mount_cmd = ["udisksctl", "mount", "-b", device_path, "-o", options]
    result = subprocess.run(mount_cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        # Success!
        if "Mounted" in result.stdout:
            parts = result.stdout.split(" at ")
            if len(parts) > 1:
                actual_mount_point = parts[1].strip().rstrip('.')
                if drive_name in self.drives:
                    self.drives[drive_name].mountpoint = actual_mount_point
                    self.notify_callbacks("mounted", self.drives[drive_name])
        return True
    
    # Step 4: Check for dirty volume
    error_output = result.stderr.lower()
    if "dirty" in error_output or "inconsistent" in error_output:
        print(f"NTFS volume {drive_name} is dirty - needs repair")
        # Set flag for GUI to show troubleshooting wizard
        if drive_name in self.drives:
            self.drives[drive_name].health_status = "Dirty"
            self.notify_callbacks("dirty_volume", self.drives[drive_name])
        return False
    
    # Step 5: Try fallback drivers
    fallback_drivers = []
    if driver == "ntfs3":
        fallback_drivers = ["lowntfs-3g", "ntfs-3g"]
    elif driver == "lowntfs-3g":
        fallback_drivers = ["ntfs-3g", "ntfs3"]
    elif driver == "ntfs-3g":
        fallback_drivers = ["lowntfs-3g", "ntfs3"]
    
    for fallback_driver in fallback_drivers:
        # Check if fallback is available
        if fallback_driver == "ntfs3":
            check_cmd = ["modprobe", "-l", "ntfs3"]
        else:
            check_cmd = ["which", fallback_driver]
        
        if subprocess.run(check_cmd, capture_output=True).returncode != 0:
            continue  # Skip unavailable driver
        
        print(f"Trying fallback driver: {fallback_driver}")
        fallback_options = self._mount_options_config.get(fallback_driver, 'nofail')
        
        mount_cmd = ["udisksctl", "mount", "-b", device_path, "-o", fallback_options]
        result = subprocess.run(mount_cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"Successfully mounted with fallback driver: {fallback_driver}")
            if "Mounted" in result.stdout:
                parts = result.stdout.split(" at ")
                if len(parts) > 1:
                    actual_mount_point = parts[1].strip().rstrip('.')
                    if drive_name in self.drives:
                        self.drives[drive_name].mountpoint = actual_mount_point
                        self.notify_callbacks("mounted", self.drives[drive_name])
            return True
    
    # Step 6: Last resort - try read-only
    print(f"All drivers failed for {drive_name}, trying read-only mount")
    mount_cmd = ["udisksctl", "mount", "-b", device_path, "-o", "ro,nofail"]
    result = subprocess.run(mount_cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print(f"Mounted {drive_name} in read-only mode")
        if "Mounted" in result.stdout:
            parts = result.stdout.split(" at ")
            if len(parts) > 1:
                actual_mount_point = parts[1].strip().rstrip('.')
                if drive_name in self.drives:
                    self.drives[drive_name].mountpoint = actual_mount_point + " (READ-ONLY)"
                    self.notify_callbacks("mounted_readonly", self.drives[drive_name])
        return True
    
    # Complete failure
    print(f"Failed to mount {drive_name} with any method")
    return False
```

### 3.4 Enhanced Error Messages

**Update error handling to provide specific guidance:**

```python
def _get_mount_error_message(self, error_output: str, drive_name: str) -> str:
    """
    Generate user-friendly error message with troubleshooting steps
    """
    error_lower = error_output.lower()
    
    if "dirty" in error_lower or "inconsistent" in error_lower:
        return f"""
NTFS Volume Dirty Error

The NTFS volume on {drive_name} was not properly unmounted by Windows.

Common causes:
• Windows Fast Startup is enabled (most common)
• Windows was shut down improperly
• System crash while volume was mounted

Recommended solutions:
1. Boot Windows and shut down properly (safest)
2. Disable Windows Fast Startup in Control Panel
3. Use the NTFS Repair Wizard (Tools menu)

Click 'Show Repair Wizard' for step-by-step guidance.
"""
    
    elif "permission" in error_lower or "access denied" in error_lower:
        return f"""
Permission Denied

You don't have permission to mount {drive_name}.

Solutions:
• Run application with proper permissions
• Check PolicyKit configuration
• Verify drive is not locked by another process
"""
    
    elif "busy" in error_lower or "in use" in error_lower:
        return f"""
Device Busy

The drive {drive_name} is currently in use.

Possible causes:
• Drive is already mounted elsewhere
• Another process is accessing the drive
• Drive is being used by system

Try:
• Close applications using the drive
• Unmount if already mounted
• Check for background processes
"""
    
    else:
        return f"""
Mount Failed

Could not mount {drive_name}.

Error details: {error_output}

Try:
• Check drive health in disk utility
• Verify filesystem is not corrupted
• Review system logs for more information
"""
```

## Phase 4: Dirty Volume Troubleshooting Feature

### 4.1 Create NTFS Repair Module

**New file: `ntfs-complete-manager-gui/backend/ntfs_repair.py`**

```python
#!/usr/bin/env python3
"""
NTFS Repair and Troubleshooting Module
Provides safe, guided NTFS repair functionality
"""

import subprocess
import re
from typing import Tuple, List, Dict
from dataclasses import dataclass

@dataclass
class RepairOption:
    """Represents a repair option with risk level"""
    name: str
    description: str
    risk_level: str  # "safe", "moderate", "risky"
    command: List[str]
    requires_windows: bool

class NTFSRepair:
    """NTFS repair and troubleshooting functionality"""
    
    def check_dirty_status(self, device_path: str) -> Tuple[bool, str]:
        """
        Check if NTFS volume is dirty
        
        Returns:
            (is_dirty, details_message)
        """
        try:
            result = subprocess.run(
                ["ntfsfix", "-n", device_path],
                capture_output=True, text=True
            )
            
            output = result.stdout + result.stderr
            
            if "marked to be fixed" in output or "dirty" in output.lower():
                return (True, "Volume is marked dirty and needs repair")
            elif "clean" in output.lower():
                return (False, "Volume appears clean")
            else:
                return (False, "Cannot determine volume status")
                
        except FileNotFoundError:
            return (False, "ntfsfix not available")
        except Exception as e:
            return (False, f"Error checking status: {e}")
    
    def get_repair_options(self, device_name: str) -> List[RepairOption]:
        """
        Get available repair options ranked by safety
        """
        options = [
            RepairOption(
                name="Boot Windows and Shutdown Properly",
                description="The safest method. Boot Windows, run CHKDSK if needed, "
                           "then shutdown (not restart) properly.",
                risk_level="safe",
                command=[],
                requires_windows=True
            ),
            RepairOption(
                name="Disable Windows Fast Startup",
                description="Prevents future dirty volume issues. Requires booting Windows: "
                           "Control Panel → Power Options → Choose what power buttons do → "
                           "Uncheck 'Turn on fast startup'",
                risk_level="safe",
                command=[],
                requires_windows=True
            ),
            RepairOption(
                name="Use ntfsfix (Linux)",
                description="Linux-based repair. Safer than forced mount but not as "
                           "thorough as Windows CHKDSK. May not fix all issues.",
                risk_level="moderate",
                command=["pkexec", "ntfsfix", "-d", f"/dev/{device_name}"],
                requires_windows=False
            ),
            RepairOption(
                name="Mount Read-Only",
                description="Access files without modifications. Safe for data recovery "
                           "while planning proper repair.",
                risk_level="safe",
                command=["udisksctl", "mount", "-b", f"/dev/{device_name}", "-o", "ro"],
                requires_windows=False
            )
        ]
        
        return options
    
    def apply_repair(self, option: RepairOption, device_name: str) -> Tuple[bool, str]:
        """
        Apply selected repair option
        
        Returns:
            (success, message)
        """
        if option.requires_windows:
            return (False, "This option requires booting into Windows. "
                          "Follow the instructions in the description.")
        
        try:
            result = subprocess.run(
                option.command,
                capture_output=True, text=True, check=True
            )
            
            return (True, f"Repair completed successfully:\n{result.stdout}")
            
        except subprocess.CalledProcessError as e:
            return (False, f"Repair failed:\n{e.stderr}")
        except Exception as e:
            return (False, f"Error during repair: {e}")
    
    def get_fast_startup_instructions(self) -> str:
        """Get detailed instructions for disabling Fast Startup"""
        return """
How to Disable Windows Fast Startup (Dual-Boot Users)

Why disable? Fast Startup causes Windows to hibernate instead of properly
shutting down, leaving NTFS volumes in an unsafe state for Linux.

Steps:
1. Boot into Windows
2. Open Control Panel
3. Go to: Power Options
4. Click: "Choose what the power buttons do" (left sidebar)
5. Click: "Change settings that are currently unavailable" (top)
6. Scroll down to "Shutdown settings"
7. Uncheck: "Turn on fast startup (recommended)"
8. Click: "Save changes"
9. Restart computer (or shutdown and boot to Linux)

Note: You may need administrator privileges.
After disabling, Windows shutdowns will take slightly longer but your
NTFS volumes will be safe for dual-boot use.
"""
```

### 4.2 Troubleshooting Wizard GUI

**Add to main.py:**

```python
class NTFSRepairWizard(Gtk.Dialog):
    """Dialog for guided NTFS repair process"""
    
    def __init__(self, parent, drive_name, drive_info):
        super().__init__(
            title="NTFS Repair Wizard",
            parent=parent,
            flags=0
        )
        
        self.drive_name = drive_name
        self.drive_info = drive_info
        self.repair = NTFSRepair()
        
        self.set_default_size(600, 500)
        self.set_border_width(10)
        
        # Content area
        content = self.get_content_area()
        content.set_spacing(10)
        
        # Title
        title_label = Gtk.Label()
        title_label.set_markup(f"<b>Repair NTFS Volume: {drive_name}</b>")
        content.pack_start(title_label, False, False, 0)
        
        # Status check
        is_dirty, status_msg = self.repair.check_dirty_status(f"/dev/{drive_name}")
        
        status_label = Gtk.Label(label=status_msg)
        status_label.set_line_wrap(True)
        content.pack_start(status_label, False, False, 0)
        
        # Separator
        content.pack_start(Gtk.Separator(), False, False, 5)
        
        # Repair options
        options_label = Gtk.Label()
        options_label.set_markup("<b>Repair Options (Ranked by Safety):</b>")
        options_label.set_halign(Gtk.Align.START)
        content.pack_start(options_label, False, False, 0)
        
        # Get repair options
        repair_options = self.repair.get_repair_options(drive_name)
        
        # Create radio buttons for options
        self.option_buttons = []
        last_button = None
        
        for option in repair_options:
            # Option box
            option_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
            option_box.set_margin_left(20)
            
            # Radio button
            if last_button:
                radio = Gtk.RadioButton.new_from_widget(last_button)
            else:
                radio = Gtk.RadioButton()
            
            radio.set_label(f"{option.name} [{option.risk_level.upper()}]")
            radio.option = option
            self.option_buttons.append(radio)
            last_button = radio
            
            option_box.pack_start(radio, False, False, 0)
            
            # Description
            desc_label = Gtk.Label(label=option.description)
            desc_label.set_line_wrap(True)
            desc_label.set_halign(Gtk.Align.START)
            desc_label.set_margin_left(25)
            option_box.pack_start(desc_label, False, False, 0)
            
            content.pack_start(option_box, False, False, 5)
        
        # Separator
        content.pack_start(Gtk.Separator(), False, False, 10)
        
        # Fast Startup info button
        fs_button = Gtk.Button(label="📖 How to Disable Windows Fast Startup")
        fs_button.connect("clicked", self.on_show_fast_startup_info)
        content.pack_start(fs_button, False, False, 0)
        
        # Action buttons
        self.add_button("Cancel", Gtk.ResponseType.CANCEL)
        self.add_button("Apply Selected Repair", Gtk.ResponseType.OK)
        
        self.show_all()
    
    def on_show_fast_startup_info(self, button):
        """Show Fast Startup instructions"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text="Disable Windows Fast Startup"
        )
        dialog.format_secondary_text(self.repair.get_fast_startup_instructions())
        dialog.run()
        dialog.destroy()
    
    def get_selected_option(self) -> RepairOption:
        """Get the selected repair option"""
        for button in self.option_buttons:
            if button.get_active():
                return button.option
        return None
```

**Integration in main window:**

```python
# Add to drive context menu or toolbar
def on_repair_ntfs(self, widget, drive_name):
    """Open NTFS repair wizard"""
    drive_info = self.drive_manager.drives.get(drive_name)
    
    if not drive_info or drive_info.fstype != "ntfs":
        self.show_error("Can only repair NTFS volumes")
        return
    
    wizard = NTFSRepairWizard(self.window, drive_name, drive_info)
    response = wizard.run()
    
    if response == Gtk.ResponseType.OK:
        selected_option = wizard.get_selected_option()
        if selected_option:
            success, message = self.repair.apply_repair(selected_option, drive_name)
            wizard.destroy()
            
            if success:
                self.show_info(message)
                self.refresh_drives()
            else:
                self.show_error(message)
    else:
        wizard.destroy()
```

## Phase 5: Testing Strategy

### 5.1 Test Scenarios

**Driver Detection Tests:**
- [ ] Kernel 5.15+ with ntfs3 module
- [ ] Kernel < 5.15 without ntfs3
- [ ] System with only ntfs-3g
- [ ] System with lowntfs-3g installed
- [ ] System with no NTFS drivers

**Mount Option Tests:**
- [ ] ntfs3: Verify nofail,users,prealloc,windows_names,nocase
- [ ] ntfs-3g: Verify nofail,noexec,windows_names
- [ ] lowntfs-3g: Verify nofail,noexec,windows_names
- [ ] Custom options from config file

**Fallback Tests:**
- [ ] Primary driver fails → fallback succeeds
- [ ] All drivers fail → read-only mount
- [ ] Dirty volume → wizard appears

**Dirty Volume Tests:**
- [ ] Create dirty volume (improper Windows shutdown)
- [ ] Detect dirty status correctly
- [ ] Show repair wizard
- [ ] Apply ntfsfix successfully
- [ ] Mount read-only when repair declined

**Edge Cases:**
- [ ] Non-NTFS drives unchanged behavior
- [ ] Already mounted drives
- [ ] Permission errors
- [ ] Missing helper utilities

### 5.2 Test Execution Plan

1. **Unit Tests** (if time permits)
   - Mock subprocess calls
   - Test driver detection logic
   - Test option parsing

2. **Integration Tests**
   - Real NTFS drives (USB stick recommended)
   - Different driver scenarios
   - Actual mount/unmount operations

3. **User Acceptance Testing**
   - Follow wizard workflows
   - Verify error messages are helpful
   - Test documentation accuracy

## Implementation Timeline

**Estimated effort: 6-8 hours**

1. **Phase 2 - Documentation** (1-2 hours)
   - Create NTFS mounting guide
   - Update troubleshooting guide
   - Update README

2. **Phase 3 - Code Implementation** (3-4 hours)
   - Driver detection
   - Mount options configuration
   - Enhance
