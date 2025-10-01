#!/usr/bin/env python3
"""
Simple test to verify Django application health.
This script is meant to be run inside the Docker container.
"""

import os
import sys

def check_django_health():
    """Check Django application health."""
    print("Starting Django health check...")
    
    try:
        # Set the Django settings module
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
        print(f"DJANGO_SETTINGS_MODULE: {os.environ.get('DJANGO_SETTINGS_MODULE')}")
        
        # Try to import Django
        try:
            import django
            print("✓ Django imported successfully")
            print(f"  Django version: {django.get_version()}")
        except ImportError as e:
            print(f"✗ Django import failed: {e}")
            return False
        
        # Initialize Django
        try:
            django.setup()
            print("✓ Django setup completed")
        except Exception as e:
            print(f"✗ Django setup failed: {e}")
            return False
        
        # Try to import settings
        try:
            from django.conf import settings
            print("✓ Django settings imported")
            print(f"  DEBUG: {settings.DEBUG}")
            print(f"  DATABASES: {list(settings.DATABASES.keys())}")
        except Exception as e:
            print(f"✗ Django settings import failed: {e}")
            return False
        
        # Try to check the configuration
        try:
            issues = settings.check()
            if issues:
                print(f"⚠ Configuration issues found: {len(issues)} issues")
                for i, issue in enumerate(issues[:5]):  # Show first 5 issues
                    print(f"  {i+1}. {issue}")
                if len(issues) > 5:
                    print(f"  ... and {len(issues) - 5} more issues")
            else:
                print("✓ Django settings are valid")
        except Exception as e:
            print(f"⚠ Django settings check failed: {e}")
        
        print("Django application health check completed successfully!")
        return True
        
    except Exception as e:
        print(f"Error in Django health check: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = check_django_health()
    sys.exit(0 if success else 1)