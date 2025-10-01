#!/usr/bin/env python3
"""
Simple container test script.
"""

import os
import sys
# from django import get_version  # Import causing type issue - commenting out

def test_container():
    """Test container functionality."""
    print("Testing container functionality...")
    
    # Test 1: Check current directory
    print(f"Current directory: {os.getcwd()}")
    
    # Test 2: List files in current directory
    print("Files in current directory:")
    for file in os.listdir('.'):
        print(f"  {file}")
    
    # Test 3: Check if required files exist
    required_files = ['manage.py', 'dog_identifier']
    for file in required_files:
        if os.path.exists(file):
            print(f"✓ {file} found")
        else:
            print(f"✗ {file} not found")
    
    # Test 4: Try to import Django
    try:
        import django
        print(f"✓ Django imported successfully (version {django.get_version()})")
    except ImportError:
        print("✗ Django import failed")
        return False
    
    # Test 5: Try to import settings
    try:
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
        from django.conf import settings
        print("✓ Django settings module found")
        # Use settings to avoid unused variable warning
        _ = settings  # Assign to _ to avoid unused variable warning
    except ImportError:
        print("✗ Django settings module not found")
        return False
    
    print("Container test completed successfully!")
    return True

if __name__ == "__main__":
    success = test_container()
    sys.exit(0 if success else 1)