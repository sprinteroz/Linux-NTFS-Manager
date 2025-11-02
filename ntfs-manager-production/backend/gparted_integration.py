#!/usr/bin/env python3
"""
GParted Integration Module
Provides integration with GParted for advanced partition management
"""

import subprocess
import re
import json
import os
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
from pathlib import Path

@dataclass
class PartitionInfo:
    """Data class for partition information"""
    device: str
    number: int
    start: str
    end: str
    size: str
    fstype: str
    label: str = ""
    flags: str = ""
    mountpoint: str = ""

@dataclass
class DeviceInfo:
    """Data class for device information"""
    device: str
    model: str = ""
    size: str = ""
    sector_size: str = ""
    partition_table: str = ""
    partitions: List[PartitionInfo] = None
    
    def __post_init__(self):
        if self.partitions is None:
            self.partitions = []

class GPartedManager:
    """GParted integration class"""
    
    def __init__(self):
        self.gparted_path = self._find_gparted()
        
    def _find_gparted(self) -> str:
        """Find GParted executable"""
        try:
            result = subprocess.run(
                ["which", "gparted"],
                capture_output=True, text=True, check=True
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError:
            return ""
    
    def is_available(self) -> bool:
        """Check if GParted is available"""
        return bool(self.gparted_path)
    
    def get_device_list(self) -> List[DeviceInfo]:
        """Get list of devices from GParted"""
        if not self.is_available():
            return []
        
        try:
            # Get list of devices
            result = subprocess.run(
                [self.gparted_path, "--list", "--json"],
                capture_output=True, text=True, check=True
            )
            
            if result.returncode != 0:
                return []
            
            # Parse JSON output
            try:
                data = json.loads(result.stdout)
                devices = []
                
                for device_data in data.get("disk", []):
                    device = DeviceInfo(
                        device=device_data.get("path", ""),
                        model=device_data.get("model", ""),
                        size=device_data.get("size", ""),
                        sector_size=device_data.get("sector-size", ""),
                        partition_table=device_data.get("partition-table", "")
                    )
                    
                    # Parse partitions
                    partitions = []
                    for part_data in device_data.get("partitions", []):
                        partition = PartitionInfo(
                            device=device_data.get("path", ""),
                            number=part_data.get("number", 0),
                            start=part_data.get("start", ""),
                            end=part_data.get("end", ""),
                            size=part_data.get("size", ""),
                            fstype=part_data.get("fstype", ""),
                            label=part_data.get("name", ""),
                            flags=part_data.get("flags", ""),
                            mountpoint=self._get_mount_point(device_data.get("path", ""), part_data.get("number", 0))
                        )
                        partitions.append(partition)
                    
                    device.partitions = partitions
                    devices.append(device)
                
                return devices
                
            except json.JSONDecodeError:
                # Fallback to text parsing
                return self._parse_text_output(result.stdout)
                
        except subprocess.CalledProcessError as e:
            print(f"Error getting device list: {e}")
            return []
    
    def _parse_text_output(self, output: str) -> List[DeviceInfo]:
        """Parse text output from GParted"""
        devices = []
        current_device = None
        
        for line in output.splitlines():
            line = line.strip()
            if not line:
                continue
            
            # Device line
            if line.startswith("Disk"):
                if current_device:
                    devices.append(current_device)
                
                parts = line.split(":")
                if len(parts) >= 2:
                    device_path = parts[1].strip()
                    current_device = DeviceInfo(device=device_path)
            
            # Partition line
            elif current_device and line.startswith(" "):  # Indented partition line
                parts = line.split()
                if len(parts) >= 6:
                    try:
                        partition = PartitionInfo(
                            device=current_device.device,
                            number=int(parts[1]),
                            start=parts[2],
                            end=parts[3],
                            size=parts[4],
                            fstype=parts[5],
                            mountpoint=self._get_mount_point(current_device.device, int(parts[1]))
                        )
                        current_device.partitions.append(partition)
                    except (ValueError, IndexError):
                        continue
        
        if current_device:
            devices.append(current_device)
        
        return devices
    
    def _get_mount_point(self, device: str, partition_num: int) -> str:
        """Get mount point for a partition"""
        try:
            partition_name = f"{device}{partition_num}"
            
            # Try to get mount point from system
            result = subprocess.run(
                ["findmnt", "-n", "-o", "TARGET", "-S", partition_name],
                capture_output=True, text=True, check=True
            )
            
            if result.returncode == 0:
                return result.stdout.strip()
            
            # Fallback to /proc/mounts
            try:
                with open("/proc/mounts", "r") as f:
                    for line in f:
                        if partition_name in line:
                            parts = line.split()
                            if len(parts) >= 2:
                                return parts[1].strip()
            except FileNotFoundError:
                pass
            
            return ""
            
        except Exception:
            return ""
    
    def create_partition(self, device: str, start: str, end: str, size: str, fstype: str, label: str = "") -> bool:
        """Create a new partition"""
        if not self.is_available():
            return False
        
        try:
            # Build gparted command
            cmd = [self.gparted_path, "mkpart", fstype, device, start, end, "--", size]
            if label:
                cmd.extend(["--label", label])
            
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.returncode == 0
            
        except subprocess.CalledProcessError:
            return False
    
    def delete_partition(self, device: str, partition_num: int) -> bool:
        """Delete a partition"""
        if not self.is_available():
            return False
        
        try:
            result = subprocess.run(
                [self.gparted_path, "rm", f"{device}{partition_num}"],
                capture_output=True, text=True, check=True
            )
            return result.returncode == 0
            
        except subprocess.CalledProcessError:
            return False
    
    def format_partition(self, device: str, partition_num: int, fstype: str, label: str = "") -> bool:
        """Format a partition"""
        if not self.is_available():
            return False
        
        try:
            cmd = [self.gparted_path, "mkpart", fstype, f"{device}{partition_num}"]
            if label:
                cmd.extend(["--label", label])
            
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.returncode == 0
            
        except subprocess.CalledProcessError:
            return False
    
    def resize_partition(self, device: str, partition_num: int, new_size: str) -> bool:
        """Resize a partition"""
        if not self.is_available():
            return False
        
        try:
            result = subprocess.run(
                [self.gparted_path, "resize", f"{device}{partition_num}", new_size],
                capture_output=True, text=True, check=True
            )
            return result.returncode == 0
            
        except subprocess.CalledProcessError:
            return False
    
    def set_partition_flag(self, device: str, partition_num: int, flag: str) -> bool:
        """Set partition flag (boot, hidden, etc.)"""
        if not self.is_available():
            return False
        
        try:
            result = subprocess.run(
                [self.gparted_path, "set", f"{device}{partition_num}", flag, "on"],
                capture_output=True, text=True, check=True
            )
            return result.returncode == 0
            
        except subprocess.CalledProcessError:
            return False
    
    def get_partition_info(self, device: str, partition_num: int) -> Optional[PartitionInfo]:
        """Get detailed information about a specific partition"""
        if not self.is_available():
            return None
        
        try:
            result = subprocess.run(
                [self.gparted_path, "info", f"{device}{partition_num}"],
                capture_output=True, text=True, check=True
            )
            
            if result.returncode != 0:
                return None
            
            # Parse the output
            info = PartitionInfo(device=device, number=partition_num)
            
            for line in result.stdout.splitlines():
                line = line.strip()
                if not line:
                    continue
                
                if "Filesystem:" in line:
                    info.fstype = line.split(":", 1)[1].strip()
                elif "Start:" in line:
                    info.start = line.split(":", 1)[1].strip()
                elif "End:" in line:
                    info.end = line.split(":", 1)[1].strip()
                elif "Size:" in line:
                    info.size = line.split(":", 1)[1].strip()
                elif "Flags:" in line:
                    info.flags = line.split(":", 1)[1].strip()
                elif "Name:" in line:
                    info.label = line.split(":", 1)[1].strip()
            
            return info
            
        except subprocess.CalledProcessError:
            return None
    
    def apply_changes(self, device: str) -> bool:
        """Apply all pending changes to device"""
        if not self.is_available():
            return False
        
        try:
            result = subprocess.run(
                [self.gparted_path, device],
                capture_output=True, text=True, check=True
            )
            return result.returncode == 0
            
        except subprocess.CalledProcessError:
            return False
