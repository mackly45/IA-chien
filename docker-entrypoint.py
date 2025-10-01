#!/usr/bin/env python3
"""
Docker entrypoint script for debugging.
"""

import os
import sys
# import subprocess  # Unused import - commenting out
import time

def main():
    """Main entrypoint function."""
    print("Docker entrypoint script started")
    print(f"Working directory: {os.getcwd()}")
    print(f"User: {os.getuid() if hasattr(os, 'getuid') else 'N/A'}")
    
    # List files in current directory
    print("Files in current directory:")
    for file in os.listdir('.'):
        print(f"  {file}")
    
    # Check if we're in the right directory
    if not os.path.exists('manage.py'):
        print("Warning: manage.py not found in current directory")
    
    # Check environment variables
    print("Environment variables:")
    for key in ['PORT', 'PYTHONPATH', 'DJANGO_SETTINGS_MODULE']:
        value = os.environ.get(key, 'Not set')
        print(f"  {key}: {value}")
    
    # If we're running in debug mode
    if len(sys.argv) > 1 and sys.argv[1] == 'debug':
        print("Running in debug mode - starting shell")
        # Assign result to _ to avoid unused call result warning
        _ = os.system('/bin/bash')
        return
    
    # Otherwise, run the normal command
    print("Starting application...")
    # This would normally be where we start the Django application
    # For now, we'll just keep the container running for debugging
    try:
        while True:
            time.sleep(60)
    except KeyboardInterrupt:
        print("Container stopped")

if __name__ == "__main__":
    main()