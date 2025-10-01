#!/usr/bin/env python3
"""
Simple Docker test to verify container startup.
"""

import subprocess
import time

def test_simple_docker_run():
    """Test a simple Docker run command."""
    # Build the image
    print("Building Docker image...")
    build_result = subprocess.run(
        ['docker', 'build', '-t', 'simple-test', '.'],
        capture_output=True,
        text=True
    )
    
    if build_result.returncode != 0:
        print("Build failed:")
        print(build_result.stdout)
        print(build_result.stderr)
        return False
    
    print("Build successful!")
    
    # Try to run a simple command in the container
    print("Running simple command in container...")
    run_result = subprocess.run([
        'docker', 'run', '--rm', 'simple-test', 'python', '--version'
    ], capture_output=True, text=True)
    
    print("Return code:", run_result.returncode)
    print("Stdout:", run_result.stdout)
    print("Stderr:", run_result.stderr)
    
    if run_result.returncode == 0:
        print("Simple command test passed!")
        return True
    else:
        print("Simple command test failed!")
        return False

if __name__ == "__main__":
    test_simple_docker_run()