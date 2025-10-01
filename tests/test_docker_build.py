#!/usr/bin/env python3
"""
Tests pour vérifier la construction et l'exécution du conteneur Docker.
"""

import subprocess
import unittest
import time
import os
# import requests  # Unused import - commenting out
# import shutil  # Unused import - commenting out

class DockerBuildTest(unittest.TestCase):
    """Tests pour la construction Docker."""
    
    def test_docker_build(self):
        """Teste la construction de l'image Docker."""
        # Change to the project root directory
        project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        print(f"Project root: {project_root}")
        
        # Ensure static directory exists
        static_dir = os.path.join(project_root, 'dog_breed_identifier', 'static')
        if not os.path.exists(static_dir):
            os.makedirs(static_dir)
            print(f"Created static directory: {static_dir}")
        
        result = subprocess.run(
            ['docker', 'build', '-t', 'dog-breed-identifier-test', '.'],
            cwd=project_root,
            capture_output=True,
            text=True
        )
        # Print stdout and stderr for better debugging
        print("Docker build return code:", result.returncode)
        print("Docker build stdout:", result.stdout)
        print("Docker build stderr:", result.stderr)
        print("Docker build combined output:")
        print(result.stdout + result.stderr)
        
        self.assertEqual(result.returncode, 0, f"Échec de la construction Docker: {result.stderr}")
    
    def test_docker_run_debug(self):
        """Teste l'exécution du conteneur Docker en mode debug."""
        # Check if image exists
        check_image = subprocess.run(
            ['docker', 'images', 'dog-breed-identifier-test'],
            capture_output=True,
            text=True
        )
        print("Docker images output:", check_image.stdout)
        
        # If image doesn't exist, skip this test
        if "dog-breed-identifier-test" not in check_image.stdout:
            self.skipTest("Docker image not found, skipping run test")
        
        # Arrêter et supprimer le conteneur s'il existe déjà
        _ = subprocess.run(['docker', 'stop', 'dog-breed-identifier-test'], capture_output=True)  # Assign to _
        _ = subprocess.run(['docker', 'rm', 'dog-breed-identifier-test'], capture_output=True)  # Assign to _
        
        # Lancer le conteneur en mode debug pour 10 seconds
        print("Starting container in debug mode for 10 seconds...")
        result = subprocess.Popen([
            'docker', 'run', '-d', 
            '--name', 'dog-breed-identifier-test',
            '-p', '8001:8000',
            'dog-breed-identifier-test'
        ])
        _ = result  # Use result to avoid unused variable warning
        
        # Give it time to start
        time.sleep(5)
        
        # Check container logs
        logs_result = subprocess.run([
            'docker', 'logs', 'dog-breed-identifier-test'
        ], capture_output=True, text=True)
        print("Container logs:", logs_result.stdout)
        if logs_result.stderr:
            print("Container logs stderr:", logs_result.stderr)
        _ = logs_result  # Use logs_result to avoid unused variable warning
        
        # Check if container is running
        ps_result = subprocess.run([
            'docker', 'ps', 
            '--filter', 'name=dog-breed-identifier-test',
            '--format', '{{.Names}}'
        ], capture_output=True, text=True)
        print("Running containers:", ps_result.stdout)
        _ = ps_result  # Use ps_result to avoid unused variable warning
        
        # Wait a bit more
        time.sleep(5)
        
        # Check logs again
        logs_result2 = subprocess.run([
            'docker', 'logs', 'dog-breed-identifier-test'
        ], capture_output=True, text=True)
        print("Container logs (after waiting):", logs_result2.stdout)
        if logs_result2.stderr:
            print("Container logs stderr (after waiting):", logs_result2.stderr)
        _ = logs_result2  # Use logs_result2 to avoid unused variable warning
        
        # Check if container is still running
        ps_result2 = subprocess.run([
            'docker', 'ps', 
            '--filter', 'name=dog-breed-identifier-test',
            '--format', '{{.Names}}'
        ], capture_output=True, text=True)
        print("Running containers (after waiting):", ps_result2.stdout)
        _ = ps_result2  # Use ps_result2 to avoid unused variable warning
        
        # Nettoyer
        _ = subprocess.run(['docker', 'stop', 'dog-breed-identifier-test'], capture_output=True)  # Assign to _
        _ = subprocess.run(['docker', 'rm', 'dog-breed-identifier-test'], capture_output=True)  # Assign to _

if __name__ == '__main__':
    unittest.main()