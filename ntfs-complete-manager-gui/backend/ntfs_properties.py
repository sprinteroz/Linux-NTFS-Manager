#!/usr/bin/env python3
"""
NTFS Properties Module
Provides Windows-style NTFS drive properties and information
"""

import subprocess
import re
import os
import json
import datetime
from typing import Dict, Any, Optional, List
from pathlib import Path
from dataclasses import dataclass

@dataclass
class NTFSVolumeInfo:
    """NTFS volume information structure"""
    volume_name: str = ""
    volume_serial: str = ""
    filesystem_type: str = "NTFS"
    cluster_size: int = 0
    total_clusters: int = 0
    free_clusters: int = 0
    used_clusters: int = 0
    total_size: int = 0
    used_space: int = 0
    free_space: int = 0
    compression: bool = False
    encryption: bool = False
    quota_enabled: bool = False
    creation_time: str = ""
    last_write_time: str = ""
    last_access_time: str = ""

@dataclass
class NTFSSecurityInfo:
    """NTFS security information"""
    owner: str = ""
    group: str = ""
    permissions: str = ""
    acl_entries: List[Dict] = None
    encryption_status: str = "Unknown"
    
    def __post_init__(self):
        if self.acl_entries is None:
            self.acl_entries = []

@dataclass
class NTFSHealthInfo:
    """NTFS health and integrity information"""
    dirty_bit: bool = False
    needs_check: bool = False
    volume_errors: List[str] = None
    smart_status: str = "Unknown"
    bad_sectors: int = 0
    reallocated_sectors: int = 0
    pending_sectors: int = 0
    power_on_hours: int = 0
    
    def __post_init__(self):
        if self.volume_errors is None:
            self.volume_errors = []

