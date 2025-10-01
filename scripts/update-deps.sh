#!/bin/bash

# Script de mise à jour des dépendances

DEV=false
LOCK=false
UPGRADE=false

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dev)
            DEV=true
            shift
            ;;
        -l|--lock)
            LOCK=true
            shift
            ;;
        -u|--upgrade)
            UPGRADE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-d] [-l] [-u]"
            echo "  -d, --dev      Mettre à jour les dépendances de développement"
            echo "  -l, --lock     Générer le fichier de verrouillage"
            echo "  -u, --upgrade  Mettre à jour toutes les dépendances"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mMise à jour des dépendances\033[0m"
echo -e "\033[1;36m========================\033[0m"

# Vérifier que pip est installé
if ! command -v pip &> /dev/null; then
    echo -e "\033[1;31m❌ pip n'est pas installé\033[0m"
    exit 1
fi

# Mise à jour de pip
echo -e "\033[1;33mMise à jour de pip...\033[0m"
pip install --upgrade pip

# Mise à jour des dépendances principales
echo -e "\033[1;33mMise à jour des dépendances principales...\033[0m"
if [ "$UPGRADE" = true ]; then
    pip install --upgrade -r requirements.txt
else
    pip install -r requirements.txt
fi

if [ $? -ne 0 ]; then
    echo -e "\033[1;31m❌ Échec de la mise à jour des dépendances principales\033[0m"
    exit 1
fi

# Mise à jour des dépendances de développement
if [ "$DEV" = true ]; then
    echo -e "\033[1;33mMise à jour des dépendances de développement...\033[0m"
    if [ "$UPGRADE" = true ]; then
        pip install --upgrade -r dev-requirements.txt
    else
        pip install -r dev-requirements.txt
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "\033[1;31m❌ Échec de la mise à jour des dépendances de développement\033[0m"
        exit 1
    fi
fi

# Génération du fichier de verrouillage
if [ "$LOCK" = true ]; then
    echo -e "\033[1;33mGénération du fichier de verrouillage...\033[0m"
    pip freeze > requirements-lock.txt
    
    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m✅ Fichier de verrouillage généré: requirements-lock.txt\033[0m"
    else
        echo -e "\033[1;31m❌ Échec de la génération du fichier de verrouillage\033[0m"
        exit 1
    fi
fi

echo -e "\033[1;36mMise à jour des dépendances terminée !\033[0m"