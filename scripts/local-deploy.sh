#!/bin/bash

# Script de déploiement local

PORT=8000
DEV_MODE=false
BACKGROUND=false

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -d|--dev)
            DEV_MODE=true
            shift
            ;;
        -b|--background)
            BACKGROUND=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-p port] [-d] [-b]"
            echo "  -p, --port PORT      Port d'écoute (défaut: 8000)"
            echo "  -d, --dev            Mode développement avec docker-compose"
            echo "  -b, --background     Lancer en arrière-plan"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mDéploiement local de Dog Breed Identifier\033[0m"
echo -e "\033[1;36m======================================\033[0m"

# Vérifier les prérequis
echo -e "\033[1;33mVérification des prérequis...\033[0m"

if ! command -v docker &> /dev/null; then
    echo -e "\033[1;31m❌ Docker n'est pas installé\033[0m"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "\033[1;31m❌ Docker Compose n'est pas installé\033[0m"
    exit 1
fi

# Construire l'image Docker
echo -e "\033[1;33mConstruction de l'image Docker...\033[0m"
if [ "$DEV_MODE" = true ]; then
    if docker-compose build web; then
        echo -e "\033[1;32m✅ Image Docker construite avec succès\033[0m"
    else
        echo -e "\033[1;31m❌ Échec de la construction de l'image Docker\033[0m"
        exit 1
    fi
else
    if docker build -t dog-breed-identifier .; then
        echo -e "\033[1;32m✅ Image Docker construite avec succès\033[0m"
    else
        echo -e "\033[1;31m❌ Échec de la construction de l'image Docker\033[0m"
        exit 1
    fi
fi

# Lancer l'application
echo -e "\033[1;33mLancement de l'application...\033[0m"

if [ "$BACKGROUND" = true ]; then
    DETACHED="-d"
else
    DETACHED=""
fi

if [ "$DEV_MODE" = true ]; then
    RUN_CMD="docker-compose up $DETACHED"
else
    if [ "$BACKGROUND" = true ]; then
        RUN_CMD="docker run -d -p ${PORT}:8000 dog-breed-identifier"
    else
        RUN_CMD="docker run -p ${PORT}:8000 dog-breed-identifier"
    fi
fi

echo -e "\033[1;33mExécution: $RUN_CMD\033[0m"

if eval $RUN_CMD; then
    echo -e "\033[1;32m✅ Application lancée avec succès !\033[0m"
    if [ "$BACKGROUND" = false ]; then
        echo -e "\033[1;37mApplication accessible sur http://localhost:$PORT\033[0m"
    else
        echo -e "\033[1;37mApplication lancée en arrière-plan sur http://localhost:$PORT\033[0m"
    fi
else
    echo -e "\033[1;31m❌ Échec du lancement de l'application\033[0m"
    exit 1
fi

# Afficher les logs si en mode développement
if [ "$DEV_MODE" = true ] && [ "$BACKGROUND" = false ]; then
    echo -e "\033[1;33mAffichage des logs...\033[0m"
    docker-compose logs -f
fi

echo -e "\033[1;36mDéploiement local terminé !\033[0m"