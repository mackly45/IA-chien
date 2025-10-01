#!/bin/bash

# Script de release du projet

VERSION=""
DRY_RUN=false

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 -v VERSION [--dry-run]"
            echo "  -v, --version VERSION  Numéro de version (X.Y.Z)"
            echo "  --dry-run             Simulation sans modifications"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    echo -e "\033[1;31m❌ Version requise. Utilisez -v VERSION\033[0m"
    exit 1
fi

echo -e "\033[1;36mRelease du projet Dog Breed Identifier v$VERSION\033[0m"
echo -e "\033[1;36m============================================\033[0m"

# Vérifier que la version est au bon format
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
    echo -e "\033[1;31m❌ Format de version invalide. Utilisez X.Y.Z ou X.Y.Z-prerelease\033[0m"
    exit 1
fi

# Vérifier que nous sommes sur la branche principale
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo -e "\033[1;31m❌ Vous devez être sur la branche principale pour créer une release\033[0m"
    exit 1
fi

# Vérifier que le working directory est propre
if [ -n "$(git status --porcelain)" ]; then
    echo -e "\033[1;31m❌ Le working directory n'est pas propre. Commitez ou stash vos changements.\033[0m"
    exit 1
fi

# Mettre à jour le numéro de version dans les fichiers pertinents
echo -e "\033[1;33mMise à jour du numéro de version...\033[0m"
VERSION_FILES=("setup.py" "dog_breed_identifier/__init__.py" "package.json")

for file in "${VERSION_FILES[@]}"; do
    if [ -f "$file" ]; then
        if grep -q "version" "$file"; then
            if [ "$DRY_RUN" = false ]; then
                sed -i "s/version[[:space:]]*=[[:space:]]*[\"'][^\"']*[\"']/version=\"$VERSION\"/g" "$file"
                git add "$file"
                echo -e "\033[1;37mMis à jour: $file\033[0m"
            else
                echo -e "\033[1;37mSimulé: Mise à jour de $file\033[0m"
            fi
        fi
    fi
done

# Créer le tag git
if [ "$DRY_RUN" = false ]; then
    git commit -m "Release v$VERSION"
    git tag -a "v$VERSION" -m "Version $VERSION"
    echo -e "\033[1;32m✅ Tag créé: v$VERSION\033[0m"
else
    echo -e "\033[1;37mSimulé: Création du tag v$VERSION\033[0m"
fi

# Créer l'archive de release
RELEASE_DIR="./releases"
if [ ! -d "$RELEASE_DIR" ]; then
    mkdir -p "$RELEASE_DIR"
fi

RELEASE_ARCHIVE="$RELEASE_DIR/dog-breed-identifier-v$VERSION.zip"
if [ "$DRY_RUN" = false ]; then
    if command -v zip &> /dev/null; then
        zip -r "$RELEASE_ARCHIVE" . \
            -x "*.git*" \
            -x "*.venv*" \
            -x "*venv*" \
            -x "*__pycache__*" \
            -x "*.pyc" \
            -x "*.DS_Store" \
            -x "*Thumbs.db" \
            -x "*releases*" \
            -x "*node_modules*" \
            -x "*mediafiles*" \
            -x "*staticfiles*" \
            -x "*.log"
        echo -e "\033[1;32m✅ Archive de release créée: $RELEASE_ARCHIVE\033[0m"
    else
        echo -e "\033[1;31mzip n'est pas installé\033[0m"
    fi
else
    echo -e "\033[1;37mSimulé: Création de l'archive $RELEASE_ARCHIVE\033[0m"
fi

# Push les changements
if [ "$DRY_RUN" = false ]; then
    echo -e "\033[1;33mSouhaitez-vous pusher les changements vers le dépôt distant ? (y/N)\033[0m"
    read -r CONFIRM
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        git push origin HEAD
        git push origin "v$VERSION"
        echo -e "\033[1;32m✅ Changements pushés vers le dépôt distant\033[0m"
    fi
else
    echo -e "\033[1;37mSimulé: Push des changements\033[0m"
fi

echo -e "\033[1;36mRelease v$VERSION terminée !\033[0m"
if [ "$DRY_RUN" = true ]; then
    echo -e "\033[1;33m⚠️  Ceci était une simulation (dry run)\033[0m"
fi