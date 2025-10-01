#!/usr/bin/env python3
"""
Tests pour vérifier la construction et l'exécution du conteneur Docker.
"""

import subprocess
import unittest
import time
import requests
import os
import shutil

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
        
        # Copy test Dockerfile to main Dockerfile for testing
        test_dockerfile = os.path.join(project_root, 'Dockerfile.test')
        main_dockerfile = os.path.join(project_root, 'Dockerfile')
        
        if os.path.exists(test_dockerfile):
            print("Using test Dockerfile")
            shutil.copy2(test_dockerfile, main_dockerfile)
        
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
        
        # Restore original Dockerfile
        original_dockerfile = os.path.join(project_root, 'Dockerfile.simple')
        if os.path.exists(original_dockerfile):
            shutil.copy2(original_dockerfile, main_dockerfile)
        
        self.assertEqual(result.returncode, 0, f"Échec de la construction Docker: {result.stderr}")
    
    def test_docker_run(self):
        """Teste l'exécution du conteneur Docker."""
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
        subprocess.run(['docker', 'stop', 'dog-breed-identifier-test'], capture_output=True)
        subprocess.run(['docker', 'rm', 'dog-breed-identifier-test'], capture_output=True)
        
        # Lancer le conteneur
        result = subprocess.run([
            'docker', 'run', '-d', 
            '--name', 'dog-breed-identifier-test',
            '-p', '8001:8000',
            'dog-breed-identifier-test'
        ], capture_output=True, text=True)
        
        # Print stdout and stderr for better debugging
        print("Docker run return code:", result.returncode)
        print("Docker run stdout:", result.stdout)
        print("Docker run stderr:", result.stderr)
        print("Docker run combined output:")
        print(result.stdout + result.stderr)
        
        self.assertEqual(result.returncode, 0, f"Échec du lancement du conteneur: {result.stderr}")
        
        # Attendre que le serveur démarre
        time.sleep(10)
        
        # Vérifier que le conteneur est en cours d'exécution
        result = subprocess.run([
            'docker', 'ps', 
            '--filter', 'name=dog-breed-identifier-test',
            '--format', '{{.Names}}'
        ], capture_output=True, text=True)
        
        self.assertIn('dog-breed-identifier-test', result.stdout, "Le conteneur n'est pas en cours d'exécution")
        
        # Nettoyer
        subprocess.run(['docker', 'stop', 'dog-breed-identifier-test'], capture_output=True)
        subprocess.run(['docker', 'rm', 'dog-breed-identifier-test'], capture_output=True)

if __name__ == '__main__':
    unittest.main()