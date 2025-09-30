#!/usr/bin/env python
"""
Script de vérification de santé pour Render
"""
import os
import sys
import django
from django.conf import settings

# Ajouter le répertoire du projet au chemin Python
sys.path.append('/app/dog_breed_identifier')

# Configurer Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
django.setup()

def check_health():
    """Vérifier la santé de l'application"""
    try:
        # Vérifier que Django peut se charger
        from django.db import connection
        from django.core.management import execute_from_command_line
        
        # Vérifier la connexion à la base de données
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