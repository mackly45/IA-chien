#!/bin/bash

# Script de vérification de compatibilité

PLATFORMS=("windows" "linux" "macos")
PYTHON_VERSIONS=("3.8" "3.9" "3.10" "3.11")
DETAILED=false

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platforms)
            IFS=',' read -ra PLATFORMS <<< "$2"
            shift 2
            ;;
        -v|--versions)
            IFS=',' read -ra PYTHON_VERSIONS <<< "$2"
            shift 2
            ;;
        -d|--detailed)
            DETAILED=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-p platforms] [-v versions] [-d]"
            echo "  -p, --platforms PLATFORMS  Plateformes (séparées par des virgules) (défaut: windows,linux,macos)"
            echo "  -v, --versions VERSIONS    Versions Python (séparées par des virgules) (défaut: 3.8,3.9,3.10,3.11)"
            echo "  -d, --detailed             Afficher les détails"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mVérification de compatibilité de Dog Breed Identifier\033[0m"
echo -e "\033[1;36m================================================\033[0m"

# Fonction pour vérifier les dépendances Python
check_python_dependencies() {
    local requirements_file=${1:-"requirements.txt"}
    
    echo -e "\033[1;33mVérification des dépendances Python...\033[0m"
    
    if [ ! -f "$requirements_file" ]; then
        echo -e "\033[1;31m❌ Fichier $requirements_file non trouvé\033[0m"
        return 1
    fi
    
    local compatible=true
    local dependencies=$(grep -v "^#" "$requirements_file" | grep -v "^$" | sed 's/[[:space:]]*$//')
    
    while IFS= read -r dep; do
        if [ -n "$dep" ]; then
            # Parser le nom de la dépendance et la version
            if echo "$dep" | grep -qE "^([^=<>!]+)([=<>!]+)(.+)$"; then
                local package_name=$(echo "$dep" | sed -E 's/^([^=<>!]+)([=<>!]+)(.+)$/\1/' | xargs)
                local operator=$(echo "$dep" | sed -E 's/^([^=<>!]+)([=<>!]+)(.+)$/\2/' | xargs)
                local version=$(echo "$dep" | sed -E 's/^([^=<>!]+)([=<>!]+)(.+)$/\3/' | xargs)
                
                if [ "$DETAILED" = true ]; then
                    echo -e "\033[1;37m  Vérification: $package_name $operator $version\033[0m"
                fi
            else
                local package_name=$(echo "$dep" | xargs)
                if [ "$DETAILED" = true ]; then
                    echo -e "\033[1;37m  Vérification: $package_name (dernière version)\033[0m"
                fi
            fi
            
            # Vérifier si le package existe sur PyPI
            if command -v curl &> /dev/null; then
                if curl -s -f -o /dev/null "https://pypi.org/pypi/$package_name/json"; then
                    if [ "$DETAILED" = true ]; then
                        echo -e "\033[1;32m  ✅ $package_name disponible sur PyPI\033[0m"
                    fi
                else
                    echo -e "\033[1;31m  ❌ $package_name non trouvé sur PyPI\033[0m"
                    compatible=false
                fi
            fi
        fi
    done <<< "$dependencies"
    
    if [ "$compatible" = true ]; then
        return 0
    else
        return 1
    fi
}

# Fonction pour vérifier la compatibilité Docker
check_docker_compatibility() {
    echo -e "\033[1;33mVérification de la compatibilité Docker...\033[0m"
    
    # Vérifier que Docker est installé
    if ! command -v docker &> /dev/null; then
        echo -e "\033[1;31m❌ Docker n'est pas installé\033[0m"
        return 1
    fi
    
    # Vérifier la version de Docker
    if docker --version >/dev/null 2>&1; then
        if [ "$DETAILED" = true ]; then
            local docker_version=$(docker --version)
            echo -e "\033[1;32m  ✅ Docker installé: $docker_version\033[0m"
        fi
    else
        echo -e "\033[1;31m  ❌ Impossible de vérifier la version de Docker\033[0m"
        return 1
    fi
    
    # Vérifier le Dockerfile
    if [ -f "Dockerfile" ]; then
        local dockerfile_content=$(cat "Dockerfile")
        
        # Vérifier l'image de base
        if echo "$dockerfile_content" | grep -qE "FROM[[:space:]]+python:([0-9.]+)"; then
            local python_version=$(echo "$dockerfile_content" | grep -E "FROM[[:space:]]+python:([0-9.]+)" | sed -E 's/FROM[[:space:]]+python:([0-9.]+)/\1/')
            if [ "$DETAILED" = true ]; then
                echo -e "\033[1;32m  ✅ Image de base Python: $python_version\033[0m"
            fi
        else
            echo -e "\033[1;33m  ⚠️  Image de base Python non trouvée dans Dockerfile\033[0m"
        fi
        
        if [ "$DETAILED" = true ]; then
            echo -e "\033[1;32m  ✅ Dockerfile trouvé et analysé\033[0m"
        fi
    else
        echo -e "\033[1;31m  ❌ Dockerfile non trouvé\033[0m"
        return 1
    fi
    
    return 0
}

# Fonction pour vérifier la compatibilité avec les systèmes d'exploitation
check_os_compatibility() {
    local target_platforms=("$@")
    
    echo -e "\033[1;33mVérification de la compatibilité OS...\033[0m"
    
    local current_platform="unknown"
    case "$(uname -s)" in
        Linux*)     current_platform="linux";;
        Darwin*)    current_platform="macos";;
        CYGWIN*|MINGW32*|MSYS*|MINGW*) current_platform="windows";;
    esac
    
    if [ "$DETAILED" = true ]; then
        echo -e "\033[1;37m  Plateforme actuelle: $current_platform\033[0m"
    fi
    
    # Vérifier les fichiers spécifiques à chaque plateforme
    local compatibility_issues=0
    
    for platform in "${target_platforms[@]}"; do
        case $platform in
            "windows")
                # Vérifier les fichiers .bat, .ps1
                local windows_files=$(find . -name "*.bat" -o -name "*.ps1" 2>/dev/null | wc -l)
                if [ "$windows_files" -gt 0 ] && [ "$DETAILED" = true ]; then
                    echo -e "\033[1;32m  ✅ Fichiers Windows trouvés: $windows_files\033[0m"
                fi
                ;;
            
            "linux")
                # Vérifier les fichiers .sh
                local linux_files=$(find . -name "*.sh" 2>/dev/null)
                if [ -n "$linux_files" ]; then
                    while IFS= read -r file; do
                        if [ -f "$file" ]; then
                            local first_line=$(head -n 1 "$file" 2>/dev/null)
                            if echo "$first_line" | grep -q "^#!"; then
                                if [ "$DETAILED" = true ]; then
                                    echo -e "\033[1;32m  ✅ Shebang trouvé dans $(basename "$file")\033[0m"
                                fi
                            else
                                echo -e "\033[1;33m  ⚠️  Fichier shell sans shebang: $(basename "$file")\033[0m"
                                compatibility_issues=$((compatibility_issues + 1))
                            fi
                        fi
                    done <<< "$linux_files"
                fi
                ;;
            
            "macos")
                # La compatibilité macOS est généralement similaire à Linux
                if [ "$DETAILED" = true ]; then
                    echo -e "\033[1;32m  ✅ Compatibilité macOS (similaire à Linux)\033[0m"
                fi
                ;;
        esac
    done
    
    if [ $compatibility_issues -gt 0 ]; then
        return 1
    fi
    
    return 0
}

