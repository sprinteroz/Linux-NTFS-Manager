#!/usr/bin/env python3
"""
NTFS Manager Nautilus Extension
Integrates NTFS drive management functionality directly into Nautilus file manager
"""

import os
import sys
import subprocess
import threading
import time
from pathlib import Path
from typing import List, Optional, Dict, Any

# Add backend modules to path
backend_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'ntfs-complete-manager-gui', 'backend')
if os.path.exists(backend_path):
    sys.path.insert(0, backend_path)

try:
    import gi
    gi.require_version('Nautilus', '3.0')
    gi.require_version('Gtk', '3.0')
    from gi.repository import Nautilus, Gtk, GObject, Gio, GLib
    NAUTILUS_AVAILABLE = True
except (ImportError, ValueError):
    NAUTILUS_AVAILABLE = False
    print("Warning: Nautilus Python bindings not available")

# Import backend modules
try:
    from drive_manager import DriveManager, DriveInfo
    from ntfs_properties import NTFSProperties
    from logger import get_logger
    BACKEND_AVAILABLE = True
except ImportError as e:
    print(f"Warning: Backend modules not available: {e}")
    BACKEND_AVAILABLE = False
    
    # Create dummy classes for fallback
    class DriveManager:
        def __init__(self): pass
        def get_all_drives(self): return []
        def get_drive_properties(self, drive): return {}
        def mount_drive(self, drive): return False
        def unmount_drive(self, drive): return False
        def format_drive(self, drive, fstype, label): return False
        def repair_drive(self, drive): return False
        def add_callback(self, callback): pass
        def start_monitoring(self): pass
        def stop_monitoring(self): pass
    
    class DriveInfo:
        def __init__(self, name="", size="", fstype="", mountpoint="", label="", model="", vendor="", serial="", uuid="", is_removable=False, is_rotational=False, health_status="Unknown", temperature=0.0, smart_status="Unknown"):
            for key, value in locals().items():
                setattr(self, key, value)
    
    class NTFSProperties:
        def __init__(self, device_path): pass
        def get_all_properties(self): return {}
        def get_windows_style_properties(self): return ""
        def run_disk_check(self): return {"timestamp": "", "overall_status": "Unknown", "checks": {}}
    
    def get_logger(name="ntfs_manager"):
        class DummyLogger:
            def info(self, msg): pass
            def error(self, msg): pass
            def debug(self, msg): pass
            def operation(self, op, device, status, details=None): pass
        return DummyLogger()

