#!/bin/bash
# NTFS Complete Manager Launcher Script
# This ensures the application runs with correct working directory and Python path

# Set the application directory
APP_DIR="/opt/ntfs-manager/ntfs-complete-manager-gui"

# Check if running directory exists
if [ ! -d "$APP_DIR" ]; then
    echo "Error: Application directory not found: $APP_DIR"
    exit 1
fi

# Change to application directory (important for backend module imports)
cd "$APP_DIR" || exit 1

# Add the directory to PYTHONPATH
export PYTHONPATH="$APP_DIR:$PYTHONPATH"

# Run the application with all arguments passed through
exec python3 "$APP_DIR/main.py" "$@"
