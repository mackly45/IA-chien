#!/usr/bin/env python3
"""
Test to verify that Django project can be imported correctly.
"""

import os
import sys

def test_django_import():
    """Test that Django can be imported and configured."""
    # Add the project directory to Python path
    project_dir = os.path.join(os.path.dirname(__file__), '..', 'dog_breed_identifier')
    sys.path.insert(0, project_dir)
    
    try:
        import django
        from django.conf import settings
        
        # Set the settings module
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
        
        # Try to setup Django
        django.setup()
        
        # Verify we can import the main module
        import dog_identifier
        print("✓ Django project imported successfully")
        print(f"  Django version: {django.get_version()}")
        print(f"  Settings module: {os.environ.get('DJANGO_SETTINGS_MODULE')}")
        
        return True
    except Exception as e:
        print(f"✗ Failed to import Django project: {e}")
        return False

if __name__ == "__main__":
    success = test_django_import()
    sys.exit(0 if success else 1)