class NTFSProperties:
    """Main NTFS properties class"""
    
    def __init__(self, device_path: str):
        self.device_path = device_path
        self.device_name = Path(device_path).name
        self.volume_info = NTFSVolumeInfo()
        self.security_info = NTFSSecurityInfo()
        self.health_info = NTFSHealthInfo()
        
    def get_all_properties(self) -> Dict[str, Any]:
        """Get comprehensive NTFS properties"""
        properties = {}
        
        # Volume information
        self._get_volume_info()
        properties["volume"] = {
            "name": self.volume_info.volume_name,
            "serial": self.volume_info.volume_serial,
            "filesystem": self.volume_info.filesystem_type,
            "cluster_size": self.volume_info.cluster_size,
            "total_clusters": self.volume_info.total_clusters,
            "free_clusters": self.volume_info.free_clusters,
            "used_clusters": self.volume_info.used_clusters,
            "total_size": self._format_bytes(self.volume_info.total_size),
            "used_space": self._format_bytes(self.volume_info.used_space),
            "free_space": self._format_bytes(self.volume_info.free_space),
            "usage_percentage": round((self.volume_info.used_space / self.volume_info.total_size * 100), 2) if self.volume_info.total_size > 0 else 0,
            "compression": self.volume_info.compression,
            "encryption": self.volume_info.encryption,
            "quota_enabled": self.volume_info.quota_enabled,
            "creation_time": self.volume_info.creation_time,
            "last_write_time": self.volume_info.last_write_time,
            "last_access_time": self.volume_info.last_access_time
        }
        
        # Security information
        self._get_security_info()
        properties["security"] = {
            "owner": self.security_info.owner,
            "group": self.security_info.group,
            "permissions": self.security_info.permissions,
            "acl_entries": self.security_info.acl_entries,
            "encryption_status": self.security_info.encryption_status
        }
        
        # Health information
        self._get_health_info()
        properties["health"] = {
            "dirty_bit": self.health_info.dirty_bit,
            "needs_check": self.health_info.needs_check,
            "volume_errors": self.health_info.volume_errors,
            "smart_status": self.health_info.smart_status,
            "bad_sectors": self.health_info.bad_sectors,
            "reallocated_sectors": self.health_info.reallocated_sectors,
            "pending_sectors": self.health_info.pending_sectors,
            "power_on_hours": self.health_info.power_on_hours
        }
        
        # Device information
        properties["device"] = self._get_device_info()
        
        # Performance metrics
        properties["performance"] = self._get_performance_metrics()
        
        return properties
    
    def _get_volume_info(self):
        """Get NTFS volume information"""
        try:
            # Use ntfsinfo for detailed NTFS information
            result = subprocess.run(
                ["ntfsinfo", self.device_path],
                capture_output=True, text=True, check=True
            )
            
            for line in result.stdout.splitlines():
                line = line.strip()
                
                if "Volume Name" in line:
                    self.volume_info.volume_name = line.split(":", 1)[1].strip()
                elif "Volume Serial Number" in line:
                    self.volume_info.volume_serial = line.split(":", 1)[1].strip()
                elif "Cluster Size" in line:
                    cluster_str = line.split(":", 1)[1].strip()
                    self.volume_info.cluster_size = self._parse_size(cluster_str)
                elif "Volume Size" in line:
                    size_str = line.split(":", 1)[1].strip()
                    self.volume_info.total_size = self._parse_size(size_str)
                elif "Free Space" in line:
                    free_str = line.split(":", 1)[1].strip()
                    self.volume_info.free_space = self._parse_size(free_str)
                    
        except subprocess.CalledProcessError:
            # Fallback to df for basic information
            self._get_basic_volume_info()
        
        # Calculate derived values
        if self.volume_info.total_size > 0:
            self.volume_info.used_space = self.volume_info.total_size - self.volume_info.free_space
        
        # Get mount point for additional information
        mount_point = self._get_mount_point()
        if mount_point:
            self._get_mount_point_info(mount_point)
    
    def _get_basic_volume_info(self):
        """Get basic volume information using df"""
        try:
            result = subprocess.run(
                ["df", "-B", "1", self.device_path],
                capture_output=True, text=True, check=True
            )
            
            lines = result.stdout.strip().split('\n')
            if len(lines) >= 2:
                parts = lines[1].split()
                if len(parts) >= 4:
                    self.volume_info.total_size = int(parts[1])
                    self.volume_info.used_space = int(parts[2])
                    self.volume_info.free_space = int(parts[3])
                    
        except subprocess.CalledProcessError:
            pass
    
    def _get_mount_point(self) -> str:
        """Get mount point for the device"""
        try:
            result = subprocess.run(
                ["findmnt", "-n", "-o", "TARGET", "-S", self.device_path],
                capture_output=True, text=True, check=True
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError:
            return ""
    
    def _get_mount_point_info(self, mount_point: str):
        """Get information from mount point"""
        try:
            # Get filesystem statistics
            stat = os.statvfs(mount_point)
            if stat:
                self.volume_info.cluster_size = stat.f_frsize
                self.volume_info.total_clusters = stat.f_blocks
                self.volume_info.free_clusters = stat.f_bavail
                self.volume_info.used_clusters = stat.f_blocks - stat.f_bavail
                
        except OSError:
            pass
        
        # Get timestamps
        try:
            stat_info = os.stat(mount_point)
            self.volume_info.creation_time = datetime.datetime.fromtimestamp(stat_info.st_ctime).isoformat()
            self.volume_info.last_write_time = datetime.datetime.fromtimestamp(stat_info.st_mtime).isoformat()
            self.volume_info.last_access_time = datetime.datetime.fromtimestamp(stat_info.st_atime).isoformat()
        except OSError:
            pass
    
    def _get_security_info(self):
        """Get NTFS security information"""
        try:
            # Get ownership information
            result = subprocess.run(
                ["stat", "-c", "%U:%G:%a", self.device_path],
                capture_output=True, text=True, check=True
            )
            
            parts = result.stdout.strip().split(":")
            if len(parts) >= 3:
                self.security_info.owner = parts[0]
                self.security_info.group = parts[1]
                self.security_info.permissions = parts[2]
                
        except subprocess.CalledProcessError:
            pass
        
        # Get ACL information if available
        try:
            result = subprocess.run(
                ["getfacl", self.device_path],
                capture_output=True, text=True, check=True
            )
            
            self._parse_acl_output(result.stdout)
            
        except subprocess.CalledProcessError:
            pass
        
        # Check encryption status
        self._check_encryption_status()
    
    def _parse_acl_output(self, acl_output: str):
        """Parse ACL output"""
        self.security_info.acl_entries = []
        
        for line in acl_output.splitlines():
            line = line.strip()
            if line.startswith("user:") or line.startswith("group:") or line.startswith("other:"):
                parts = line.split(":")
                if len(parts) >= 3:
                    entry = {
                        "type": parts[0],
                        "entity": parts[1] if parts[1] else "default",
                        "permissions": parts[2]
                    }
                    self.security_info.acl_entries.append(entry)
    
    def _check_encryption_status(self):
        """Check if volume is encrypted"""
        try:
            # Check for BitLocker or other encryption
            result = subprocess.run(
                ["lsblk", "-o", "FSTYPE", "-n", self.device_path],
                capture_output=True, text=True, check=True
            )
            
            fstype = result.stdout.strip()
            if "crypto" in fstype.lower() or "bitlocker" in fstype.lower():
                self.security_info.encryption_status = "Encrypted"
            else:
                self.security_info.encryption_status = "Not Encrypted"
                
        except subprocess.CalledProcessError:
            self.security_info.encryption_status = "Unknown"
    
    def _get_health_info(self):
        """Get NTFS health information"""
        try:
            # Check dirty bit and filesystem health
            result = subprocess.run(
                ["ntfsck", "-n", self.device_path],
                capture_output=True, text=True
            )
            
            if "Dirty" in result.stderr:
                self.health_info.dirty_bit = True
                self.health_info.needs_check = True
            
            if result.returncode != 0:
                self.health_info.volume_errors.append("Filesystem check failed")
                
        except subprocess.CalledProcessError:
            pass
        
        # Get SMART data
        self._get_smart_data()
    
    def _get_smart_data(self):
        """Get SMART health data"""
        try:
            result = subprocess.run(
                ["smartctl", "-A", "-H", self.device_path],
                capture_output=True, text=True, check=True
            )
            
            # Parse SMART status
            for line in result.stdout.splitlines():
                line = line.strip()
                
                if "SMART overall-health self-assessment test result:" in line:
                    if "PASSED" in line:
                        self.health_info.smart_status = "PASSED"
                    else:
                        self.health_info.smart_status = "FAILED"
                
                # Parse specific SMART attributes
                if "Reallocated_Sector_Ct" in line:
                    self.health_info.reallocated_sectors = self._extract_smart_value(line)
                elif "Pending_Sector_Ct" in line:
                    self.health_info.pending_sectors = self._extract_smart_value(line)
                elif "Power_On_Hours" in line:
                    self.health_info.power_on_hours = self._extract_smart_value(line)
                elif "Reallocated_Event_Count" in line:
                    self.health_info.bad_sectors = self._extract_smart_value(line)
                    
        except subprocess.CalledProcessError:
            self.health_info.smart_status = "Unknown"
    
    def _extract_smart_value(self, line: str) -> int:
        """Extract numeric value from SMART attribute line"""
        try:
            parts = line.split()
            if len(parts) >= 10:
                return int(parts[9])  # RAW_VALUE is typically the 10th column
        except (ValueError, IndexError):
            pass
        return 0
    
    def _get_device_info(self) -> Dict[str, Any]:
        """Get device information"""
        device_info = {}
        
        try:
            # Get device model and serial
            result = subprocess.run(
                ["lsblk", "-d", "-o", "MODEL,SERIAL,VENDOR,SIZE,ROTA,RM", "-n", self.device_path],
                capture_output=True, text=True, check=True
            )
            
            parts = result.stdout.strip().split()
            if len(parts) >= 5:
                device_info = {
                    "model": parts[0] if parts[0] else "Unknown",
                    "serial": parts[1] if parts[1] else "Unknown",
                    "vendor": parts[2] if parts[2] else "Unknown",
                    "size": parts[3] if parts[3] else "Unknown",
                    "rotational": parts[4] == "1",
                    "removable": parts[5] == "1" if len(parts) > 5 else False
                }
                
        except subprocess.CalledProcessError:
            device_info = {
                "model": "Unknown",
                "serial": "Unknown",
                "vendor": "Unknown",
                "size": "Unknown",
                "rotational": False,
                "removable": False
            }
        
        return device_info
    
    def _get_performance_metrics(self) -> Dict[str, Any]:
        """Get performance metrics"""
        metrics = {
            "read_speed": 0,
            "write_speed": 0,
            "random_read_iops": 0,
            "random_write_iops": 0,
            "latency_ms": 0
        }
        
        # This would require benchmarking tools
        # For now, return placeholder values
        return metrics
    
    def _parse_size(self, size_str: str) -> int:
        """Parse size string to bytes"""
        size_str = size_str.strip().upper()
        
        if size_str.endswith("KB"):
            return int(float(size_str[:-2]) * 1024)
        elif size_str.endswith("MB"):
            return int(float(size_str[:-2]) * 1024 * 1024)
        elif size_str.endswith("GB"):
            return int(float(size_str[:-2]) * 1024 * 1024 * 1024)
        elif size_str.endswith("TB"):
            return int(float(size_str[:-2]) * 1024 * 1024 * 1024 * 1024)
        elif size_str.endswith("B"):
            return int(size_str[:-1])
        else:
            # Assume bytes if no unit
            try:
                return int(size_str)
            except ValueError:
                return 0
    
    def _format_bytes(self, bytes_value: int) -> str:
        """Format bytes to human readable string"""
        if bytes_value == 0:
            return "0 B"
        
        units = ["B", "KB", "MB", "GB", "TB", "PB"]
        unit_index = 0
        
        while bytes_value >= 1024 and unit_index < len(units) - 1:
            bytes_value /= 1024
            unit_index += 1
        
        return f"{bytes_value:.2f} {units[unit_index]}"
    
    def run_disk_check(self) -> Dict[str, Any]:
        """Run comprehensive disk check"""
        check_results = {
            "timestamp": datetime.datetime.now().isoformat(),
            "checks": {},
            "overall_status": "Unknown"
        }
        
        # Filesystem check
        try:
            result = subprocess.run(
                ["ntfsck", "-n", self.device_path],
                capture_output=True, text=True
            )
            
            check_results["checks"]["filesystem"] = {
                "status": "Passed" if result.returncode == 0 else "Failed",
                "dirty_bit": "Dirty" in result.stderr,
                "errors": result.stderr.strip() if result.stderr else ""
            }
        except subprocess.CalledProcessError as e:
            check_results["checks"]["filesystem"] = {
                "status": "Error",
                "error": str(e)
            }
        
        # SMART check
        try:
            result = subprocess.run(
                ["smartctl", "-H", self.device_path],
                capture_output=True, text=True, check=True
            )
            
            smart_status = "Unknown"
            for line in result.stdout.splitlines():
                if "SMART overall-health self-assessment test result:" in line:
                    if "PASSED" in line:
                        smart_status = "Passed"
                    else:
                        smart_status = "Failed"
                    break
            
            check_results["checks"]["smart"] = {
                "status": smart_status,
                "details": result.stdout.strip()
            }
        except subprocess.CalledProcessError as e:
            check_results["checks"]["smart"] = {
                "status": "Error",
                "error": str(e)
            }
        
        # Determine overall status
        all_passed = all(
            check.get("status", "Error") in ["Passed", "OK"]
            for check in check_results["checks"].values()
        )
        
        check_results["overall_status"] = "Passed" if all_passed else "Failed"
        
        return check_results
    
    def get_windows_style_properties(self) -> str:
        """Get properties formatted like Windows Explorer"""
        properties = self.get_all_properties()
        
        output = []
        output.append(f"Volume: {properties['volume']['name'] or 'Local Disk'}")
        output.append(f"File system: {properties['volume']['filesystem']}")
        output.append("")
        
        # Capacity section
        output.append("Capacity:")
        output.append(f"  Used space: {properties['volume']['used_space']}")
        output.append(f"  Free space: {properties['volume']['free_space']}")
        output.append(f"  Total size: {properties['volume']['total_size']}")
        output.append("")
        
        # Device section
        device = properties['device']
        output.append("Device:")
        output.append(f"  Model: {device['model']}")
        output.append(f"  Serial: {device['serial']}")
        output.append(f"  Vendor: {device['vendor']}")
        output.append(f"  Size: {device['size']}")
        output.append("")
        
        # Health section
        health = properties['health']
        output.append("Health:")
        output.append(f"  SMART Status: {health['smart_status']}")
        output.append(f"  Dirty Bit: {'Set' if health['dirty_bit'] else 'Clear'}")
        output.append(f"  Bad Sectors: {health['bad_sectors']}")
        output.append("")
        
        return "\n".join(output)
