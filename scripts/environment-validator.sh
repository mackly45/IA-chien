#!/bin/bash

# Script de validation de l'environnement

# Paramètres par défaut
ENVIRONMENT="development"
CHECK_DOCKER=true
CHECK_PYTHON=true
CHECK_DEPENDENCIES=true
CHECK_CONFIG=true
VERBOSE=false

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
REQUIRED_PYTHON_VERSION="3.8"
REQUIRED_DOCKER_VERSION="20.0"

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mValidation de l'environnement\033[0m"
    echo -e "\033[1;36m==========================\033[0m"
}

print_info() {
    echo -e "\033[1;33m$1\033[0m"
}

print_success() {
    echo -e "\033[1;32m✅ $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m⚠️  $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m❌ $1\033[0m"
}

print_debug() {
    if [ "$VERBOSE" = true ]; then
        echo -e "\033[1;37m  [DEBUG] $1\033[0m"
    fi
}

# Analyse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --no-docker)
            CHECK_DOCKER=false
            shift
            ;;
        --no-python)
            CHECK_PYTHON=false
            shift
            ;;
        --no-dependencies)
            CHECK_DEPENDENCIES=false
            shift
            ;;
        --no-config)
            CHECK_CONFIG=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -e, --environment ENV    Environnement cible (défaut: development)"
            echo "  --no-docker              Ne pas vérifier Docker"
            echo "  --no-python              Ne pas vérifier Python"
            echo "  --no-dependencies        Ne pas vérifier les dépendances"
            echo "  --no-config              Ne pas vérifier la configuration"
            echo "  -v, --verbose            Mode verbeux"
            echo "  -h, --help               Afficher cette aide"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

print_header

# Initialiser les compteurs
checks_passed=0
checks_total=0

# Vérifier l'environnement
print_info "Environnement cible: $ENVIRONMENT"

# Vérifier Python
if [ "$CHECK_PYTHON" = true ]; then
    checks_total=$((checks_total + 1))
    print_info "Vérification de Python..."
    print_debug "Recherche de l'exécutable Python"
    
    if command -v python &> /dev/null; then
        python_version=$(python --version 2>&1)
        print_success "Python trouvé: $python_version"
        checks_passed=$((checks_passed + 1))
    elif command -v python3 &> /dev/null; then
        python_version=$(python3 --version 2>&1)
        print_success "Python trouvé: $python_version"
        checks_passed=$((checks_passed + 1))
    else
        print_error "Python non trouvé"
    fi
fi

# Vérifier Docker
if [ "$CHECK_DOCKER" = true ]; then
    checks_total=$((checks_total + 1))
    print_info "Vérification de Docker..."
    
    if command -v docker &> /dev/null; then
        docker_version=$(docker --version 2>&1)
        print_success "Docker trouvé: $docker_version"
        checks_passed=$((checks_passed + 1))
    else
        print_error "Docker non trouvé"
    fi
fi

# Vérifier les dépendances
if [ "$CHECK_DEPENDENCIES" = true ]; then
    checks_total=$((checks_total + 1))
    print_info "Vérification des dépendances..."
    
    if [ -f "requirements.txt" ]; then
        # Compter les dépendances
        dep_count=$(grep -v "^#" requirements.txt | grep -v "^$" | wc -l)
        
        # Vérifier si les dépendances sont installées
        missing_count=0
        while IFS= read -r req; do
            if [[ ! $req =~ ^# ]] && [[ ! $req =~ ^[[:space:]]*$ ]]; then
                # Extraire le nom du paquet (sans version)
                package_name=$(echo "$req" | sed -E 's/([>=<~!]=?.*)//')
                print_debug "Vérification de la dépendance: $package_name"
                
                # Vérifier si le paquet est installé
                if python -c "import $package_name" &> /dev/null; then
                    print_debug "✅ Dépendance trouvée: $package_name"
                else
                    missing_count=$((missing_count + 1))
                    print_debug "❌ Dépendance manquante: $package_name"
                fi
            fi
        done < "requirements.txt"
        
        if [ $missing_count -eq 0 ]; then
            print_success "Toutes les dépendances sont installées ($dep_count paquets)"
            checks_passed=$((checks_passed + 1))
        else
            print_error "$missing_count dépendances manquantes sur $dep_count"
        fi
    else
        print_error "Fichier requirements.txt non trouvé"
    fi
fi

# Vérifier la configuration
if [ "$CHECK_CONFIG" = true ]; then
    checks_total=$((checks_total + 1))
    print_info "Vérification de la configuration..."
    
    # Vérifier les fichiers de configuration
    config_files=(
        "./config/settings.py:true"
        "./config/database.py:false"
        "./.env:false"
    )
    
    missing_configs=0
    found_configs=0
    
    for config_entry in "${config_files[@]}"; do
        IFS=':' read -r config_path config_required <<< "$config_entry"
        
        if [ -f "$config_path" ]; then
            found_configs=$((found_configs + 1))
            print_debug "✅ Fichier de configuration trouvé: $config_path"
        elif [ "$config_required" = "true" ]; then
            missing_configs=$((missing_configs + 1))
            print_debug "❌ Fichier de configuration requis manquant: $config_path"
        else
            print_debug "ℹ️  Fichier de configuration optionnel non trouvé: $config_path"
        fi
    done
    
    if [ $missing_configs -eq 0 ]; then
        print_success "Configuration vérifiée ($found_configs fichiers trouvés)"
        checks_passed=$((checks_passed + 1))
    else
        print_error "$missing_configs fichiers de configuration requis manquants"
    fi
fi

# Vérifier les variables d'environnement
checks_total=$((checks_total + 1))
print_info "Vérification des variables d'environnement..."

required_env_vars=("SECRET_KEY" "DEBUG")
missing_env_vars=0
found_env_vars=0

for var in "${required_env_vars[@]}"; do
    if [ -n "${!var}" ]; then
        found_env_vars=$((found_env_vars + 1))
        print_debug "✅ Variable d'environnement trouvée: $var"
    else
        # Vérifier dans le fichier .env
        if [ -f ".env" ] && grep -q "^$var=" ".env"; then
            found_env_vars=$((found_env_vars + 1))
            print_debug "✅ Variable d'environnement trouvée dans .env: $var"
        else
            missing_env_vars=$((missing_env_vars + 1))
            print_debug "❌ Variable d'environnement manquante: $var"
        fi
    fi
done

if [ $missing_env_vars -eq 0 ]; then
    print_success "Variables d'environnement vérifiées ($found_env_vars variables trouvées)"
    checks_passed=$((checks_passed + 1))
else
    print_error "$missing_env_vars variables d'environnement manquantes"
fi

# Afficher le résumé
echo
echo -e "\033[1;36mRésumé de validation:\033[0m"
echo -e "\033[1;36m==================\033[0m"
echo -e "\033[1;37mEnvironnement: $ENVIRONMENT\033[0m"
echo -e "\033[1;37mVérifications réussies: $checks_passed/$checks_total\033[0m"

if [ $checks_passed -eq $checks_total ]; then
    print_success "Environnement validé avec succès"
    exit 0
else
    print_error "Environnement non valide ($((checks_total - checks_passed)) échecs)"
    exit 1
fi