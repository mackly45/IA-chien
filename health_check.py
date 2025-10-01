#!/usr/bin/env python3
"""
Script de vérification de la santé de l'application.
"""

import os
import sys
import django
from django.core.management import execute_from_command_line

# Configuration de Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
django.setup()

def check_database():
    """Vérifie la connexion à la base de données."""
    try:
        from django.db import connection
        connection.ensure_connection()
        return True
    except Exception as e:
        print(f"Erreur de connexion à la base de données: {e}")
        return False

def check_ml_model():
    """Vérifie que le modèle ML est disponible."""
    try:
        # Ajoutez ici la vérification de votre modèle ML
        # Par exemple, vérifier que le fichier du modèle existe
        model_path = os.path.join(os.path.dirname(__file__), 'ml_models', 'dog_breed_model.h5')
        return os.path.exists(model_path)
    except Exception as e:
        print(f"Erreur avec le modèle ML: {e}")
        return False

def main():
    """Point d'entrée principal."""
    print("Vérification de la santé de l'application...")
    
    # Vérifier la base de données
    if not check_database():
        print("❌ Échec de la vérification de la base de données")
        sys.exit(1)
    
    print("✅ Base de données OK")
    
    # Vérifier le modèle ML
    if not check_ml_model():
        print("❌ Échec de la vérification du modèle ML")
        sys.exit(1)
    
    print("✅ Modèle ML OK")
    print("✅ Tous les systèmes sont opérationnels")

if __name__ == '__main__':
    main()