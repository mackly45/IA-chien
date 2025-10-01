#!/usr/bin/env python3
"""
Test script to verify that all dependencies work correctly after updates.
"""

import sys
import importlib

def test_import(module_name):
    """Test if a module can be imported."""
    try:
        importlib.import_module(module_name)
        print(f"✓ {module_name} imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Failed to import {module_name}: {e}")
        return False

def test_tensorflow():
    """Test TensorFlow functionality."""
    try:
        import tensorflow as tf
        print(f"✓ TensorFlow version: {tf.__version__}")
        
        # Test basic functionality
        hello = tf.constant('Hello, TensorFlow!')
        print(f"✓ TensorFlow basic operation: {hello}")
        return True
    except Exception as e:
        print(f"✗ TensorFlow test failed: {e}")
        return False

def test_pillow():
    """Test Pillow functionality."""
    try:
        from PIL import Image
        print("✓ Pillow imported successfully")
        
        # Test basic functionality
        img = Image.new('RGB', (100, 100), color='red')
        print("✓ Pillow basic operation completed")
        return True
    except Exception as e:
        print(f"✗ Pillow test failed: {e}")
        return False

def test_numpy():
    """Test NumPy functionality."""
    try:
        import numpy as np
        print(f"✓ NumPy version: {np.__version__}")
        
        # Test basic functionality
        arr = np.array([1, 2, 3, 4, 5])
        print(f"✓ NumPy basic operation: {arr}")
        return True
    except Exception as e:
        print(f"✗ NumPy test failed: {e}")
        return False

def main():
    """Run all dependency tests."""
    print("Testing dependencies after updates...")
    print("=" * 50)
    
    # Test core dependencies
    core_modules = [
        'django',
        'gunicorn',
        'whitenoise',
        'requests',
        'dj_database_url',
        'python_decouple'
    ]
    
    results = []
    
    # Test core modules
    for module in core_modules:
        try:
            result = test_import(module)
            results.append(result)
        except Exception as e:
            print(f"✗ Error testing {module}: {e}")
            results.append(False)
    
    # Test specialized modules
    print("\nTesting specialized modules...")
    results.append(test_tensorflow())
    results.append(test_pillow())
    results.append(test_numpy())
    
    # Summary
    print("\n" + "=" * 50)
    print("DEPENDENCY TEST SUMMARY")
    print("=" * 50)
    
    passed = sum(results)
    total = len(results)
    
    if passed == total:
        print(f"✓ All {total} tests passed!")
        return 0
    else:
        print(f"✗ {passed}/{total} tests passed.")
        return 1

if __name__ == "__main__":
    sys.exit(main())