# NTFS Manager Test Suite

## Overview

This directory contains the test suite for NTFS Manager.

## Test Structure

- `__init__.py` - Test suite initialization
- `test_drive_manager.py` - Drive management tests (to be added)
- `test_ntfs_properties.py` - NTFS properties tests (to be added)
- `test_integration.py` - Integration tests (to be added)

## Running Tests

```bash
# Install test dependencies
pip3 install pytest pytest-cov --user

# Run all tests
python3 -m pytest tests/

# Run with coverage
python3 -m pytest --cov=backend tests/
```

## Test Categories

### Unit Tests
- Drive detection logic
- Mount/unmount operations
- NTFS property parsing
- Error handling

### Integration Tests
- Full mount/unmount cycle
- Nautilus extension loading
- GUI functionality
- System integration

## Contributing

When adding new features, please include corresponding tests.

---

**Test Suite Version:** 3.0.0
