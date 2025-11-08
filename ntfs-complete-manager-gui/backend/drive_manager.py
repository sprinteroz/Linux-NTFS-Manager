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
import threading
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
        """Get list of all detected drives and partitions"""
        drives = []
        
        try:
            # Get block devices using lsblk
            result = subprocess.run(
                ["lsblk", "-J", "-o", "NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL,MODEL,SERIAL,UUID,RM,ROTA"],
                capture_output=True, text=True, check=True
            )
            
            data = json.loads(result.stdout)
            
            for device in data.get("blockdevices", []):
                # Add parent device
                drive_info = self._parse_device_info(device)
                if drive_info:
                    drives.append(drive_info)
                    self.drives[drive_info.name] = drive_info
                
                # Add child devices (partitions)
                for partition in device.get("children", []):
                    partition_info = self._parse_device_info(partition)
                    if partition_info:
                        drives.append(partition_info)
                        self.drives[partition_info.name] = partition_info
                    
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
                
            # Skip only loop devices and device mapper (but show everything else including swap)
            if name.startswith("loop") or name.startswith("dm-"):
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
            
            # Use enhanced hardware info if basic lsblk didn't provide it
            if not model and not serial:
                hw_model, hw_vendor, hw_serial = self._get_hardware_info(name)
                model = hw_model
                vendor = hw_vendor
                serial = hw_serial
            else:
                vendor = self._get_hardware_info(name)[1]  # Get vendor even if we have model
            
            # Get enhanced label if lsblk didn't provide one
            if not label:
                label = self._get_volume_label(full_path, fstype, label)
            
            # Check device type for appropriate status checks
            device_type = self._get_device_type(name)
            
            # Get health and SMART status (with device type awareness)
            if device_type in ["ram", "loop"]:
                health_status = "N/A (virtual device)"
                smart_status = "N/A (virtual device)"
                temperature = 0.0
            else:
                health_status = self._get_health_status(full_path)
                temperature = self._get_temperature(full_path)
                smart_status = self._get_smart_status(full_path)
            
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
                smart_status=smart_status
            )
            
        except Exception as e:
            print(f"Error parsing device info: {e}")
            return None
    
    def _get_device_type(self, device_name: str) -> str:
        """Determine device type (disk, partition, special)"""
        if device_name.startswith("zram") or device_name.startswith("ram"):
            return "ram"
        elif device_name.startswith("loop"):
            return "loop"
        elif device_name.startswith("sr") or device_name.startswith("cdrom"):
            return "optical"
        elif device_name.startswith("nvme") and "p" in device_name:
            return "nvme_partition"
        elif device_name.startswith("nvme"):
            return "nvme_disk"
        elif re.match(r'^sd[a-z]\d+$', device_name):
            return "partition"
        elif re.match(r'^sd[a-z]$', device_name):
            return "disk"
        else:
            return "unknown"
    
    def _get_parent_device(self, device_name: str) -> str:
        """Get parent device name from partition name"""
        # sda1 -> sda, nvme0n1p1 -> nvme0n1
        if device_name.startswith("nvme") and "p" in device_name:
            return device_name.rsplit("p", 1)[0]
        else:
            # Remove trailing digits
            return re.sub(r'\d+$', '', device_name)
    
    def _get_hardware_info(self, device_name: str) -> Tuple[str, str, str]:
        """Get model, vendor, and serial from hardware
        Returns: (model, vendor, serial)
        """
        device_type = self._get_device_type(device_name)
        
        # Special devices don't have hardware info
        if device_type in ["ram", "loop", "optical"]:
            return ("N/A", "N/A", "N/A")
        
        # For partitions, get info from parent device
        if "partition" in device_type:
            device_name = self._get_parent_device(device_name)
        
        model = ""
        vendor = ""
        serial = ""
        
        try:
            # Try /sys/block first
            sys_path = f"/sys/block/{device_name}/device"
            
            if os.path.exists(sys_path):
                # Read model
                model_path = f"{sys_path}/model"
                if os.path.exists(model_path):
                    with open(model_path, 'r') as f:
                        model = f.read().strip()
                
                # Read vendor
                vendor_path = f"{sys_path}/vendor"
                if os.path.exists(vendor_path):
                    with open(vendor_path, 'r') as f:
                        vendor = f.read().strip()
                
                # Read serial
                serial_path = f"{sys_path}/serial"
                if os.path.exists(serial_path):
                    with open(serial_path, 'r') as f:
                        serial = f.read().strip()
            
            # For NVMe devices, try different paths
            if device_name.startswith("nvme"):
                nvme_path = f"/sys/block/{device_name}"
                if os.path.exists(nvme_path):
                    model_file = f"{nvme_path}/device/model"
                    if os.path.exists(model_file):
                        with open(model_file, 'r') as f:
                            model = f.read().strip()
                    
                    serial_file = f"{nvme_path}/device/serial"
                    if os.path.exists(serial_file):
                        with open(serial_file, 'r') as f:
                            serial = f.read().strip()
            
            # Fallback to udevadm
            if not model or not vendor:
                device_path = f"/dev/{device_name}"
                result = subprocess.run(
                    ["udevadm", "info", "--query=property", "--name", device_path],
                    capture_output=True, text=True, check=True
                )
                
                for line in result.stdout.splitlines():
                    if not model and line.startswith("ID_MODEL="):
                        model = line.split("=", 1)[1].replace("_", " ")
                    elif not vendor and line.startswith("ID_VENDOR="):
                        vendor = line.split("=", 1)[1]
                    elif not serial and line.startswith("ID_SERIAL_SHORT="):
                        serial = line.split("=", 1)[1]
                        
        except Exception as e:
            print(f"Error getting hardware info for {device_name}: {e}")
        
        return (model or "", vendor or "", serial or "")
    
    def _get_volume_label(self, device_path: str, fstype: str, lsblk_label: str) -> str:
        """Get volume label with multiple fallbacks"""
        # Return lsblk label if available
        if lsblk_label:
            return lsblk_label
        
        # Try blkid for all filesystem types
        try:
            result = subprocess.run(
                ["blkid", "-s", "LABEL", "-o", "value", device_path],
                capture_output=True, text=True, check=True
            )
            label = result.stdout.strip()
            if label:
                return label
        except subprocess.CalledProcessError:
            pass
        
        # NTFS-specific: try ntfslabel
        if fstype == "ntfs":
            try:
                result = subprocess.run(
                    ["ntfslabel", device_path],
                    capture_output=True, text=True, check=True
                )
                label = result.stdout.strip()
                if label:
                    return label
            except (subprocess.CalledProcessError, FileNotFoundError):
                pass
        
        # ext filesystem: try e2label
        if fstype and fstype.startswith("ext"):
            try:
                result = subprocess.run(
                    ["e2label", device_path],
                    capture_output=True, text=True, check=True
                )
                label = result.stdout.strip()
                if label:
                    return label
            except (subprocess.CalledProcessError, FileNotFoundError):
                pass
        
        return ""
    
    def _get_health_status(self, device_path: str) -> str:
        """Get drive health status"""
        try:
            # For NTFS drives, check dirty bit using ntfsfix
            fstype = self._get_filesystem_type(device_path)
            if fstype == "ntfs":
                result = subprocess.run(
                    ["ntfsfix", "-n", device_path],
                    capture_output=True, text=True
                )
                
                if "marked to be fixed" in result.stdout or "dirty" in result.stdout.lower():
                    return "Dirty"
                elif result.returncode == 0:
                    return "Healthy"
                else:
                    return "Error"
                    
        except (subprocess.CalledProcessError, FileNotFoundError):
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
        """Mount a drive using udisksctl for better PolicyKit integration"""
        try:
            device_path = f"/dev/{drive_name}"
            
            # Use udisksctl for mounting (works with PolicyKit)
            mount_cmd = ["udisksctl", "mount", "-b", device_path]
            
            if options:
                mount_cmd.extend(["-o", options])
                
            result = subprocess.run(mount_cmd, capture_output=True, text=True, check=True)
            
            # Parse mount point from udisksctl output
            # Output format: "Mounted /dev/sdX at /media/user/mountpoint"
            if "Mounted" in result.stdout:
                parts = result.stdout.split(" at ")
                if len(parts) > 1:
                    actual_mount_point = parts[1].strip().rstrip('.')
                    
                    # Update drive info
                    if drive_name in self.drives:
                        self.drives[drive_name].mountpoint = actual_mount_point
                        self.notify_callbacks("mounted", self.drives[drive_name])
                
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Error mounting drive {drive_name}: {e}")
            print(f"stderr: {e.stderr if hasattr(e, 'stderr') else 'N/A'}")
            return False
    
    def unmount_drive(self, drive_name: str) -> bool:
        """Unmount a drive using udisksctl for better PolicyKit integration"""
        try:
            device_path = f"/dev/{drive_name}"
            
            # Use udisksctl for unmounting (works with PolicyKit)
            result = subprocess.run(["udisksctl", "unmount", "-b", device_path], 
                                 capture_output=True, text=True, check=True)
            
            # Update drive info
            if drive_name in self.drives:
                self.drives[drive_name].mountpoint = ""
                self.notify_callbacks("unmounted", self.drives[drive_name])
                
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"Error unmounting drive {drive_name}: {e}")
            print(f"stderr: {e.stderr if hasattr(e, 'stderr') else 'N/A'}")
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
                # NTFS repair using ntfsfix
                subprocess.run(["ntfsfix", "-d", device_path], capture_output=True, text=True, check=True)
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
            "smart_status": drive.smart_status
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
        """Start drive monitoring using udev"""
        if self.monitoring:
            return
            
        self.monitoring = True
        
        # Start monitoring thread for udev events
        self.monitor_thread = threading.Thread(target=self._monitor_udev_events, daemon=True)
        self.monitor_thread.start()
        
        print("Drive monitoring started")
    
    def stop_monitoring(self):
        """Stop drive monitoring"""
        self.monitoring = False
        print("Drive monitoring stopped")
    
    def _monitor_udev_events(self):
        """Monitor udev events for drive add/remove"""
        try:
            # Start udevadm monitor for block devices
            process = subprocess.Popen(
                ["udevadm", "monitor", "--subsystem-match=block"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1
            )
            
            while self.monitoring:
                line = process.stdout.readline()
                if not line:
                    break
                    
                # Parse udev event
                if "add" in line.lower() or "remove" in line.lower():
                    # Wait a moment for system to settle
                    time.sleep(0.5)
                    
                    # Get current drives
                    old_drives = set(self.drives.keys())
                    new_drive_list = self.get_all_drives()
                    new_drives = set(self.drives.keys())
                    
                    # Check for new drives
                    for drive_name in new_drives - old_drives:
                        if drive_name in self.drives:
                            self.notify_callbacks("added", self.drives[drive_name])
                    
                    # Check for removed drives
                    for drive_name in old_drives - new_drives:
                        # Create temporary DriveInfo for removed drive
                        removed_drive = DriveInfo(
                            name=drive_name,
                            size="",
                            fstype="",
                            mountpoint="",
                            label=""
                        )
                        self.notify_callbacks("removed", removed_drive)
                        
        except Exception as e:
            print(f"Error in udev monitoring: {e}")
        finally:
            if 'process' in locals():
                process.terminate()
    
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
