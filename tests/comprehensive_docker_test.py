#!/usr/bin/env python3
"""
Comprehensive Docker test to diagnose container issues.
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

def test_docker_comprehensive() -> bool:
    """Comprehensive Docker test."""
    print("=" * 50)
    print("COMPREHENSIVE DOCKER TEST")
    print("=" * 50)
    
    # Get project root
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print(f"Project root: {project_root}")
    
    # Test 1: Docker info
    print("\n1. Docker info:")
    _ = run_command(['docker', 'info'])  # Assign to _ to avoid unused result warning
    
    # Test 2: Build Docker image
    print("\n2. Building Docker image:")
    build_result = run_command(['docker', 'build', '-t', 'comprehensive-test', '.'], timeout=120)
    if not build_result or build_result.returncode != 0:
        print("Failed to build Docker image")
        return False
    
    # Test 3: Run container and check immediately
    print("\n3. Running container:")
    run_result = run_command([
        'docker', 'run', '-d', '--name', 'comprehensive-test-container', 
        '-p', '8002:8000', 'comprehensive-test', 'python', '--version'
    ])
    
    if not run_result or run_result.returncode != 0:
        print("Failed to start container")
        return False
    
    # Wait a moment
    time.sleep(2)
    
    # Test 4: Check if container is running
    print("\n4. Checking container status:")
    _ = run_command(['docker', 'ps', '--filter', 'name=comprehensive-test-container'])  # Assign to _
    
    # Test 5: Check container logs
    print("\n5. Container logs:")
    _ = run_command(['docker', 'logs', 'comprehensive-test-container'])  # Assign to _
    
    # Test 6: Run a more complex command
    print("\n6. Running health check:")
    _ = run_command([
        'docker', 'run', '--rm', 'comprehensive-test', 
        'python', '-c', 'import sys; print("Python works!"); print(sys.version)'
    ])  # Assign to _
    
    # Cleanup
    print("\n7. Cleaning up:")
    _ = run_command(['docker', 'stop', 'comprehensive-test-container'])  # Assign to _
    _ = run_command(['docker', 'rm', 'comprehensive-test-container'])  # Assign to _
    _ = run_command(['docker', 'rmi', 'comprehensive-test'])  # Assign to _
    
    print("\n" + "=" * 50)
    print("COMPREHENSIVE TEST COMPLETE")
    print("=" * 50)
    
    return True

if __name__ == "__main__":
    success = test_docker_comprehensive()
    sys.exit(0 if success else 1)