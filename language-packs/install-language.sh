#!/bin/bash
# NTFS Manager Language Pack Installer

INSTALL_DIR="/usr/share/ntfs-manager/translations"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0 $@"
    exit 1
fi

# Get language code
LANG_CODE="$1"

if [ -z "$LANG_CODE" ]; then
    echo "Usage: $0 <language_code>"
    echo "Example: $0 es (for Spanish)"
    echo ""
    echo "Available languages:"
    ls -1 translations/*.json | sed 's/translations\//  /' | sed 's/.json//'
    exit 1
fi

# Check if translation exists
if [ ! -f "translations/${LANG_CODE}.json" ]; then
    echo "Error: Translation for '$LANG_CODE' not found"
    exit 1
fi

# Install translation
mkdir -p "$INSTALL_DIR"
cp "translations/${LANG_CODE}.json" "$INSTALL_DIR/"

echo "✓ Language pack for '$LANG_CODE' installed successfully"
echo "  Installed to: $INSTALL_DIR/${LANG_CODE}.json"
echo ""
echo "To use this language in NTFS Manager:"
echo "  export LANG=${LANG_CODE}_*.UTF-8"
echo "  ntfs-manager"

