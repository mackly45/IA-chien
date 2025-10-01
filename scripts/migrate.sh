#!/bin/bash

# Script de migration de base de données

SHOW_SQL=false
FAKE=false
APP=""

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sql)
            SHOW_SQL=true
            shift
            ;;
        --fake)
            FAKE=true
            shift
            ;;
        -a|--app)
            APP="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--sql] [--fake] [-a|--app APP]"
            echo "  --sql          Afficher le SQL qui serait exécuté"
            echo "  --fake         Marquer les migrations comme appliquées sans les exécuter"
            echo "  -a, --app APP  Appliquer les migrations seulement à cette application"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mMigration de la base de données\033[0m"
echo -e "\033[1;36m============================\033[0m"

# Vérifier que Django est installé
if ! command -v python &> /dev/null; then
    echo -e "\033[1;31m❌ Python n'est pas installé\033[0m"
    exit 1
fi

# Construire la commande de migration
CMD="python manage.py migrate"

if [ "$SHOW_SQL" = true ]; then
    CMD="$CMD --plan"
fi

if [ "$FAKE" = true ]; then
    CMD="$CMD --fake"
fi

if [ -n "$APP" ]; then
    CMD="$CMD $APP"
fi

# Exécuter la migration
echo -e "\033[1;33mExécution: $CMD\033[0m"
cd dog_breed_identifier || exit 1

if eval $CMD; then
    echo -e "\033[1;32m✅ Migration réussie !\033[0m"
else
    echo -e "\033[1;31m❌ Migration échouée\033[0m"
    cd ..
    exit 1
fi

cd ..
echo -e "\033[1;36mMigration terminée !\033[0m"