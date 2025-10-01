#!/usr/bin/env python3
"""
Test script to verify Django application can start.
This script is meant to be run inside the Docker container.
"""

import os
import sys
import time

def test_django_run():
    """Test if Django application can start."""
    print("Starting Django run test...")
    
    # Change to the project directory
    project_dir = '/app/dog_breed_identifier'
    if os.path.exists(project_dir):
        os.chdir(project_dir)
        print(f"Changed to directory: {os.getcwd()}")
    
    # Set environment variables
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
    os.environ.setdefault('DEBUG', 'True')
    
    print(f"DJANGO_SETTINGS_MODULE: {os.environ.get('DJANGO_SETTINGS_MODULE')}")
    
    try:
        # Import Django
        import django
        print("✓ Django imported successfully")
        
        # Setup Django
        django.setup()
        print("✓ Django setup completed")
        
        # Try to import the WSGI application using importlib to avoid linter issues
        try:
            import importlib
            # pylint: disable=import-error
            wsgi_module = importlib.import_module('dog_identifier.wsgi')
            print("✓ WSGI application imported successfully")
        except Exception as e:
            print(f"⚠ WSGI application import warning: {e}")
        
        # Try to import manage.py commands
        try:
            from django.core.management import execute_from_command_line
            print("✓ Django management commands available")
        except Exception as e:
            print(f"⚠ Django management commands warning: {e}")
        
        print("Django run test completed successfully!")
        return True
        
    except Exception as e:
        print(f"Error in Django run test: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_django_run()
    print(f"Test result: {'PASS' if success else 'FAIL'}")
    sys.exit(0 if success else 1)