#!/bin/bash
# Script pour exécuter l'entraînement automatique du modèle

# Définir le répertoire du projet
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Se déplacer dans le répertoire du projet
cd "$PROJECT_DIR"

# Activer l'environnement virtuel si disponible
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
fi

# Exécuter l'entraînement automatique
echo "Exécution de l'entraînement automatique..."
python manage.py auto_train --images-per-breed 3

echo "Entraînement automatique terminé."