#!/bin/bash
# Install All Language Packs for NTFS Manager

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

INSTALL_DIR="/usr/share/ntfs-manager/translations"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSLATIONS_DIR="$SCRIPT_DIR/../translations"

echo "Installing NTFS Manager Language Packs..."
echo ""

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Count translation files
total_files=$(ls -1 "$TRANSLATIONS_DIR"/*.json 2>/dev/null | wc -l)

if [ "$total_files" -eq 0 ]; then
    echo "Error: No translation files found in $TRANSLATIONS_DIR"
    exit 1
fi

echo "Found $total_files language translation files"
echo ""

# Copy all translation files
installed=0
for translation_file in "$TRANSLATIONS_DIR"/*.json; do
    if [ -f "$translation_file" ]; then
        filename=$(basename "$translation_file")
        cp "$translation_file" "$INSTALL_DIR/"
        echo "✓ Installed: $filename"
        ((installed++))
    fi
done

echo ""
echo "================================================"
echo "✓ Successfully installed $installed language packs"
echo "================================================"
echo ""
echo "Installed to: $INSTALL_DIR"
echo ""
echo "Available languages:"
ls -1 "$INSTALL_DIR"/*.json | sed 's|.*/||' | sed 's/.json//' | sed 's/^/  - /'
echo ""
echo "To use a specific language:"
echo "  export LANG=<language_code>_*.UTF-8"
echo "  ntfs-manager"
echo ""
echo "Examples:"
echo "  LANG=es_ES.UTF-8 ntfs-manager  # Spanish"
echo "  LANG=fr_FR.UTF-8 ntfs-manager  # French"
echo "  LANG=de_DE.UTF-8 ntfs-manager  # German"
