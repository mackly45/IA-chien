#!/bin/bash

# Script de génération de CHANGELOG

OUTPUT_FILE="./CHANGELOG.md"
SINCE_TAG=""
INCLUDE_UNRELEASED=false
FROM_GIT_LOG=false

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -s|--since)
            SINCE_TAG="$2"
            shift 2
            ;;
        -u|--unreleased)
            INCLUDE_UNRELEASED=true
            shift
            ;;
        -g|--git-log)
            FROM_GIT_LOG=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-o output] [-s since_tag] [-u] [-g]"
            echo "  -o, --output FILE       Fichier de sortie (défaut: ./CHANGELOG.md)"
            echo "  -s, --since TAG         Tag de départ pour les commits"
            echo "  -u, --unreleased        Inclure les changements non publiés"
            echo "  -g, --git-log           Générer à partir des logs Git"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mGénération du CHANGELOG\033[0m"
echo -e "\033[1;36m====================\033[0m"

# Fonction pour obtenir les commits Git
get_git_commits() {
    local since=$1
    
    local git_command="git log --pretty=format:'%H|%an|%ad|%s' --date=short"
    
    if [ -n "$since" ]; then
        git_command="$git_command $since..HEAD"
    fi
    
    eval $git_command 2>/dev/null | while IFS='|' read -r hash author date message; do
        echo "$hash|$author|$date|$message"
    done
}

# Fonction pour catégoriser les commits
categorize_commits() {
    local commits_file=$1
    
    # Créer des fichiers temporaires pour chaque catégorie
    local features_file=$(mktemp)
    local fixes_file=$(mktemp)
    local changes_file=$(mktemp)
    local docs_file=$(mktemp)
    local tests_file=$(mktemp)
    local other_file=$(mktemp)
    
    # Traiter chaque commit
    while IFS='|' read -r hash author date message; do
        local lower_message=$(echo "$message" | tr '[:upper:]' '[:lower:]')
        
        if echo "$lower_message" | grep -qE "^(add|feat|feature|ajout)"; then
            echo "$hash|$author|$date|$message" >> "$features_file"
        elif echo "$lower_message" | grep -qE "^(fix|bug|corrige)"; then
            echo "$hash|$author|$date|$message" >> "$fixes_file"
        elif echo "$lower_message" | grep -qE "^(docs|doc|documentation)"; then
            echo "$hash|$author|$date|$message" >> "$docs_file"
        elif echo "$lower_message" | grep -qE "^(test|tests)"; then
            echo "$hash|$author|$date|$message" >> "$tests_file"
        elif echo "$lower_message" | grep -qE "^(change|update|modify|modifie)"; then
            echo "$hash|$author|$date|$message" >> "$changes_file"
        else
            echo "$hash|$author|$date|$message" >> "$other_file"
        fi
    done < "$commits_file"
    
    # Retourner les fichiers
    echo "$features_file,$fixes_file,$changes_file,$docs_file,$tests_file,$other_file"
}

# Fonction pour générer le contenu du CHANGELOG
generate_changelog_content() {
    local categorized_files=$1
    local version=$2
    local date=$3
    
    local content=""
    
    if [ -n "$version" ] && [ -n "$date" ]; then
        content="## [$version] - $date\n\n"
    elif [ "$INCLUDE_UNRELEASED" = true ]; then
        content="## [Unreleased]\n\n"
    fi
    
    # Extraire les fichiers
    IFS=',' read -ra files <<< "$categorized_files"
    local features_file=${files[0]}
    local fixes_file=${files[1]}
    local changes_file=${files[2]}
    local docs_file=${files[3]}
    local tests_file=${files[4]}
    local other_file=${files[5]}
    
    # Fonction pour ajouter une section
    add_section() {
        local title=$1
        local commits_file=$2
        
        if [ -s "$commits_file" ]; then
            content="$content### $title\n\n"
            while IFS='|' read -r hash author date message; do
                # Formater le message en enlevant le type de commit s'il est présent
                local clean_message=$(echo "$message" | sed -E 's/^(add|feat|feature|fix|bug|docs|doc|documentation|test|tests|change|update|modify|ajout|corrige|documentation|test|modifie):\s*//i')
                content="$content- $clean_message ($author)\n"
            done < "$commits_file"
            content="$content\n"
        fi
    }
    
    # Ajouter les sections
    add_section "Added" "$features_file"
    add_section "Fixed" "$fixes_file"
    add_section "Changed" "$changes_file"
    add_section "Documentation" "$docs_file"
    add_section "Tests" "$tests_file"
    add_section "Other" "$other_file"
    
    echo -e "$content"
}

# Générer le CHANGELOG
if [ "$FROM_GIT_LOG" = true ]; then
    # Obtenir les commits
    commits_file=$(mktemp)
    get_git_commits "$SINCE_TAG" > "$commits_file"
    
    if [ ! -s "$commits_file" ]; then
        echo -e "\033[1;31m❌ Aucun commit trouvé\033[0m"
        rm -f "$commits_file"
        exit 1
    fi
    
    # Catégoriser les commits
    categorized_files=$(categorize_commits "$commits_file")
    
    # Obtenir la version actuelle
    version="Unreleased"
    if command -v git &> /dev/null; then
        version=$(git describe --tags --abbrev=0 2>/dev/null || echo "Unreleased")
    fi
    
    # Générer le contenu
    date=$(date +"%Y-%m-%d")
    changelog_content=$(generate_changelog_content "$categorized_files" "$version" "$date")
    
    # Lire le CHANGELOG existant s'il existe
    existing_content=""
    if [ -f "$OUTPUT_FILE" ]; then
        existing_content=$(cat "$OUTPUT_FILE")
    fi
    
    # Combiner le contenu
    final_content="# Changelog\n\n"
    final_content="${final_content}Toutes les modifications notables apportées à ce projet seront documentées dans ce fichier.\n\n"
    final_content="${final_content}Le format est basé sur [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),\n"
    final_content="${final_content}et ce projet adhère au [Versioning sémantique](https://semver.org/spec/v2.0.0.html).\n\n"
    
    if [ -n "$existing_content" ]; then
        # Insérer le nouveau contenu après l'en-tête
        echo -e "$final_content$changelog_content$existing_content" > "$OUTPUT_FILE"
    else
        echo -e "$final_content$changelog_content" > "$OUTPUT_FILE"
    fi
    
    # Nettoyer les fichiers temporaires
    IFS=',' read -ra files <<< "$categorized_files"
    for file in "${files[@]}"; do
        rm -f "$file"
    done
    rm -f "$commits_file"
    
    echo -e "\033[1;32m✅ CHANGELOG généré: $OUTPUT_FILE\033[0m"
else
    # Générer un template de CHANGELOG
    cat > "$OUTPUT_FILE" << 'EOF'
# Changelog

Toutes les modifications notables apportées à ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
et ce projet adhère au [Versioning sémantique](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- 

### Changed
- 

### Fixed
- 

### Removed
- 

## [1.0.0] - DATE

### Added
- Projet initial

EOF
    
    # Remplacer DATE par la date actuelle
    sed -i "s/DATE/$(date +"%Y-%m-%d")/g" "$OUTPUT_FILE"
    
    echo -e "\033[1;32m✅ Template de CHANGELOG généré: $OUTPUT_FILE\033[0m"
fi

echo -e "\033[1;36mGénération du CHANGELOG terminée !\033[0m"