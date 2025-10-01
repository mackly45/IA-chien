#!/usr/bin/env python3
"""
Simple Docker test to verify basic functionality.
"""

import subprocess
import sys

def test_simple_docker_run():
    """Test simple Docker run command."""
    print("Building Docker image...")
    
    # Build Docker image
    build_result = subprocess.run([
        'docker', 'build', '-t', 'simple-test', '.'
    ], capture_output=True, text=True)
    
    if build_result.returncode != 0:
        print(f"Build failed: {build_result.stderr}")
        return False
    
    print("Build successful!")
    
    # Run simple command in container
    print("Running simple command in container...")
    run_result = subprocess.run([
        'docker', 'run', '--rm', 'simple-test', 'python', '--version'
    ], capture_output=True, text=True)
    
    print(f"Return code: {run_result.returncode}")
    print(f"Stdout: {run_result.stdout}")
    print(f"Stderr: {run_result.stderr}")
    
    if run_result.returncode == 0:
        print("Simple command test passed!")
        return True
    else:
        print("Simple command test failed!")
        return False

def test_simple_docker_run_pytest():
    """Pytest version of simple Docker run test."""
    assert test_simple_docker_run() is True

if __name__ == "__main__":
    success = test_simple_docker_run()
    sys.exit(0 if success else 1)