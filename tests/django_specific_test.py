#!/usr/bin/env python3
"""
Django specific test to diagnose container issues.
"""

import subprocess
import time
import sys
import os
from typing import List, Optional

def run_command(cmd: List[str], timeout: int = 30) -> Optional[subprocess.CompletedProcess[str]]:
    """Run a command and return the result."""
    print(f"Running: {' '.join(cmd)}")
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        print(f"Return code: {result.returncode}")
        if result.stdout:
            print(f"Stdout:\n{result.stdout}")
        if result.stderr:
            print(f"Stderr:\n{result.stderr}")
        return result
    except subprocess.TimeoutExpired:
        print(f"Command timed out after {timeout} seconds")
        return None
    except Exception as e:
        print(f"Error running command: {e}")
        return None

def test_django_container() -> bool:
    """Test Django container specifically."""
    print("=" * 50)
    print("DJANGO CONTAINER TEST")
    print("=" * 50)
    
    # Get project root
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print(f"Project root: {project_root}")
    
    # Build the main Docker image
    print("\n1. Building main Docker image:")
    build_result = run_command(['docker', 'build', '-t', 'django-test', '.'], timeout=120)
    if not build_result or build_result.returncode != 0:
        print("Failed to build Docker image")
        return False
    
    # Test the actual Django application startup
    print("\n2. Testing Django application startup:")
    # Run the container with the actual Django command but with a timeout
    run_result = subprocess.Popen([
        'docker', 'run', '--name', 'django-test-container', 
        '-p', '8003:8000', 'django-test'
    ])
    
    # Give it time to start
    print("Waiting 10 seconds for Django to start...")
    time.sleep(10)
    
    # Check if container is still running
    print("\n3. Checking container status:")
    _ = run_command(['docker', 'ps', '--filter', 'name=django-test-container'])  # Assign to _
    
    # Check container logs
    print("\n4. Container logs:")
    _ = run_command(['docker', 'logs', 'django-test-container'])  # Assign to _
    
    # Stop and remove container
    print("\n5. Stopping container:")
    _ = run_command(['docker', 'stop', 'django-test-container'])  # Assign to _
    _ = run_command(['docker', 'rm', 'django-test-container'])  # Assign to _
    
    # Test with a simple Django command instead
    print("\n6. Testing Django check command:")
    check_result = run_command([
        'docker', 'run', '--rm', '-w', '/app/dog_breed_identifier', 
        'django-test', 'python', 'manage.py', 'check'
    ], timeout=30)
    _ = check_result  # Use the result to avoid unused variable warning
    
    # Cleanup
    print("\n7. Cleaning up image:")
    _ = run_command(['docker', 'rmi', '-f', 'django-test'])  # Assign to _
    
    print("\n" + "=" * 50)
    print("DJANGO CONTAINER TEST COMPLETE")
    print("=" * 50)
    
    return True

if __name__ == "__main__":
    success = test_django_container()
    sys.exit(0 if success else 1)