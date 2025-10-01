#!/usr/bin/env python3
"""
Tests pour vérifier la construction et l'exécution du conteneur Docker.
"""

import subprocess
import unittest
import time
import requests

class DockerBuildTest(unittest.TestCase):
    """Tests pour la construction Docker."""
    
    def test_docker_build(self):
        """Teste la construction de l'image Docker."""
        result = subprocess.run(
            ['docker', 'build', '-t', 'dog-breed-identifier-test', '.'],
            capture_output=True,
            text=True
        )
        # Print stdout and stderr for better debugging
        if result.returncode != 0:
            print("Docker build stdout:", result.stdout)
            print("Docker build stderr:", result.stderr)
        self.assertEqual(result.returncode, 0, f"Échec de la construction Docker: {result.stderr}")
    
    def test_docker_run(self):
        """Teste l'exécution du conteneur Docker."""
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
        if result.returncode != 0:
            print("Docker run stdout:", result.stdout)
            print("Docker run stderr:", result.stderr)
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