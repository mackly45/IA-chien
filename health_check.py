#!/usr/bin/env python
"""
Health check script for Render deployment
"""
import os
import sys
import django
from django.conf import settings

# Add project directory to Python path
sys.path.append('/app/dog_breed_identifier')

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
django.setup()

def check_health():
    """Check application health"""
    try:
        # Check that Django can load
        from django.db import connection
        
        # Check database connection
        connection.ensure_connection()
        
        print("Health check passed")
        return True
    except Exception as e:
        print(f"Health check failed: {e}")
        return False

if __name__ == "__main__":
    if check_health():
        sys.exit(0)
    else:
        sys.exit(1)