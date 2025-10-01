#!/bin/bash

# Script de validation de configuration

VERBOSE=false
ERRORS=0
WARNINGS=0

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-v]"
            echo "  -v, --verbose  Mode verbeux"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

# Fonction pour afficher les messages
write_log() {
    local message=$1
    local level=${2:-"INFO"}
    
    case $level in
        "ERROR")
            echo -e "\033[1;31m❌ $message\033[0m"
            ((ERRORS++))
            ;;
        "WARNING")
            echo -e "\033[1;33m⚠️  $message\033[0m"
            ((WARNINGS++))
            ;;
        "SUCCESS")
            echo -e "\033[1;32m✅ $message\033[0m"
            ;;
        *)
            if [ "$VERBOSE" = true ]; then
                echo -e "\033[1;37mℹ️  $message\033[0m"
            fi
            ;;
    esac
}

echo -e "\033[1;36mValidation de la configuration\033[0m"
echo -e "\033[1;36m===========================\033[0m"

# Vérifier la structure du projet
echo -e "\033[1;33mVérification de la structure du projet...\033[0m"

required_files=(
    "requirements.txt"
    "Dockerfile"
    "docker-compose.yml"
    "README.md"
    ".gitignore"
    ".env"
)

required_dirs=(
    "dog_breed_identifier"
    "docs"
    "scripts"
    "tests"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        write_log "Fichier trouvé: $file" "SUCCESS"
    else
        write_log "Fichier manquant: $file" "ERROR"
    fi
done

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        write_log "Répertoire trouvé: $dir" "SUCCESS"
    else
        write_log "Répertoire manquant: $dir" "ERROR"
    fi
done

# Vérifier les fichiers de configuration Docker
echo -e "\033[1;33mVérification des fichiers Docker...\033[0m"

docker_files=(
    "Dockerfile"
    "docker-compose.yml"
    ".dockerignore"
)

for file in "${docker_files[@]}"; do
    if [ -f "$file" ]; then
        # Vérifier que le fichier n'est pas vide
        if [ -s "$file" ]; then
            write_log "Fichier Docker valide: $file" "SUCCESS"
        else
            write_log "Fichier Docker vide: $file" "ERROR"
        fi
    else
        write_log "Fichier Docker manquant: $file" "ERROR"
    fi
done

# Vérifier les fichiers de documentation
echo -e "\033[1;33mVérification des fichiers de documentation...\033[0m"

doc_files=(
    "docs/architecture.md"
    "docs/development.md"
    "docs/deployment.md"
)

for file in "${doc_files[@]}"; do
    if [ -f "$file" ]; then
        if [ -s "$file" ]; then
            write_log "Fichier de documentation valide: $file" "SUCCESS"
        else
            write_log "Fichier de documentation vide: $file" "WARNING"
        fi
    else
        write_log "Fichier de documentation manquant: $file" "WARNING"
    fi
done

# Vérifier les scripts
echo -e "\033[1;33mVérification des scripts...\033[0m"

if command -v find &> /dev/null; then
    script_files=$(find scripts -name "*.sh" -type f 2>/dev/null)
    for file in $script_files; do
        if [ -s "$file" ]; then
            write_log "Script valide: $(basename "$file")" "SUCCESS"
        else
            write_log "Script vide: $(basename "$file")" "WARNING"
        fi
    done
fi

# Vérifier les dépendances Python
echo -e "\033[1;33mVérification des dépendances Python...\033[0m"

if [ -f "requirements.txt" ]; then
    req_count=$(grep -v "^#" requirements.txt | grep -v "^$" | wc -l)
    if [ "$req_count" -gt 0 ]; then
        write_log "Dépendances Python trouvées: $req_count" "SUCCESS"
    else
        write_log "Aucune dépendance Python trouvée" "WARNING"
    fi
else
    write_log "Fichier requirements.txt manquant" "ERROR"
fi

# Afficher le résumé
echo -e "\n\033[1;36mRésumé de la validation:\033[0m"
echo -e "\033[1;36m====================\033[0m"
echo -e "\033[1;31mErreurs: $ERRORS\033[0m"
echo -e "\033[1;33mAvertissements: $WARNINGS\033[0m"

if [ $ERRORS -eq 0 ]; then
    echo -e "\033[1;32m✅ Configuration valide !\033[0m"
    exit 0
else
    echo -e "\033[1;31m❌ Configuration invalide ($ERRORS erreurs)\033[0m"
    exit 1
fi