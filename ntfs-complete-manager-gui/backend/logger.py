#!/usr/bin/env python3
"""
Comprehensive Logging System
Handles all logging operations for the NTFS Manager
"""

import logging
import logging.handlers
import os
import sys
import json
import datetime
from typing import Dict, Any, Optional
from pathlib import Path

class NTFSLogger:
    """Enhanced logging system for NTFS Manager"""
    
    def __init__(self, name: str = "ntfs_manager", log_dir: str = "/var/log/ntfs-manager"):
        self.name = name
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
        # Create loggers for different purposes
        self.main_logger = self._create_logger("main", "main.log")
        self.operation_logger = self._create_logger("operations", "operations.log")
        self.error_logger = self._create_logger("errors", "errors.log")
        self.security_logger = self._create_logger("security", "security.log")
        self.audit_logger = self._create_logger("audit", "audit.log")
        
        # JSON structured logger for machine parsing
        self.json_logger = self._create_json_logger("json", "structured.json")
        
    def _create_logger(self, logger_name: str, filename: str) -> logging.Logger:
        """Create a configured logger"""
        logger = logging.getLogger(f"{self.name}.{logger_name}")
        logger.setLevel(logging.DEBUG)
        
        # Clear existing handlers
        logger.handlers.clear()
        
        # File handler with rotation
        file_handler = logging.handlers.RotatingFileHandler(
            self.log_dir / filename,
            maxBytes=10*1024*1024,  # 10MB
            backupCount=5
        )
        file_handler.setLevel(logging.DEBUG)
        
        # Console handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)
        
        # Formatters
        file_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s'
        )
        console_formatter = logging.Formatter(
            '%(levelname)s: %(message)s'
        )
        
        file_handler.setFormatter(file_formatter)
        console_handler.setFormatter(console_formatter)
        
        logger.addHandler(file_handler)
        logger.addHandler(console_handler)
        
        return logger
    
    def _create_json_logger(self, logger_name: str, filename: str) -> logging.Logger:
        """Create JSON structured logger"""
        logger = logging.getLogger(f"{self.name}.{logger_name}")
        logger.setLevel(logging.DEBUG)
        
        # Clear existing handlers
        logger.handlers.clear()
        
        # File handler for JSON logs
        file_handler = logging.handlers.RotatingFileHandler(
            self.log_dir / filename,
            maxBytes=10*1024*1024,  # 10MB
            backupCount=5
        )
        file_handler.setLevel(logging.DEBUG)
        
        # JSON formatter
        json_formatter = JsonFormatter()
        file_handler.setFormatter(json_formatter)
        
        logger.addHandler(file_handler)
        
        return logger
    
    def info(self, message: str, **kwargs):
        """Log info message"""
        self.main_logger.info(message)
        if kwargs:
            self.json_logger.info(message, extra=kwargs)
    
    def debug(self, message: str, **kwargs):
        """Log debug message"""
        self.main_logger.debug(message)
        if kwargs:
            self.json_logger.debug(message, extra=kwargs)
    
    def warning(self, message: str, **kwargs):
        """Log warning message"""
        self.main_logger.warning(message)
        if kwargs:
            self.json_logger.warning(message, extra=kwargs)
    
    def error(self, message: str, **kwargs):
        """Log error message"""
        self.main_logger.error(message)
        self.error_logger.error(message)
        if kwargs:
            self.json_logger.error(message, extra=kwargs)
    
    def critical(self, message: str, **kwargs):
        """Log critical message"""
        self.main_logger.critical(message)
        self.error_logger.critical(message)
        if kwargs:
            self.json_logger.critical(message, extra=kwargs)
    
    def operation(self, operation: str, device: str, status: str, details: Dict[str, Any] = None):
        """Log drive operation"""
        message = f"Operation: {operation} on {device} - {status}"
        self.operation_logger.info(message)
        
        log_data = {
            "operation": operation,
            "device": device,
            "status": status,
            "timestamp": datetime.datetime.now().isoformat(),
            "details": details or {}
        }
        self.json_logger.info(message, extra=log_data)
    
    def security_event(self, event_type: str, user: str, device: str, action: str, details: Dict[str, Any] = None):
        """Log security event"""
        message = f"Security: {event_type} by {user} on {device} - {action}"
        self.security_logger.info(message)
        
        log_data = {
            "event_type": event_type,
            "user": user,
            "device": device,
            "action": action,
            "timestamp": datetime.datetime.now().isoformat(),
            "details": details or {}
        }
        self.json_logger.info(message, extra=log_data)
    
    def audit_event(self, action: str, user: str, device: str, result: str, details: Dict[str, Any] = None):
        """Log audit event"""
        message = f"Audit: {action} by {user} on {device} - {result}"
        self.audit_logger.info(message)
        
        log_data = {
            "action": action,
            "user": user,
            "device": device,
            "result": result,
            "timestamp": datetime.datetime.now().isoformat(),
            "details": details or {}
        }
        self.json_logger.info(message, extra=log_data)
    
    def drive_event(self, event_type: str, drive_info: Dict[str, Any]):
        """Log drive connection/disconnection events"""
        message = f"Drive Event: {event_type} - {drive_info.get('name', 'Unknown')}"
        self.main_logger.info(message)
        
        log_data = {
            "event_type": event_type,
            "drive_info": drive_info,
            "timestamp": datetime.datetime.now().isoformat()
        }
        self.json_logger.info(message, extra=log_data)
    
    def get_recent_logs(self, log_type: str = "main", lines: int = 100) -> list:
        """Get recent log entries"""
        log_file = self.log_dir / f"{log_type}.log"
        
        if not log_file.exists():
            return []
        
        try:
            with open(log_file, 'r') as f:
                all_lines = f.readlines()
                return all_lines[-lines:] if len(all_lines) > lines else all_lines
        except Exception as e:
            self.error(f"Error reading log file {log_file}: {e}")
            return []
    
    def get_operation_history(self, device: str = None, limit: int = 50) -> list:
        """Get operation history from JSON logs"""
        json_file = self.log_dir / "structured.json"
        
        if not json_file.exists():
            return []
        
        operations = []
        try:
            with open(json_file, 'r') as f:
                for line in f:
                    try:
                        log_entry = json.loads(line.strip())
                        if 'operation' in log_entry:
                            if device is None or log_entry.get('device') == device:
                                operations.append(log_entry)
                    except json.JSONDecodeError:
                        continue
                        
        except Exception as e:
            self.error(f"Error reading JSON log file: {e}")
        
        # Sort by timestamp and limit
        operations.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        return operations[:limit]
    
    def get_error_summary(self, hours: int = 24) -> Dict[str, Any]:
        """Get error summary for the last N hours"""
        error_file = self.log_dir / "errors.log"
        
        if not error_file.exists():
            return {"total_errors": 0, "error_types": {}, "recent_errors": []}
        
        cutoff_time = datetime.datetime.now() - datetime.timedelta(hours=hours)
        errors = []
        error_types = {}
        
        try:
            with open(error_file, 'r') as f:
                for line in f:
                    try:
                        # Parse timestamp from log line
                        if line.strip():
                            errors.append(line.strip())
                            # Extract error type (simplified)
                            if "ERROR" in line:
                                error_type = line.split("ERROR")[-1].strip()[:50]
                                error_types[error_type] = error_types.get(error_type, 0) + 1
                    except Exception:
                        continue
                        
        except Exception as e:
            self.error(f"Error reading error log: {e}")
        
        return {
            "total_errors": len(errors),
            "error_types": error_types,
            "recent_errors": errors[-10:]  # Last 10 errors
        }
    
    def export_logs(self, output_file: str, format_type: str = "json", start_date: str = None, end_date: str = None):
        """Export logs to file"""
        json_file = self.log_dir / "structured.json"
        
        if not json_file.exists():
            return False
        
        try:
            logs = []
            with open(json_file, 'r') as f:
                for line in f:
                    try:
                        log_entry = json.loads(line.strip())
                        
                        # Filter by date if specified
                        if start_date or end_date:
                            timestamp = log_entry.get('timestamp', '')
                            if start_date and timestamp < start_date:
                                continue
                            if end_date and timestamp > end_date:
                                continue
                        
                        logs.append(log_entry)
                    except json.JSONDecodeError:
                        continue
            
            # Export based on format
            if format_type.lower() == "json":
                with open(output_file, 'w') as f:
                    json.dump(logs, f, indent=2)
            elif format_type.lower() == "csv":
                import csv
                if logs:
                    with open(output_file, 'w', newline='') as f:
                        writer = csv.DictWriter(f, fieldnames=logs[0].keys())
                        writer.writeheader()
                        writer.writerows(logs)
            
            return True
            
        except Exception as e:
            self.error(f"Error exporting logs: {e}")
            return False
    
    def cleanup_old_logs(self, days: int = 30):
        """Clean up old log files"""
        cutoff_date = datetime.datetime.now() - datetime.timedelta(days=days)
        
        for log_file in self.log_dir.glob("*.log*"):
            try:
                file_time = datetime.datetime.fromtimestamp(log_file.stat().st_mtime)
                if file_time < cutoff_date:
                    log_file.unlink()
                    self.info(f"Deleted old log file: {log_file}")
            except Exception as e:
                self.error(f"Error deleting old log file {log_file}: {e}")
    
    def get_log_stats(self) -> Dict[str, Any]:
        """Get logging statistics"""
        stats = {
            "log_directory": str(self.log_dir),
            "total_log_files": 0,
            "total_size_mb": 0,
            "log_files": {}
        }
        
        try:
            for log_file in self.log_dir.glob("*"):
                if log_file.is_file():
                    stats["total_log_files"] += 1
                    size_mb = log_file.stat().st_size / (1024 * 1024)
                    stats["total_size_mb"] += size_mb
                    stats["log_files"][log_file.name] = {
                        "size_mb": round(size_mb, 2),
                        "modified": datetime.datetime.fromtimestamp(log_file.stat().st_mtime).isoformat()
                    }
        except Exception as e:
            self.error(f"Error getting log stats: {e}")
        
        stats["total_size_mb"] = round(stats["total_size_mb"], 2)
        return stats


