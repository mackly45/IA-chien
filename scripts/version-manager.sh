#!/bin/bash

# Script de gestion de version

ACTION="show"
NEW_VERSION=""
TAG=false
PUSH=false

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -v|--version)
            NEW_VERSION="$2"
            shift 2
            ;;
        -t|--tag)
            TAG=true
            shift
            ;;
        --push)
            PUSH=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-a action] [-v version] [-t] [--push]"
            echo "  -a, --action ACTION    Action (show, update, bump) (défaut: show)"
            echo "  -v, --version VERSION  Nouvelle version pour update/bump"
            echo "  -t, --tag              Créer un tag Git"
            echo "  --push                 Pousser vers le dépôt distant"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mGestion de version de Dog Breed Identifier\033[0m"
echo -e "\033[1;36m=====================================\033[0m"

# Fonction pour lire la version actuelle
get_current_version() {
    # Chercher la version dans différents fichiers possibles
    local version_files=("setup.py" "dog_breed_identifier/__init__.py" "package.json")
    
    for file in "${version_files[@]}"; do
        if [ -f "$file" ]; then
            local content=$(cat "$file")
            if echo "$content" | grep -qE 'version[[:space:]]*=[[:space:]]*["'"'"']([^"'"'"']+)["'"'"']'; then
                echo "$content" | grep -oE 'version[[:space:]]*=[[:space:]]*["'"'"']([^"'"'"']+)["'"'"']' | cut -d'"' -f2 | cut -d"'" -f2
                return
            fi
        fi
    done
    
    # Si aucune version trouvée, retourner une version par défaut
    echo "0.0.0"
}

# Fonction pour mettre à jour la version
update_version() {
    local old_version=$1
    local new_version=$2
    
    echo -e "\033[1;33mMise à jour de la version $old_version vers $new_version...\033[0m"
    
    local version_files=("setup.py" "dog_breed_identifier/__init__.py" "package.json")
    local updated_files=0
    
    for file in "${version_files[@]}"; do
        if [ -f "$file" ]; then
            # Utiliser sed pour remplacer la version
            sed -i "s/version[[:space:]]*=[[:space:]]*[\"']$old_version[\"']/version=\"$new_version\"/g" "$file"
            
            # Vérifier si le fichier a été modifié
            if [ $? -eq 0 ]; then
                echo -e "\033[1;32m✅ Mise à jour: $file\033[0m"
                updated_files=$((updated_files + 1))
            fi
        fi
    done
    
    if [ $updated_files -eq 0 ]; then
        echo -e "\033[1;33m⚠️  Aucun fichier de version mis à jour\033[0m"
    fi
    
    return $updated_files
}

# Fonction pour créer un tag Git
create_git_tag() {
    local version=$1
    
    echo -e "\033[1;33mCréation du tag Git v$version...\033[0m"
    
    if git tag -a "v$version" -m "Version $version"; then
        echo -e "\033[1;32m✅ Tag Git créé: v$version\033[0m"
        
        if [ "$PUSH" = true ]; then
            if git push origin "v$version"; then
                echo -e "\033[1;32m✅ Tag poussé vers le dépôt distant\033[0m"
            else
                echo -e "\033[1;31m❌ Échec du push du tag\033[0m"
                return 1
            fi
        fi
        
        return 0
    else
        echo -e "\033[1;31m❌ Échec de la création du tag Git\033[0m"
        return 1
    fi
}

# Fonction pour valider le format de version
validate_version_format() {
    local version=$1
    
    # Format sémantique: X.Y.Z ou X.Y.Z-prerelease
    if echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$'; then
        return 0
    else
        return 1
    fi
}

# Exécuter l'action demandée
case $ACTION in
    "show")
        current_version=$(get_current_version)
        echo -e "\033[1;37mVersion actuelle: $current_version\033[0m"
        ;;
    
    "update")
        if [ -z "$NEW_VERSION" ]; then
            echo -e "\033[1;31m❌ Version requise pour l'action 'update'\033[0m"
            exit 1
        fi
        
        if ! validate_version_format "$NEW_VERSION"; then
            echo -e "\033[1;31m❌ Format de version invalide. Utilisez X.Y.Z ou X.Y.Z-prerelease\033[0m"
            exit 1
        fi
        
        current_version=$(get_current_version)
        echo -e "\033[1;37mVersion actuelle: $current_version\033[0m"
        echo -e "\033[1;37mNouvelle version: $NEW_VERSION\033[0m"
        
        if [ "$current_version" = "$NEW_VERSION" ]; then
            echo -e "\033[1;33m⚠️  La version est déjà à jour\033[0m"
            exit 0
        fi
        
        # Mettre à jour la version
        if update_version "$current_version" "$NEW_VERSION"; then
            # Commiter les changements
            if git add . && git commit -m "Mise à jour de la version $current_version vers $NEW_VERSION"; then
                echo -e "\033[1;32m✅ Changements commités\033[0m"
            else
                echo -e "\033[1;31m❌ Échec du commit des changements\033[0m"
            fi
            
            # Créer un tag si demandé
            if [ "$TAG" = true ]; then
                create_git_tag "$NEW_VERSION"
            fi
            
            # Pousser les changements si demandé
            if [ "$PUSH" = true ]; then
                if git push origin HEAD; then
                    echo -e "\033[1;32m✅ Changements poussés vers le dépôt distant\033[0m"
                else
                    echo -e "\033[1;31m❌ Échec du push des changements\033[0m"
                fi
            fi
            
            echo -e "\033[1;32m✅ Version mise à jour avec succès !\033[0m"
        else
            echo -e "\033[1;31m❌ Échec de la mise à jour de la version\033[0m"
            exit 1
        fi
        ;;
    
    "bump")
        current_version=$(get_current_version)
        echo -e "\033[1;37mVersion actuelle: $current_version\033[0m"
        
        # Parser la version actuelle
        if echo "$current_version" | grep -qE '^([0-9]+)\.([0-9]+)\.([0-9]+)(-.+)?$'; then
            major=$(echo "$current_version" | cut -d. -f1)
            minor=$(echo "$current_version" | cut -d. -f2)
            patch=$(echo "$current_version" | cut -d. -f3 | cut -d- -f1)
            prerelease=$(echo "$current_version" | grep -oE '\-[a-zA-Z0-9]+$' || echo "")
            
            # Déterminer le type de bump
            case $NEW_VERSION in
                "major")
                    major=$((major + 1))
                    minor=0
                    patch=0
                    prerelease=""
                    ;;
                
                "minor")
                    minor=$((minor + 1))
                    patch=0
                    prerelease=""
                    ;;
                
                "patch")
                    patch=$((patch + 1))
                    prerelease=""
                    ;;
                
                *)
                    echo -e "\033[1;31m❌ Type de bump invalide. Utilisez 'major', 'minor', ou 'patch'\033[0m"
                    exit 1
                    ;;
            esac
            
            new_version="$major.$minor.$patch$prerelease"
            
            echo -e "\033[1;37mNouvelle version: $new_version\033[0m"
            
            # Mettre à jour la version
            if update_version "$current_version" "$new_version"; then
                # Commiter les changements
                if git add . && git commit -m "Bump version $current_version vers $new_version"; then
                    echo -e "\033[1;32m✅ Changements commités\033[0m"
                else
                    echo -e "\033[1;31m❌ Échec du commit des changements\033[0m"
                fi
                
                # Créer un tag si demandé
                if [ "$TAG" = true ]; then
                    create_git_tag "$new_version"
                fi
                
                # Pousser les changements si demandé
                if [ "$PUSH" = true ]; then
                    if git push origin HEAD; then
                        echo -e "\033[1;32m✅ Changements poussés vers le dépôt distant\033[0m"
                    else
                        echo -e "\033[1;31m❌ Échec du push des changements\033[0m"
                    fi
                fi
                
                echo -e "\033[1;32m✅ Version bumpée avec succès !\033[0m"
            else
                echo -e "\033[1;31m❌ Échec du bump de version\033[0m"
                exit 1
            fi
        else
            echo -e "\033[1;31m❌ Impossible de parser la version actuelle: $current_version\033[0m"
            exit 1
        fi
        ;;
    
    *)
        echo -e "\033[1;31m❌ Action non supportée: $ACTION\033[0m"
        echo -e "\033[1;33mActions supportées: show, update, bump\033[0m"
        exit 1
        ;;
esac

echo -e "\033[1;36mGestion de version terminée !\033[0m"