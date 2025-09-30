#!/bin/bash

# Script de déploiement automatique
echo "Début du déploiement automatique..."

# Mise à jour du numéro de version
echo "Mise à jour du numéro de version..."
python scripts/update_version.py

# Récupération de la nouvelle version
VERSION=$(cat VERSION)
echo "Version actuelle : $VERSION"

# Ajout des fichiers modifiés
echo "Ajout des fichiers modifiés..."
git add .

# Commit avec message automatique
echo "Création du commit..."
git commit -m "Mise à jour automatique de la version : $VERSION - $(date)"

# Push vers le dépôt distant
echo "Push vers le dépôt distant..."
git push origin main

echo "Déploiement terminé ! La nouvelle version $VERSION est en cours de déploiement."