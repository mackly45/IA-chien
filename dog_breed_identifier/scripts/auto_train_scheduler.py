#!/usr/bin/env python
"""
Script pour l'entraînement automatique périodique du modèle.
Ce script peut être exécuté via cron, une tâche planifiée, ou un service cloud.
"""

import os
import sys
import django
from django.conf import settings

# Ajouter le répertoire du projet au chemin Python
project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(project_dir)

# Configurer Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
django.setup()

from classifier.management.commands.auto_train import Command

def run_auto_training():
    """Exécute l'entraînement automatique"""
    print("Démarrage de l'entraînement automatique...")
    
    try:
        # Créer une instance de la commande
        command = Command()
        
        # Exécuter la commande avec des options par défaut
        from django.core.management.base import CommandParser
        parser = CommandParser()
        command.add_arguments(parser)
        
        # Simuler les options de ligne de commande
        options = {
            'images_per_breed': 3,
            'force': False
        }
        
        # Exécuter la commande
        command.handle(**options)
        
        print("Entraînement automatique terminé avec succès.")
        
    except Exception as e:
        print(f"Erreur lors de l'entraînement automatique: {e}")
        sys.exit(1)

if __name__ == "__main__":
    run_auto_training()