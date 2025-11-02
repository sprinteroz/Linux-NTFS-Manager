#!/usr/bin/env python3
"""
Drive Manager Backend Module
Handles drive detection, monitoring, and management operations
"""

import subprocess
import re
import json
import os
import time
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from pathlib import Path

@dataclass
class DriveInfo:
    """Data class for drive information"""
    name: str
    size: str
    fstype: str
    mountpoint: str
    label: str
    model: str = ""
    vendor: str = ""
    serial: str = ""
    uuid: str = ""
    is_removable: bool = False
    is_rotational: bool = False
    health_status: str = "Unknown"
    temperature: float = 0.0
    smart_status: str = "Unknown"
    is_hot_swappable: bool = False
    is_in_use: bool = False
    processes_using: Optional[List[str]] = None

class DriveManager:
    """Main drive management class"""
    
    def __init__(self):
        self.drives = {}
        self.monitoring = False
        self.callbacks = []
        
    def add_callback(self, callback):
        """Add callback for drive events"""
        self.callbacks.append(callback)
        
    def notify_callbacks(self, event_type: str, drive_info: DriveInfo):
        """Notify all registered callbacks"""
        for callback in self.callbacks:
            try:
                callback(event_type, drive_info)
            except Exception as e:
                print(f"Callback error: {e}")
    
    def get_all_drives(self) -> List[DriveInfo]:
        """Get list of all detected drives"""
        drives = []
        
        try:
            # Get block devices using lsblk
            result = subprocess.run(
                ["lsblk", "-J", "-o", "NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL,MODEL,SERIAL,UUID,RM,ROTA"],
                capture_output=True, text=True, check=True
            )
            
            data = json.loads(result.stdout)
            
            for device in data.get("blockdevices", []):
                drive_info = self._parse_device_info(device)
                if drive_info:
                    drives.append(drive_info)
                    self.drives[drive_info.name] = drive_info
                    
        except subprocess.CalledProcessError as e:
            print(f"Error getting drive list: {e}")
        except json.JSONDecodeError as e:
            print(f"Error parsing lsblk output: {e}")
            
        return drives
    
    def _parse_device_info(self, device: dict) -> Optional[DriveInfo]:
        """Parse device information from lsblk JSON output"""
        try:
            name = device.get("name", "")
            if not name:
                return None
                
            # Skip system partitions that shouldn't be managed
            if name.startswith("loop") or name.startswith("ram") or name.startswith("dm-"):
                return None
                
            size = device.get("size", "Unknown")
            fstype = device.get("fstype", "")
            mountpoint = device.get("mountpoint", "")
            label = device.get("label", "")
            model = device.get("model", "")
            serial = device.get("serial", "")
            uuid = device.get("uuid", "")
            is_removable = device.get("rm", "0") == "1"
            is_rotational = device.get("rota", "0") == "1"
            
            # Get additional information
            full_path = f"/dev/{name}"
            vendor = self._get_vendor(full_path)
            health_status = self._get_health_status(full_path)
            temperature = self._get_temperature(full_path)
            smart_status = self._get_smart_status(full_path)
            is_hot_swappable = self._is_hot_swappable(full_path, is_removable)
            is_in_use, processes_using = self._check_drive_usage(full_path)
            
            return DriveInfo(
                name=name,
                size=size,
                fstype=fstype or "Unknown",
                mountpoint=mountpoint or "",
                label=label or "",
                model=model or "",
                vendor=vendor or "",
                serial=serial or "",
                uuid=uuid or "",
                is_removable=is_removable,
                is_rotational=is_rotational,
                health_status=health_status,
                temperature=temperature,
                smart_status=smart_status,
                is_hot_swappable=is_hot_swappable,
                is_in_use=is_in_use,
                processes_using=processes_using
            )
            
        except Exception as e:
            print(f"Error parsing device info: {e}")
            return None
    
    def _get_vendor(self, device_path: str) -> str:
        """Get device vendor information"""
        try:
            # Try to get vendor from udev
            result = subprocess.run(
                ["udevadm", "info", "--query=property", "--name", device_path],
                capture_output=True, text=True, check=True
            )
            
            for line in result.stdout.splitlines():
                if line.startswith("ID_VENDOR="):
                    return line.split("=", 1)[1]
                    
        except subprocess.CalledProcessError:
            pass
            
        return ""
    
    def _get_health_status(self, device_path: str) -> str:
        """Get drive health status"""
        try:
            # For NTFS drives, check dirty bit
            fstype = self._get_filesystem_type(device_path)
            if fstype == "ntfs":
                result = subprocess.run(
                    ["ntfsck", "-n", device_path],
                    capture_output=True, text=True
                )
                
                if "Dirty" in result.stderr:
                    return "Dirty"
                elif result.returncode == 0:
                    return "Healthy"
                else:
                    return "Error"
                    
        except subprocess.CalledProcessError:
            pass
            
        return "Unknown"
    
    def _get_temperature(self, device_path: str) -> float:
        """Get drive temperature if available"""
        try:
            # Try to get temperature from hddtemp or smartctl
            result = subprocess.run(
                ["smartctl", "-A", device_path],
                capture_output=True, text=True, check=True
            )
            
            for line in result.stdout.splitlines():
                if "Temperature" in line and "Celsius" in line:
                    # Extract temperature value
                    match = re.search(r'(\d+)\s*Celsius', line)
                    if match:
                        return float(match.group(1))
                        
        except subprocess.CalledProcessError:
            pass
            
        return 0.0
    
    def _get_smart_status(self, device_path: str) -> str:
        """Get SMART status"""
        try:
            result = subprocess.run(
                ["smartctl", "-H", device_path],
                capture_output=True, text=True, check=True
            )
            
            for line in result.stdout.splitlines():
                if "SMART overall-health self-assessment test result:" in line:
                    if "PASSED" in line:
                        return "PASSED"
                    else:
                        return "FAILED"
                        
        except subprocess.CalledProcessError:
            pass
            
        return "Unknown"
    
    def _get_filesystem_type(self, device_path: str) -> str:
        """Get filesystem type for a device"""
        try:
            result = subprocess.run(
                ["lsblk", "-no", "FSTYPE", device_path],
                capture_output=True, text=True, check=True
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError:
            return ""
    
    def mount_drive(self, drive_name: str, mount_point: str = None, options: str = "") -> bool:
        """Mount a drive"""
        try:
            device_path = f"/dev/{drive_name}"
            
            if not mount_point:
                # Create default mount point
                mount_point = f"/mnt/{drive_name}"
                
            # Create mount point directory
            os.makedirs(mount_point, exist_ok=True)
            
            # Determine filesystem type and mount options
            fstype = self._get_filesystem_type(device_path)
            
            if fstype == "ntfs":
                mount_cmd = ["mount", "-t", "ntfs-3g", device_path, mount_point]
                if options:
                    mount_cmd.extend(["-o", options])
            else:
                mount_cmd = ["mount", device_path, mount_point]
                if options:
                    mount_cmd.extend(["-o", options])
                    
            result = subprocess.run(mount_cmd, capture_output=True, text=True, check=True)
            
            # Update drive info
            if drive_name in self.drives:
                self.drives[drive_name].mountpoint = mount_point
                self.notify_callbacks("mounted", self.drives[drive_name])
                
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Error mounting drive {drive_name}: {e}")
            return False
    
    def unmount_drive(self, drive_name: str) -> bool:
        """Unmount a drive"""
        try:
            device_path = f"/dev/{drive_name}"
            
            result = subprocess.run(["umount", device_path], capture_output=True, text=True, check=True)
            
            # Update drive info
            if drive_name in self.drives:
                self.drives[drive_name].mountpoint = ""
                self.notify_callbacks("unmounted", self.drives[drive_name])
                
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Error unmounting drive {drive_name}: {e}")
            return False
    
    def format_drive(self, drive_name: str, fstype: str, label: str = "") -> bool:
        """Format a drive (DANGEROUS OPERATION)"""
        try:
            device_path = f"/dev/{drive_name}"
            
            # Safety check - make sure device is not mounted
            if self.drives.get(drive_name, DriveInfo("", "", "", "", "")).mountpoint:
                print("Cannot format mounted drive")
                return False
                
            # Format based on filesystem type
            if fstype.lower() == "ntfs":
                cmd = ["mkfs.ntfs", "-f"]
                if label:
                    cmd.extend(["-L", label])
                cmd.append(device_path)
            elif fstype.lower() == "ext4":
                cmd = ["mkfs.ext4", "-F"]
                if label:
                    cmd.extend(["-L", label])
                cmd.append(device_path)
            elif fstype.lower() == "fat32":
                cmd = ["mkfs.vfat", "-F", "32"]
                if label:
                    cmd.extend(["-n", label])
                cmd.append(device_path)
            else:
                print(f"Unsupported filesystem type: {fstype}")
                return False
                
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            
            # Refresh drive information
            self.get_all_drives()
            
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Error formatting drive {drive_name}: {e}")
            return False
    
    def repair_drive(self, drive_name: str) -> bool:
        """Repair a drive using the auto-repair script"""
        try:
            # Call the auto-repair script
            script_path = "/usr/local/bin/drive-auto-repair"
            if not os.path.exists(script_path):
                # Fallback to basic repair
                return self._basic_repair(drive_name)
                
            result = subprocess.run(
                [script_path, "repair", drive_name],
                capture_output=True, text=True, check=True
            )
            
            # Refresh drive information
            self.get_all_drives()
            
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Error repairing drive {drive_name}: {e}")
            return False
    
    def _basic_repair(self, drive_name: str) -> bool:
        """Basic repair functionality"""
        try:
            device_path = f"/dev/{drive_name}"
            fstype = self._get_filesystem_type(device_path)
            
            if fstype == "ntfs":
                # NTFS repair
                subprocess.run(["ntfsfix", "-d", device_path], capture_output=True, text=True, check=True)
                subprocess.run(["ntfsck", "-a", device_path], capture_output=True, text=True, check=True)
            elif fstype.startswith("ext"):
                # EXT filesystem repair
                subprocess.run(["e2fsck", "-y", device_path], capture_output=True, text=True, check=True)
            else:
                print(f"No basic repair available for filesystem: {fstype}")
                return False
                
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Error in basic repair: {e}")
            return False
    
    def get_drive_properties(self, drive_name: str) -> Dict:
        """Get detailed properties for a drive"""
        if drive_name not in self.drives:
            return {}
            
        drive = self.drives[drive_name]
        device_path = f"/dev/{drive_name}"
        
        properties = {
            "name": drive.name,
            "size": drive.size,
            "fstype": drive.fstype,
            "mountpoint": drive.mountpoint,
            "label": drive.label,
            "model": drive.model,
            "vendor": drive.vendor,
            "serial": drive.serial,
            "uuid": drive.uuid,
            "is_removable": drive.is_removable,
            "is_rotational": drive.is_rotational,
            "health_status": drive.health_status,
            "temperature": drive.temperature,
            "smart_status": drive.smart_status,
            "is_hot_swappable": drive.is_hot_swappable,
            "is_in_use": drive.is_in_use,
            "processes_using": drive.processes_using
        }
        
        # Add filesystem-specific properties
        try:
            if drive.fstype == "ntfs":
                # Get NTFS-specific information
                result = subprocess.run(
                    ["ntfsinfo", device_path],
                    capture_output=True, text=True, check=True
                )
                
                # Parse NTFS info
                for line in result.stdout.splitlines():
                    if "Volume Name" in line:
                        properties["ntfs_volume_name"] = line.split(":", 1)[1].strip()
                    elif "Volume Serial Number" in line:
                        properties["ntfs_serial"] = line.split(":", 1)[1].strip()
                    elif "Cluster Size" in line:
                        properties["ntfs_cluster_size"] = line.split(":", 1)[1].strip()
                        
        except subprocess.CalledProcessError:
            pass
            
        return properties
    
    def start_monitoring(self):
        """Start drive monitoring"""
        if self.monitoring:
            return
            
        self.monitoring = True
        
        # This would typically run in a separate thread
        # For now, we'll just mark it as started
        print("Drive monitoring started")
    
    def stop_monitoring(self):
        """Stop drive monitoring"""
        self.monitoring = False
        print("Drive monitoring stopped")
    
    def refresh_drives(self) -> List[DriveInfo]:
        """Refresh the drive list"""
        old_drives = set(self.drives.keys())
        new_drives = self.get_all_drives()
        new_drive_names = set(drive.name for drive in new_drives)
        
        # Check for new drives
        for drive_name in new_drive_names - old_drives:
            if drive_name in self.drives:
                self.notify_callbacks("added", self.drives[drive_name])
                
        # Check for removed drives
        for drive_name in old_drives - new_drive_names:
            if drive_name in self.drives:
                self.notify_callbacks("removed", self.drives[drive_name])
                del self.drives[drive_name]
                
        return new_drives
    
    def _is_hot_swappable(self, device_path: str, is_removable: bool) -> bool:
        """Check if device is hot-swappable"""
        try:
            # USB and external drives are typically hot-swappable
            if is_removable:
                return True
                
            # Check if device is connected via USB/Thunderbolt/etc.
            result = subprocess.run(
                ["udevadm", "info", "--query=property", "--name", device_path],
                capture_output=True, text=True, check=True
            )
            
            for line in result.stdout.splitlines():
                if "ID_BUS=" in line:
                    bus = line.split("=", 1)[1].strip()
                    if bus in ["usb", "thunderbolt", "firewire", "ieee1394"]:
                        return True
                        
            # Check sysfs for hotplug capabilities
            sysfs_path = f"/sys/block/{os.path.basename(device_path)}"
            if os.path.exists(f"{sysfs_path}/removable"):
                with open(f"{sysfs_path}/removable", "r") as f:
                    if f.read().strip() == "1":
                        return True
                        
        except subprocess.CalledProcessError:
            pass
            
        return False
    
    def _check_drive_usage(self, device_path: str) -> Tuple[bool, List[str]]:
        """Check if drive is currently in use and by which processes"""
        try:
            processes_using = []
            
            # Check if device is mounted
            mount_result = subprocess.run(
                ["findmnt", "-n", "-o", "SOURCE", device_path],
                capture_output=True, text=True, check=True
            )
            
            if mount_result.returncode == 0:
                # Device is mounted, find processes using it
                device_name = os.path.basename(device_path)
                
                # Check lsof for processes using the device
                lsof_result = subprocess.run(
                    ["lsof", "+D", device_path],
                    capture_output=True, text=True, check=True
                )
                
                if lsof_result.returncode == 0:
                    for line in lsof_result.stdout.splitlines():
                        if line.strip() and not line.startswith("COMMAND"):
                            parts = line.split()
                            if len(parts) >= 2:
                                process_name = parts[0]
                                processes_using.append(process_name)
                                
                return True, processes_using
            else:
                return False, []
                
        except subprocess.CalledProcessError:
            return False, []
    
    def safe_eject_drive(self, drive_name: str) -> bool:
        """Safely eject a hot-swappable drive"""
        try:
            device_path = f"/dev/{drive_name}"
            
            # Check if drive is in use
            is_in_use, processes_using = self._check_drive_usage(device_path)
            
            if is_in_use:
                print(f"Cannot eject {drive_name}: drive is in use by processes: {', '.join(processes_using)}")
                return False
                
            # Unmount if mounted
            if drive_name in self.drives and self.drives[drive_name].mountpoint:
                if not self.unmount_drive(drive_name):
                    print(f"Failed to unmount {drive_name}")
                    return False
                    
            # Try to eject the device
            result = subprocess.run(
                ["udisksctl", "power-off", "-b", device_path],
                capture_output=True, text=True, check=True
            )
            
            if result.returncode == 0:
                print(f"Successfully ejected {drive_name}")
                return True
            else:
                print(f"Failed to eject {drive_name}: {result.stderr}")
                return False
                
        except subprocess.CalledProcessError as e:
            print(f"Error ejecting {drive_name}: {e}")
            return False