class NTFSManagerExtension(GObject.GObject, Nautilus.MenuProvider, Nautilus.ColumnProvider, Nautilus.InfoProvider):
    """Main NTFS Manager extension class"""
    
    def __init__(self):
        if not NAUTILUS_AVAILABLE or not BACKEND_AVAILABLE:
            print("NTFS Manager Extension: Dependencies not available, extension disabled")
            return
            
        super().__init__()
        self.drive_manager = DriveManager()
        self.logger = get_logger()
        self.drive_cache = {}
        self.last_update = 0
        
        # Start drive monitoring
        self.drive_manager.start_monitoring()
        self.logger.info("NTFS Manager Nautilus Extension initialized")
        
        # Initial drive scan
        self.refresh_drive_cache()
    
    def refresh_drive_cache(self):
        """Refresh the drive information cache"""
        try:
            drives = self.drive_manager.get_all_drives()
            self.drive_cache = {drive.name: drive for drive in drives}
            self.last_update = time.time()
            self.logger.debug(f"Drive cache refreshed: {len(drives)} drives")
        except Exception as e:
            self.logger.error(f"Error refreshing drive cache: {e}")
    
    def get_file_items(self, window, files):
        """Get menu items for selected files"""
        if not NAUTILUS_AVAILABLE or not BACKEND_AVAILABLE:
            return []
        
        # Refresh cache if it's old (more than 30 seconds)
        if time.time() - self.last_update > 30:
            self.refresh_drive_cache()
        
        items = []
        
        for file_info in files:
            # Check if this is a drive or mount point we can manage
            drive_info = self.get_drive_for_file(file_info)
            if drive_info:
                menu_items = self.create_drive_menu_items(file_info, drive_info)
                items.extend(menu_items)
        
        return items
    
    def get_drive_for_file(self, file_info) -> Optional[DriveInfo]:
        """Get drive information for a file"""
        try:
            # Get the file path
            if file_info.get_uri_scheme() != 'file':
                return None
            
            file_path = file_info.get_location().get_path()
            if not file_path:
                return None
            
            # Check if it's a block device
            if file_path.startswith('/dev/'):
                drive_name = os.path.basename(file_path)
                return self.drive_cache.get(drive_name)
            
            # Check if it's a mount point
            for drive in self.drive_cache.values():
                if drive.mountpoint and file_path.startswith(drive.mountpoint):
                    return drive
            
            # Check if it's in /media or /mnt (common mount locations)
            if file_path.startswith('/media/') or file_path.startswith('/mnt/'):
                # Try to find the corresponding drive
                for drive in self.drive_cache.values():
                    if drive.mountpoint and file_path.startswith(drive.mountpoint):
                        return drive
            
        except Exception as e:
            self.logger.error(f"Error getting drive for file: {e}")
        
        return None
    
    def create_drive_menu_items(self, file_info, drive_info: DriveInfo) -> List[Nautilus.MenuItem]:
        """Create context menu items for a drive"""
        items = []
        
        # Main NTFS Management submenu
        main_item = Nautilus.MenuItem(
            name='NTFSManager::Main',
            label='NTFS Management',
            icon='drive-harddisk'
        )
        main_submenu = Nautilus.Menu()
        main_item.set_submenu(main_submenu)
        items.append(main_item)
        
        # Mount/Unmount item
        if drive_info.mountpoint:
            mount_item = Nautilus.MenuItem(
                name='NTFSManager::Unmount',
                label='Unmount Drive',
                icon='media-eject'
            )
            mount_item.connect('activate', self.on_unmount_drive, drive_info)
            main_submenu.append_item(mount_item)
        else:
            mount_item = Nautilus.MenuItem(
                name='NTFSManager::Mount',
                label='Mount Drive',
                icon='drive-harddisk'
            )
            mount_item.connect('activate', self.on_mount_drive, drive_info)
            main_submenu.append_item(mount_item)
        
        # Separator
        main_submenu.append_item(Nautilus.MenuItem(name='NTFSManager::Sep1', label='-'))
        
        # Properties item
        props_item = Nautilus.MenuItem(
            name='NTFSManager::Properties',
            label='Drive Properties',
            icon='document-properties'
        )
        props_item.connect('activate', self.on_show_properties, drive_info)
        main_submenu.append_item(props_item)
        
        # Health Check item
        health_item = Nautilus.MenuItem(
            name='NTFSManager::Health',
            label='Health Check',
            icon='system-run'
        )
        health_item.connect('activate', self.on_health_check, drive_info)
        main_submenu.append_item(health_item)
        
        # Separator
        main_submenu.append_item(Nautilus.MenuItem(name='NTFSManager::Sep2', label='-'))
        
        # Repair item
        repair_item = Nautilus.MenuItem(
            name='NTFSManager::Repair',
            label='Repair Drive',
            icon='tools'
        )
        repair_item.connect('activate', self.on_repair_drive, drive_info)
        main_submenu.append_item(repair_item)
        
        # Format item (with warning)
        format_item = Nautilus.MenuItem(
            name='NTFSManager::Format',
            label='Format Drive (DANGEROUS)',
            icon='format-disks'
        )
        format_item.connect('activate', self.on_format_drive, drive_info)
        main_submenu.append_item(format_item)
        
        # Safe Eject item (for removable drives)
        if drive_info.is_removable:
            main_submenu.append_item(Nautilus.MenuItem(name='NTFSManager::Sep3', label='-'))
            eject_item = Nautilus.MenuItem(
                name='NTFSManager::Eject',
                label='Safe Eject',
                icon='media-eject'
            )
            eject_item.connect('activate', self.on_eject_drive, drive_info)
            main_submenu.append_item(eject_item)
        
        return items
    
    def on_mount_drive(self, menu_item, drive_info: DriveInfo):
        """Handle mount drive action"""
        def mount_operation():
            try:
                success = self.drive_manager.mount_drive(drive_info.name)
                if success:
                    self.show_notification("Drive Mounted", f"{drive_info.name} mounted successfully")
                    self.logger.operation("mount", drive_info.name, "success")
                    self.refresh_drive_cache()
                else:
                    self.show_error_dialog("Mount Failed", f"Failed to mount {drive_info.name}")
                    self.logger.operation("mount", drive_info.name, "failed")
            except Exception as e:
                self.show_error_dialog("Mount Error", f"Error mounting {drive_info.name}: {e}")
                self.logger.error(f"Error mounting {drive_info.name}: {e}")
        
        # Run in thread to avoid blocking UI
        threading.Thread(target=mount_operation, daemon=True).start()
    
    def on_unmount_drive(self, menu_item, drive_info: DriveInfo):
        """Handle unmount drive action"""
        def unmount_operation():
            try:
                success = self.drive_manager.unmount_drive(drive_info.name)
                if success:
                    self.show_notification("Drive Unmounted", f"{drive_info.name} unmounted successfully")
                    self.logger.operation("unmount", drive_info.name, "success")
                    self.refresh_drive_cache()
                else:
                    self.show_error_dialog("Unmount Failed", f"Failed to unmount {drive_info.name}")
                    self.logger.operation("unmount", drive_info.name, "failed")
            except Exception as e:
                self.show_error_dialog("Unmount Error", f"Error unmounting {drive_info.name}: {e}")
                self.logger.error(f"Error unmounting {drive_info.name}: {e}")
        
        threading.Thread(target=unmount_operation, daemon=True).start()
    
    def on_show_properties(self, menu_item, drive_info: DriveInfo):
        """Handle show properties action"""
        self.show_properties_dialog(drive_info)
    
    def on_health_check(self, menu_item, drive_info: DriveInfo):
        """Handle health check action"""
        def health_operation():
            try:
                device_path = f"/dev/{drive_info.name}"
                ntfs_props = NTFSProperties(device_path)
                health_results = ntfs_props.run_disk_check()
                
                # Show results in dialog
                GLib.idle_add(self.show_health_dialog, drive_info, health_results)
                self.logger.operation("health_check", drive_info.name, "completed")
            except Exception as e:
                GLib.idle_add(self.show_error_dialog, "Health Check Error", f"Error checking {drive_info.name}: {e}")
                self.logger.error(f"Error checking health of {drive_info.name}: {e}")
        
        threading.Thread(target=health_operation, daemon=True).start()
    
    def on_repair_drive(self, menu_item, drive_info: DriveInfo):
        """Handle repair drive action"""
        # Show confirmation dialog
        dialog = Gtk.MessageDialog(
            parent=None,
            flags=Gtk.DialogFlags.MODAL,
            type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.YES_NO,
            message_format=f"Repair drive {drive_info.name}?\n\nThis will attempt to fix filesystem errors."
        )
        
        response = dialog.run()
        dialog.destroy()
        
        if response == Gtk.ResponseType.YES:
            def repair_operation():
                try:
                    success = self.drive_manager.repair_drive(drive_info.name)
                    if success:
                        self.show_notification("Drive Repaired", f"{drive_info.name} repaired successfully")
                        self.logger.operation("repair", drive_info.name, "success")
                        self.refresh_drive_cache()
                    else:
                        self.show_error_dialog("Repair Failed", f"Failed to repair {drive_info.name}")
                        self.logger.operation("repair", drive_info.name, "failed")
                except Exception as e:
                    self.show_error_dialog("Repair Error", f"Error repairing {drive_info.name}: {e}")
                    self.logger.error(f"Error repairing {drive_info.name}: {e}")
            
            threading.Thread(target=repair_operation, daemon=True).start()
    
    def on_format_drive(self, menu_item, drive_info: DriveInfo):
        """Handle format drive action"""
        self.show_format_dialog(drive_info)
    
    def on_eject_drive(self, menu_item, drive_info: DriveInfo):
        """Handle safe eject action"""
        def eject_operation():
            try:
                # First unmount if mounted
                if drive_info.mountpoint:
                    self.drive_manager.unmount_drive(drive_info.name)
                
                # Then eject
                device_path = f"/dev/{drive_info.name}"
                result = subprocess.run(["eject", device_path], capture_output=True, text=True)
                
                if result.returncode == 0:
                    self.show_notification("Drive Ejected", f"{drive_info.name} ejected safely")
                    self.logger.operation("eject", drive_info.name, "success")
                    self.refresh_drive_cache()
                else:
                    self.show_error_dialog("Eject Failed", f"Failed to eject {drive_info.name}")
                    self.logger.operation("eject", drive_info.name, "failed")
            except Exception as e:
                self.show_error_dialog("Eject Error", f"Error ejecting {drive_info.name}: {e}")
                self.logger.error(f"Error ejecting {drive_info.name}: {e}")
        
        threading.Thread(target=eject_operation, daemon=True).start()
    
    def show_properties_dialog(self, drive_info: DriveInfo):
        """Show drive properties dialog"""
        dialog = Gtk.Dialog(title=f"NTFS Properties - {drive_info.name}", flags=Gtk.DialogFlags.MODAL)
        dialog.add_button("Close", Gtk.ResponseType.CLOSE)
        dialog.set_default_size(700, 600)
        
        content_area = dialog.get_content_area()
        
        # Create notebook for tabbed properties
        notebook = Gtk.Notebook()
        
        # Basic properties tab
        basic_page = Gtk.ScrolledWindow()
        basic_text = Gtk.TextView()
        basic_text.set_editable(False)
        basic_text.set_wrap_mode(Gtk.WrapMode.WORD)
        basic_page.add(basic_text)
        notebook.append_page(basic_page, Gtk.Label(label="Basic"))
        
        # NTFS properties tab (if applicable)
        if drive_info.fstype == 'ntfs':
            ntfs_page = Gtk.ScrolledWindow()
            ntfs_text = Gtk.TextView()
            ntfs_text.set_editable(False)
            ntfs_text.set_wrap_mode(Gtk.WrapMode.WORD)
            ntfs_page.add(ntfs_text)
            notebook.append_page(ntfs_page, Gtk.Label(label="NTFS"))
        
        content_area.pack_start(notebook, True, True, 5)
        
        # Load properties in background
        def load_properties():
            try:
                # Get basic properties
                properties = self.drive_manager.get_drive_properties(drive_info.name)
                basic_content = self.format_basic_properties(drive_info, properties)
                
                GLib.idle_add(lambda: basic_text.get_buffer().set_text(basic_content))
                
                # Load NTFS properties if applicable
                if drive_info.fstype == 'ntfs':
                    device_path = f"/dev/{drive_info.name}"
                    ntfs_props = NTFSProperties(device_path)
                    ntfs_details = ntfs_props.get_all_properties()
                    ntfs_content = self.format_ntfs_properties(ntfs_details)
                    
                    GLib.idle_add(lambda: ntfs_text.get_buffer().set_text(ntfs_content))
                    
            except Exception as e:
                error_msg = f"Error loading properties: {e}"
                GLib.idle_add(lambda: basic_text.get_buffer().set_text(error_msg))
        
        threading.Thread(target=load_properties, daemon=True).start()
        
        dialog.show_all()
        dialog.run()
        dialog.destroy()
    
    def show_health_dialog(self, drive_info: DriveInfo, health_results: Dict):
        """Show health check results dialog"""
        dialog = Gtk.Dialog(title=f"Health Check - {drive_info.name}", flags=Gtk.DialogFlags.MODAL)
        dialog.add_button("Close", Gtk.ResponseType.CLOSE)
        dialog.set_default_size(600, 400)
        
        content_area = dialog.get_content_area()
        
        scrolled = Gtk.ScrolledWindow()
        text_view = Gtk.TextView()
        text_view.set_editable(False)
        text_view.set_wrap_mode(Gtk.WrapMode.WORD)
        scrolled.add(text_view)
        content_area.pack_start(scrolled, True, True, 5)
        
        # Format health results
        health_content = self.format_health_results(health_results)
        buffer = text_view.get_buffer()
        buffer.set_text(health_content)
        
        dialog.show_all()
        dialog.run()
        dialog.destroy()
    
    def show_format_dialog(self, drive_info: DriveInfo):
        """Show format dialog"""
        dialog = Gtk.Dialog(title="Format Drive", flags=Gtk.DialogFlags.MODAL)
        dialog.add_button("Cancel", Gtk.ResponseType.CANCEL)
        dialog.add_button("Format", Gtk.ResponseType.OK)
        dialog.set_default_size(400, 300)
        
        content_area = dialog.get_content_area()
        
        # Warning label
        warning_label = Gtk.Label(label=f"WARNING: This will erase all data on {drive_info.name}!")
        warning_label.get_style_context().add_class("warning")
        content_area.pack_start(warning_label, False, False, 10)
        
        # Filesystem selection
        fs_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        fs_label = Gtk.Label(label="Filesystem:")
        fs_combo = Gtk.ComboBoxText()
        fs_combo.append_text("ntfs")
        fs_combo.append_text("ext4")
        fs_combo.append_text("fat32")
        fs_combo.set_active(0)  # Default to NTFS
        
        fs_box.pack_start(fs_label, False, False, 5)
        fs_box.pack_start(fs_combo, True, True, 5)
        content_area.pack_start(fs_box, False, False, 5)
        
        # Label entry
        label_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        label_entry_label = Gtk.Label(label="Label:")
        label_entry = Gtk.Entry()
        
        label_box.pack_start(label_entry_label, False, False, 5)
        label_box.pack_start(label_entry, True, True, 5)
        content_area.pack_start(label_box, False, False, 5)
        
        dialog.show_all()
        response = dialog.run()
        
        if response == Gtk.ResponseType.OK:
            fstype = fs_combo.get_active_text()
            label = label_entry.get_text()
            
            def format_operation():
                try:
                    success = self.drive_manager.format_drive(drive_info.name, fstype, label)
                    if success:
                        self.show_notification("Drive Formatted", f"{drive_info.name} formatted successfully")
                        self.logger.operation("format", drive_info.name, "success", {"filesystem": fstype, "label": label})
                        self.refresh_drive_cache()
                    else:
                        self.show_error_dialog("Format Failed", f"Failed to format {drive_info.name}")
                        self.logger.operation("format", drive_info.name, "failed", {"filesystem": fstype, "label": label})
                except Exception as e:
                    self.show_error_dialog("Format Error", f"Error formatting {drive_info.name}: {e}")
                    self.logger.error(f"Error formatting {drive_info.name}: {e}")
            
            threading.Thread(target=format_operation, daemon=True).start()
        
        dialog.destroy()
    
    def format_basic_properties(self, drive_info: DriveInfo, properties: dict) -> str:
        """Format basic drive properties"""
        lines = [
            f"Drive: {drive_info.name}",
            f"Size: {drive_info.size}",
            f"Filesystem: {drive_info.fstype}",
            f"Mount Point: {drive_info.mountpoint or 'Not mounted'}",
            f"Label: {drive_info.label or 'No label'}",
            f"Model: {drive_info.model}",
            f"Vendor: {drive_info.vendor}",
            f"Serial: {drive_info.serial}",
            f"UUID: {drive_info.uuid}",
            f"Removable: {'Yes' if drive_info.is_removable else 'No'}",
            f"Rotational: {'Yes' if drive_info.is_rotational else 'No'}",
            f"Health Status: {drive_info.health_status}",
            f"SMART Status: {drive_info.smart_status}",
        ]
        
        if drive_info.temperature > 0:
            lines.append(f"Temperature: {drive_info.temperature}°C")
        
        return "\n".join(lines)
    
    def format_ntfs_properties(self, properties: dict) -> str:
        """Format NTFS properties for display"""
        lines = []
        
        volume = properties.get('volume', {})
        lines.append("=== NTFS Volume Information ===")
        lines.append(f"Volume Name: {volume.get('name', 'Unknown')}")
        lines.append(f"Volume Serial: {volume.get('serial', 'Unknown')}")
        lines.append(f"Cluster Size: {volume.get('cluster_size', 0)} bytes")
        lines.append(f"Total Clusters: {volume.get('total_clusters', 0)}")
        lines.append(f"Free Clusters: {volume.get('free_clusters', 0)}")
        lines.append(f"Usage: {volume.get('usage_percentage', 0)}%")
        lines.append("")
        
        security = properties.get('security', {})
        lines.append("=== Security Information ===")
        lines.append(f"Owner: {security.get('owner', 'Unknown')}")
        lines.append(f"Group: {security.get('group', 'Unknown')}")
        lines.append(f"Permissions: {security.get('permissions', 'Unknown')}")
        lines.append(f"Encryption Status: {security.get('encryption_status', 'Unknown')}")
        lines.append("")
        
        health = properties.get('health', {})
        lines.append("=== Health Information ===")
        lines.append(f"Dirty Bit: {'Set' if health.get('dirty_bit') else 'Clear'}")
        lines.append(f"Needs Check: {'Yes' if health.get('needs_check') else 'No'}")
        lines.append(f"SMART Status: {health.get('smart_status', 'Unknown')}")
        lines.append(f"Bad Sectors: {health.get('bad_sectors', 0)}")
        lines.append(f"Reallocated Sectors: {health.get('reallocated_sectors', 0)}")
        lines.append("")
        
        return "\n".join(lines)
    
    def format_health_results(self, health_results: dict) -> str:
        """Format health check results for display"""
        lines = []
        lines.append("=== Drive Health Check ===")
        lines.append(f"Check Time: {health_results.get('timestamp', 'Unknown')}")
        lines.append(f"Overall Status: {health_results.get('overall_status', 'Unknown')}")
        lines.append("")
        
        checks = health_results.get('checks', {})
        for check_name, check_result in checks.items():
            lines.append(f"=== {check_name.title()} ===")
            lines.append(f"Status: {check_result.get('status', 'Unknown')}")
            
            if 'error' in check_result:
                lines.append(f"Error: {check_result['error']}")
            if 'dirty_bit' in check_result:
                lines.append(f"Dirty Bit: {'Set' if check_result['dirty_bit'] else 'Clear'}")
            if 'errors' in check_result:
                lines.append(f"Errors: {check_result['errors']}")
            lines.append("")
        
        return "\n".join(lines)
    
    def show_notification(self, title: str, message: str):
        """Show desktop notification"""
        try:
            subprocess.run([
                'notify-send',
                f'NTFS Manager: {title}',
                message,
                '--icon=drive-harddisk',
                '--expire-time=5000'
            ], check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            # Fallback to console if notify-send not available
            print(f"NTFS Manager: {title} - {message}")
    
    def show_error_dialog(self, title: str, message: str):
        """Show error dialog"""
        dialog = Gtk.MessageDialog(
            parent=None,
            flags=Gtk.DialogFlags.MODAL,
            type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            message_format=message
        )
        dialog.set_title(f"NTFS Manager: {title}")
        dialog.run()
        dialog.destroy()
    
    def get_columns(self):
        """Provide additional columns for Nautilus list view"""
        if not NAUTILUS_AVAILABLE or not BACKEND_AVAILABLE:
            return []
        
        return [
            Nautilus.Column(
                name="NTFSManager::HealthStatus",
                attribute="health_status",
                label="Health",
                description="Drive health status"
            ),
            Nautilus.Column(
                name="NTFSManager::FileSystem",
                attribute="filesystem",
                label="FS",
                description="Filesystem type"
            )
        ]
    
    def update_file_info(self, file_info):
        """Update file information with additional data"""
        if not NAUTILUS_AVAILABLE or not BACKEND_AVAILABLE:
            return Nautilus.OperationResult.COMPLETE
        
        try:
            drive_info = self.get_drive_for_file(file_info)
            if drive_info:
                # Add custom attributes
                file_info.add_string_attribute('health_status', drive_info.health_status)
                file_info.add_string_attribute('filesystem', drive_info.fstype)
                
                # Add emblem based on status
                if drive_info.health_status == "Dirty":
                    file_info.add_emblem('important')
                elif drive_info.health_status == "Error":
                    file_info.add_emblem('error')
                elif drive_info.mountpoint:
                    file_info.add_emblem('mounted')
        
        except Exception as e:
            self.logger.error(f"Error updating file info: {e}")
        
        return Nautilus.OperationResult.COMPLETE

# Extension entry point
if NAUTILUS_AVAILABLE and BACKEND_AVAILABLE:
    print("NTFS Manager Nautilus Extension loaded successfully")
else:
    print("NTFS Manager Nautilus Extension: Dependencies not available")
