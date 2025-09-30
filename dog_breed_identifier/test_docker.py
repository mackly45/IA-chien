#!/usr/bin/env python3
"""
Script pour tester la configuration Docker localement
"""

import os
import subprocess
import sys

def test_docker_build():
    """Teste la construction de l'image Docker"""
    print("🔍 Test de la construction de l'image Docker...")
    
    try:
        # Teste si Docker est disponible
        result = subprocess.run(['docker', '--version'], 
                              capture_output=True, text=True)
        if result.returncode != 0:
            print("❌ Docker n'est pas installé ou n'est pas accessible")
            return False
            
        print(f"✅ Docker est disponible : {result.stdout.strip()}")
        
        # Teste la construction de l'image
        print("🏗️  Construction de l'image Docker...")
        result = subprocess.run(['docker', 'build', '-t', 'dog-breed-test', '.'], 
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Image Docker construite avec succès")
            return True
        else:
            print("❌ Erreur lors de la construction de l'image Docker")
            print(f"📝 Erreur : {result.stderr}")
            return False
            
    except FileNotFoundError:
        print("❌ Docker n'est pas installé")
        return False

def test_python_imports():
    """Teste les imports Python"""
    print("\n🔍 Test des imports Python...")
    
    try:
        # Teste l'import de Django
        import django
        print(f"✅ Django importé avec succès : version {django.get_version()}")
        
        # Teste l'import du module dog_identifier
        import dog_identifier
        print("✅ Module dog_identifier importé avec succès")
        
        # Teste l'import du WSGI
        from dog_identifier import wsgi
        print("✅ Module WSGI importé avec succès")
        
        return True
        
    except ImportError as e:
        print(f"❌ Erreur d'import : {e}")
        return False

def test_directory_structure():
    """Vérifie la structure des répertoires"""
    print("\n🔍 Vérification de la structure des répertoires...")
    
    required_files = [
        'Dockerfile',
        'requirements.txt',
        'dog_identifier/',
        'dog_identifier/wsgi.py',
        'dog_identifier/settings.py'
    ]
    
    all_good = True
    for file_path in required_files:
        if os.path.exists(file_path):
            print(f"✅ {file_path} trouvé")
        else:
            print(f"❌ {file_path} manquant")
            all_good = False
    
    return all_good

def main():
    """Fonction principale"""
    print("🚀 Tests de configuration pour le déploiement Docker\n")
    
    tests = [
        test_directory_structure,
        test_python_imports,
        test_docker_build
    ]
    
    results = []
    for test in tests:
        results.append(test())
    
    print("\n📊 Résumé des tests :")
    if all(results):
        print("✅ Tous les tests ont réussi !")
        print("🟢 Vous pouvez maintenant déployer sur Render")
        return 0
    else:
        print("❌ Certains tests ont échoué")
        print("🔴 Veuillez corriger les problèmes avant de déployer")
        return 1

if __name__ == "__main__":
    sys.exit(main())