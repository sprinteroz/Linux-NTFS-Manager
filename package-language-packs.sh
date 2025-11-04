#!/bin/bash
# Package Language Packs for Distribution

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/dist"
PACKAGE_NAME="NTFS-Manager-Language-Packs-v1.0.1"

echo "=========================================="
echo "  NTFS Manager Language Pack Packager"
echo "=========================================="
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create package directory
PACKAGE_DIR="$OUTPUT_DIR/$PACKAGE_NAME"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

echo "Copying files..."

# Copy translations
cp -r translations "$PACKAGE_DIR/"
echo "✓ Copied 32 translation files"

# Copy language-packs directory
cp -r language-packs "$PACKAGE_DIR/"
echo "✓ Copied language pack installers"

# Copy i18n module
mkdir -p "$PACKAGE_DIR/backend"
cp ntfs-manager-production/backend/i18n.py "$PACKAGE_DIR/backend/"
echo "✓ Copied i18n integration module"

# Copy documentation
cp language-packs/README.md "$PACKAGE_DIR/"
echo "✓ Copied README"

# Create tarball
echo ""
echo "Creating tarball..."
cd "$OUTPUT_DIR"
tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"

# Create checksum
sha256sum "${PACKAGE_NAME}.tar.gz" > "${PACKAGE_NAME}.tar.gz.sha256"

cd "$SCRIPT_DIR"

SIZE=$(du -h "$OUTPUT_DIR/${PACKAGE_NAME}.tar.gz" | cut -f1)

echo ""
echo "=========================================="
echo "✓ Language Pack Created Successfully!"
echo "=========================================="
echo ""
echo "Package: ${PACKAGE_NAME}.tar.gz ($SIZE)"
echo "Location: $OUTPUT_DIR"
echo ""
echo "SHA256:"
cat "$OUTPUT_DIR/${PACKAGE_NAME}.tar.gz.sha256"
echo ""
echo "Contents:"
echo "  - 32 language translation files"
echo "  - Installation scripts"
echo "  - i18n integration module"
echo "  - Documentation"
echo ""
echo "Ready for distribution!"
