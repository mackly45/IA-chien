#!/bin/bash

# Script de nettoyage pour le projet

echo -e "\033[1;36mNettoyage du projet Dog Breed Identifier\033[0m"
echo -e "\033[1;36m=====================================\033[0m"

# Arrêter et supprimer les conteneurs
echo -e "\033[1;33mArrêt des conteneurs...\033[0m"
docker-compose down 2>/dev/null

# Supprimer les images Docker
echo -e "\033[1;33mSuppression des images Docker...\033[0m"
docker rmi dog-breed-identifier 2>/dev/null
docker rmi dog-breed-identifier-test 2>/dev/null

# Nettoyer les volumes Docker
echo -e "\033[1;33mNettoyage des volumes Docker...\033[0m"
docker volume prune -f 2>/dev/null

# Supprimer les fichiers de cache Python
echo -e "\033[1;33mSuppression des fichiers de cache Python...\033[0m"
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true

# Supprimer les fichiers de test media
echo -e "\033[1;33mSuppression des fichiers de test media...\033[0m"
if [ -d "tests/test_media" ]; then
    rm -rf tests/test_media
fi

echo -e "\033[1;32mNettoyage terminé !\033[0m"