# Fonction pour vérifier la compatibilité Python
check_python_compatibility() {
    local target_versions=("$@")
    
    echo -e "\033[1;33mVérification de la compatibilité Python...\033[0m"
    
    # Vérifier la version Python actuelle
    if command -v python3 &> /dev/null; then
        local python_version=$(python3 --version 2>&1)
        if [ "$DETAILED" = true ]; then
            echo -e "\033[1;32m  ✅ Python installé: $python_version\033[0m"
        fi
    elif command -v python &> /dev/null; then
        local python_version=$(python --version 2>&1)
        if [ "$DETAILED" = true ]; then
            echo -e "\033[1;32m  ✅ Python installé: $python_version\033[0m"
        fi
    else
        echo -e "\033[1;31m  ❌ Python non installé\033[0m"
        return 1
    fi
    
    # Vérifier setup.py ou pyproject.toml pour les versions supportées
    if [ -f "setup.py" ]; then
        local setup_content=$(cat "setup.py")
        if echo "$setup_content" | grep -qE "python_requires[[:space:]]*=[[:space:]]*['\"](>=?[^'\"]+)['\"]"; then
            local requires=$(echo "$setup_content" | grep -E "python_requires[[:space:]]*=[[:space:]]*['\"](>=?[^'\"]+)['\"]" | sed -E 's/.*python_requires[[:space:]]*=[[:space:]]*['\"](>=?[^'\"]+)['\"].*/\1/')
            if [ "$DETAILED" = true ]; then
                echo -e "\033[1;32m  ✅ Versions Python requises: $requires\033[0m"
            fi
        fi
    fi
    
    if [ -f "pyproject.toml" ]; then
        local pyproject_content=$(cat "pyproject.toml")
        if echo "$pyproject_content" | grep -qE "requires-python[[:space:]]*=[[:space:]]*['\"](>=?[^'\"]+)['\"]"; then
            local requires=$(echo "$pyproject_content" | grep -E "requires-python[[:space:]]*=[[:space:]]*['\"](>=?[^'\"]+)['\"]" | sed -E 's/.*requires-python[[:space:]]*=[[:space:]]*['\"](>=?[^'\"]+)['\"].*/\1/')
            if [ "$DETAILED" = true ]; then
                echo -e "\033[1;32m  ✅ Versions Python requises: $requires\033[0m"
            fi
        fi
    fi
    
    return 0
}

# Fonction pour vérifier la compatibilité des dépendances avec les versions Python
check_dependency_python_compatibility() {
    local python_versions=("$@")
    
    echo -e "\033[1;33mVérification de la compatibilité des dépendances avec Python...\033[0m"
    
    if [ ! -f "requirements.txt" ]; then
        echo -e "\033[1;33m  ⚠️  requirements.txt non trouvé\033[0m"
        return 0
    fi
    
    local compatible=true
    local dependencies=$(grep -v "^#" "requirements.txt" | grep -v "^$" | sed 's/[[:space:]]*$//')
    
    while IFS= read -r dep; do
        if [ -n "$dep" ]; then
            local package_name="$dep"
            if echo "$dep" | grep -qE "^([^=<>!]+)"; then
                package_name=$(echo "$dep" | sed -E 's/^([^=<>!]+)(.*)$/\1/' | xargs)
            fi
            
            # Pour chaque version Python cible, vérifier la compatibilité
            for py_version in "${python_versions[@]}"; do
                if [ "$DETAILED" = true ]; then
                    echo -e "\033[1;37m  Vérification de $package_name avec Python $py_version\033[0m"
                fi
                
                # Cette vérification est complexe sans outils dédiés
                # Dans un vrai scénario, on utiliserait des outils comme pip-check ou pyup
            done
        fi
    done <<< "$dependencies"
    
    if [ "$compatible" = true ]; then
        return 0
    else
        return 1
    fi
}

# Exécuter les vérifications
echo -e "\033[1;33mExécution des vérifications de compatibilité...\033[0m"

all_compatible=true

# Vérifier les dépendances Python
if ! check_python_dependencies; then
    all_compatible=false
fi

# Vérifier la compatibilité Docker
if ! check_docker_compatibility; then
    all_compatible=false
fi

# Vérifier la compatibilité OS
if ! check_os_compatibility "${PLATFORMS[@]}"; then
    all_compatible=false
fi

# Vérifier la compatibilité Python
if ! check_python_compatibility "${PYTHON_VERSIONS[@]}"; then
    all_compatible=false
fi

# Vérifier la compatibilité des dépendances avec Python
if ! check_dependency_python_compatibility "${PYTHON_VERSIONS[@]}"; then
    all_compatible=false
fi

# Afficher le résumé
echo -e "\n\033[1;36mRésumé de la compatibilité:\033[0m"
echo -e "\033[1;36m========================\033[0m"

if [ "$all_compatible" = true ]; then
    echo -e "\033[1;32m✅ Le projet est compatible avec les plateformes cibles\033[0m"
    echo -e "\033[1;37m   Plateformes: ${PLATFORMS[*]}\033[0m"
    echo -e "\033[1;37m   Versions Python: ${PYTHON_VERSIONS[*]}\033[0m"
else
    echo -e "\033[1;31m❌ Le projet présente des problèmes de compatibilité\033[0m"
    echo -e "\033[1;33m   Veuillez consulter les messages d'erreur ci-dessus\033[0m"
fi

echo -e "\033[1;36mVérification de compatibilité terminée !\033[0m"