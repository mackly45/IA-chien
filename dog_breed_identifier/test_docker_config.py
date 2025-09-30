#!/usr/bin/env python3
"""
Test script to validate Docker configuration for the dog breed identifier application.
This script checks if the application can be imported and if the necessary components are available.
"""

import os
import sys
import importlib.util

def test_module_import():
    """Test if the dog_identifier module can be imported."""
    print("Testing dog_identifier module import...")
    try:
        # Add the current directory to Python path
        sys.path.insert(0, os.getcwd())
        
        # Try to import the module
        import dog_identifier
        print("✓ dog_identifier module imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Failed to import dog_identifier module: {e}")
        return False

def test_wsgi_import():
    """Test if the WSGI application can be imported."""
    print("Testing WSGI application import...")
    try:
        from dog_identifier.wsgi import application
        print("✓ WSGI application imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Failed to import WSGI application: {e}")
        return False

def test_settings_import():
    """Test if the settings module can be imported."""
    print("Testing settings module import...")
    try:
        from dog_identifier import settings
        print("✓ Settings module imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Failed to import settings module: {e}")
        return False

def check_directory_structure():
    """Check if the expected directory structure exists."""
    print("Checking directory structure...")
    expected_dirs = ['dog_identifier', 'classifier', 'ml_models']
    missing_dirs = []
    
    for dir_name in expected_dirs:
        if not os.path.isdir(dir_name):
            missing_dirs.append(dir_name)
    
    if missing_dirs:
        print(f"✗ Missing directories: {missing_dirs}")
        return False
    else:
        print("✓ All expected directories present")
        return True

def check_dog_identifier_contents():
    """Check if the dog_identifier directory has the necessary files."""
    print("Checking dog_identifier directory contents...")
    dog_identifier_path = 'dog_identifier'
    if not os.path.isdir(dog_identifier_path):
        print("✗ dog_identifier directory not found")
        return False
    
    required_files = ['__init__.py', 'wsgi.py', 'settings.py', 'urls.py']
    missing_files = []
    
    for file_name in required_files:
        if not os.path.isfile(os.path.join(dog_identifier_path, file_name)):
            missing_files.append(file_name)
    
    if missing_files:
        print(f"✗ Missing files in dog_identifier directory: {missing_files}")
        return False
    else:
        print("✓ All required files present in dog_identifier directory")
        return True

def main():
    """Run all tests."""
    print("Docker Configuration Test Suite")
    print("=" * 40)
    
    tests = [
        check_directory_structure,
        check_dog_identifier_contents,
        test_module_import,
        test_settings_import,
        test_wsgi_import,
    ]
    
    results = []
    for test in tests:
        try:
            result = test()
            results.append(result)
            print()
        except Exception as e:
            print(f"✗ Test {test.__name__} failed with exception: {e}")
            results.append(False)
            print()
    
    print("Test Summary")
    print("=" * 40)
    passed = sum(results)
    total = len(results)
    
    if passed == total:
        print(f"All {total} tests passed! ✓")
        return 0
    else:
        print(f"{passed}/{total} tests passed. ✗")
        return 1

if __name__ == "__main__":
    sys.exit(main())