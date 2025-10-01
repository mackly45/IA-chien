#!/usr/bin/env python3
"""
Test script to verify that all dependencies work correctly after updates.
"""

import sys
import importlib
import tensorflow as tf  # type: ignore
import numpy as np  # type: ignore
from typing import Any, Union

def _test_import(module_name):
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
        # Use getattr to avoid pyright warnings about module attributes
        tf_version = getattr(tf, '__version__', 'unknown')
        print(f"✓ TensorFlow version: {tf_version}")
        
        # Test basic functionality
        constant_func = getattr(tf, 'constant', None)
        if constant_func:
            hello = constant_func('Hello, TensorFlow!')  # type: ignore
            print(f"✓ TensorFlow basic operation: {hello}")
        else:
            print("✗ TensorFlow constant function not available")
            return False
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
        # Use getattr to avoid pyright warnings about module attributes
        np_version = getattr(np, '__version__', 'unknown')
        print(f"✓ NumPy version: {np_version}")
        
        # Test basic functionality
        arr = np.array([1, 2, 3, 4, 5])  # type: ignore
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
        'decouple'
    ]
    
    results = []
    
    # Test core modules
    for module in core_modules:
        try:
            result = _test_import(module)
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

# Fonctions de test individuelles pour pytest
def test_django_import():
    """Test Django import."""
    assert _test_import('django')

def test_gunicorn_import():
    """Test Gunicorn import."""
    assert _test_import('gunicorn')

def test_whitenoise_import():
    """Test Whitenoise import."""
    assert _test_import('whitenoise')

def test_requests_import():
    """Test Requests import."""
    assert _test_import('requests')

def test_dj_database_url_import():
    """Test dj_database_url import."""
    assert _test_import('dj_database_url')

def test_python_decouple_import():
    """Test python_decouple import."""
    assert _test_import('decouple')

def test_tensorflow_functionality():
    """Test TensorFlow functionality."""
    assert test_tensorflow()

def test_pillow_functionality():
    """Test Pillow functionality."""
    assert test_pillow()

def test_numpy_functionality():
    """Test NumPy functionality."""
    assert test_numpy()

if __name__ == "__main__":
    sys.exit(main())