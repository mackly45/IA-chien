#!/usr/bin/env python3
"""
Script pour mettre à jour automatiquement le numéro de version
"""

import os
import subprocess
from datetime import datetime

def get_current_version():
    """Récupère la version actuelle depuis le fichier VERSION"""
    try:
        with open('VERSION', 'r') as f:
            return f.read().strip()
    except FileNotFoundError:
        return '1.0.0'

def increment_version(version):
    """Incrémente le numéro de version"""
    parts = version.split('.')
    # Incrémente le dernier numéro
    parts[-1] = str(int(parts[-1]) + 1)
    return '.'.join(parts)

def update_version_file(version):
    """Met à jour le fichier VERSION"""
    with open('VERSION', 'w') as f:
        f.write(version)

def update_readme(version):
    """Met à jour le numéro de version dans le README.md"""
    try:
        with open('README.md', 'r') as f:
            content = f.read()
        
        # Remplace la ligne de version
        import re
        content = re.sub(r'## Version .*', f'## Version {version}', content)
        
        with open('README.md', 'w') as f:
            f.write(content)
    except FileNotFoundError:
        print("README.md non trouvé")

def main():
    """Fonction principale"""
    current_version = get_current_version()
    print(f"Version actuelle : {current_version}")
    
    new_version = increment_version(current_version)
    print(f"Nouvelle version : {new_version}")
    
    update_version_file(new_version)
    update_readme(new_version)
    
    print(f"Version mise à jour vers {new_version}")

if __name__ == '__main__':
    main()