class JsonFormatter(logging.Formatter):
    """Custom JSON formatter for structured logging"""
    
    def format(self, record):
        log_entry = {
            "timestamp": datetime.datetime.now().isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno
        }
        
        # Add extra fields if present
        if hasattr(record, '__dict__'):
            for key, value in record.__dict__.items():
                if key not in ['name', 'msg', 'args', 'levelname', 'levelno', 'pathname', 
                              'filename', 'module', 'lineno', 'funcName', 'created', 
                              'msecs', 'relativeCreated', 'thread', 'threadName', 
                              'processName', 'process', 'getMessage', 'exc_info', 
                              'exc_text', 'stack_info']:
                    log_entry[key] = value
        
        return json.dumps(log_entry)


# Global logger instance
_logger_instance = None

def get_logger(name: str = "ntfs_manager") -> NTFSLogger:
    """Get or create logger instance"""
    global _logger_instance
    if _logger_instance is None:
        _logger_instance = NTFSLogger(name)
    return _logger_instance

def setup_logging(log_level: str = "INFO", log_dir: str = "/var/log/ntfs-manager"):
    """Setup logging configuration"""
    global _logger_instance
    _logger_instance = NTFSLogger("ntfs_manager", log_dir)
    
    # Set log level
    level = getattr(logging, log_level.upper(), logging.INFO)
    _logger_instance.main_logger.setLevel(level)
    
    return _logger_instance
