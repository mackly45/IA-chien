#!/bin/bash

# Script d'initialisation du déploiement automatique

echo -e "\033[1;36mInitialisation du déploiement automatique pour Dog Breed Identifier\033[0m"
echo -e "\033[1;36m====================================================================\033[0m"

# Vérifier que Docker est installé
echo -e "\033[1;33mVérification de Docker...\033[0m"
if ! command -v docker &> /dev/null; then
    echo -e "\033[1;31mDocker n'est pas installé!\033[0m"
    echo -e "\033[1;33mVeuillez installer Docker Desktop: https://www.docker.com/products/docker-desktop\033[0m"
    exit 1
fi
docker --version

# Vérifier que Git est installé
echo -e "\033[1;33mVérification de Git...\033[0m"
if ! command -v git &> /dev/null; then
    echo -e "\033[1;31mGit n'est pas installé!\033[0m"
    echo -e "\033[1;33mVeuillez installer Git: https://git-scm.com/downloads\033[0m"
    exit 1
fi
git --version

# Créer le fichier .env.local si nécessaire
if [ ! -f ".env.local" ]; then
    echo -e "\033[1;33mCréation du fichier .env.local à partir de .env...\033[0m"
    if [ -f ".env" ]; then
        cp .env .env.local
        echo -e "\033[1;32mFichier .env.local créé. Veuillez le modifier avec vos informations!\033[0m"
        echo -e "\033[1;33mCe fichier est ignoré par Git et ne sera pas commité.\033[0m"
    else
        echo -e "\033[1;31mFichier .env non trouvé!\033[0m"
    fi
fi

# Construire l'image Docker
echo -e "\033[1;33mConstruction de l'image Docker...\033[0m"
docker build -t dog-breed-identifier .

if [ $? -eq 0 ]; then
    echo -e "\033[1;32mImage Docker construite avec succès!\033[0m"
else
    echo -e "\033[1;31mÉchec de la construction de l'image Docker!\033[0m"
    exit 1
fi

# Configuration des variables d'environnement pour GitHub Actions
echo -e "\033[1;33mConfiguration des secrets pour GitHub Actions...\033[0m"
echo -e "\033[1;37mVeuillez ajouter les secrets suivants dans les paramètres de votre dépôt GitHub:\033[0m"
echo -e "\033[1;37m1. DOCKER_USERNAME - Votre nom d'utilisateur Docker Hub\033[0m"
echo -e "\033[1;37m2. DOCKER_PASSWORD - Votre token d'accès personnel Docker Hub\033[0m"
echo -e "\033[1;37m3. RENDER_DEPLOY_HOOK - L'URL du hook de déploiement Render\033[0m"

# Configuration pour Render
echo -e "\n\033[1;33mConfiguration pour Render:\033[0m"
echo -e "\033[1;37m1. Connectez votre dépôt GitHub à Render\033[0m"
echo -e "\033[1;37m2. Render détectera automatiquement le Dockerfile\033[0m"
echo -e "\033[1;37m3. Ajoutez les variables d'environnement dans le dashboard Render\033[0m"

echo -e "\n\033[1;32mInitialisation terminée!\033[0m"
echo -e "\033[1;32mVous pouvez maintenant utiliser './deploy.sh -Auto' pour un déploiement automatique complet.\033[0m"