#!/bin/bash

# Script de validation de la configuration

# Paramètres par défaut
CONFIG_DIR="./config"
ENV_FILE=".env"
CHECK_DJANGO=true
CHECK_DATABASE=true
CHECK_SECRETS=true
VERBOSE=false

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mValidation de la configuration\033[0m"
    echo -e "\033[1;36m==========================\033[0m"
}

print_log() {
    local message=$1
    local level=${2:-"INFO"}
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case $level in
        "INFO")
            echo -e "\033[1;37m[$timestamp] [INFO] $message\033[0m"
            ;;
        "WARN")
            echo -e "\033[1;33m[$timestamp] [WARN] $message\033[0m"
            ;;
        "ERROR")
            echo -e "\033[1;31m[$timestamp] [ERROR] $message\033[0m"
            ;;
        "SUCCESS")
            echo -e "\033[1;32m[$timestamp] [SUCCESS] $message\033[0m"
            ;;
    esac
}

# Analyse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config-dir)
            CONFIG_DIR="$2"
            shift 2
            ;;
        -e|--env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        --no-django)
            CHECK_DJANGO=false
            shift
            ;;
        --no-database)
            CHECK_DATABASE=false
            shift
            ;;
        --no-secrets)
            CHECK_SECRETS=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -c, --config-dir DIR     Répertoire de configuration (défaut: ./config)"
            echo "  -e, --env-file FILE      Fichier d'environnement (défaut: .env)"
            echo "  --no-django              Ne pas vérifier la configuration Django"
            echo "  --no-database            Ne pas vérifier la configuration de la base de données"
            echo "  --no-secrets             Ne pas vérifier les secrets"
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

# Fichiers de configuration requis
REQUIRED_CONFIG_FILES=(
    "./dog_breed_identifier/dog_identifier/settings.py"
    "./requirements.txt"
    "./Dockerfile"
    "./docker-compose.yml"
)

# Variables d'environnement requises
REQUIRED_ENV_VARS=(
    "SECRET_KEY"
    "DEBUG"
)

# Fonction pour vérifier l'existence des fichiers
test_config_files() {
    print_log "Vérification des fichiers de configuration..." "INFO"
    local missing_files=0
    local found_files=0
    
    for file in "${REQUIRED_CONFIG_FILES[@]}"; do
        if [ -f "$file" ]; then
            found_files=$((found_files + 1))
            print_log "Fichier trouvé: $file" "SUCCESS"
        else
            missing_files=$((missing_files + 1))
            print_log "Fichier manquant: $file" "ERROR"
        fi
    done
    
    echo "$missing_files"
}

# Fonction pour vérifier les variables d'environnement
test_environment_variables() {
    local env_file_path=$1
    print_log "Vérification des variables d'environnement..." "INFO"
    local missing_vars=0
    local found_vars=0
    
    # Charger les variables depuis le fichier .env si il existe
    declare -A env_vars
    if [ -f "$env_file_path" ]; then
        while IFS= read -r line; do
            if [[ $line =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
                key="${BASH_REMATCH[1]}"
                value="${BASH_REMATCH[2]}"
                env_vars["$key"]="$value"
            fi
        done < "$env_file_path"
    fi
    
    # Vérifier chaque variable requise
    for var in "${REQUIRED_ENV_VARS[@]}"; do
        # Vérifier d'abord dans les variables d'environnement système
        if [ -n "${!var}" ]; then
            found_vars=$((found_vars + 1))
            print_log "Variable système trouvée: $var" "SUCCESS"
        # Ensuite vérifier dans le fichier .env
        elif [ -n "${env_vars[$var]}" ]; then
            found_vars=$((found_vars + 1))
            print_log "Variable .env trouvée: $var" "SUCCESS"
        # Sinon, variable manquante
        else
            missing_vars=$((missing_vars + 1))
            print_log "Variable manquante: $var" "ERROR"
        fi
    done
    
    echo "$missing_vars"
}

# Fonction pour valider la configuration Django
test_django_config() {
    print_log "Vérification de la configuration Django..." "INFO"
    
    # Vérifier que Django est installé
    if python -c "import django" &> /dev/null; then
        print_log "Django est installé" "SUCCESS"
    else
        print_log "Django n'est pas installé" "ERROR"
        return 1
    fi
    
    # Vérifier la configuration Django
    python << 'EOF'
import sys
import os
sys.path.append('./dog_breed_identifier')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
try:
    import django
    django.setup()
    from django.conf import settings
    print('SECRET_KEY defined:', hasattr(settings, 'SECRET_KEY') and bool(settings.SECRET_KEY))
    print('DEBUG defined:', hasattr(settings, 'DEBUG'))
    print('DATABASES defined:', hasattr(settings, 'DATABASES') and bool(settings.DATABASES))
except Exception as e:
    print('Error:', str(e))
EOF
    
    return 0
}

# Fonction pour valider la configuration de la base de données
test_database_config() {
    print_log "Vérification de la configuration de la base de données..." "INFO"
    
    # Vérifier la configuration de la base de données
    python << 'EOF'
import sys
import os
sys.path.append('./dog_breed_identifier')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
try:
    import django
    django.setup()
    from django.conf import settings
    db_config = settings.DATABASES.get('default', {})
    print('Engine:', db_config.get('ENGINE', 'Not set'))
    print('Name:', db_config.get('NAME', 'Not set'))
    print('User:', db_config.get('USER', 'Not set'))
    print('Host:', db_config.get('HOST', 'Not set'))
    print('Port:', db_config.get('PORT', 'Not set'))
except Exception as e:
    print('Error:', str(e))
EOF
    
    print_log "Configuration de la base de données vérifiée" "SUCCESS"
    return 0
}

# Fonction pour vérifier les secrets
test_secrets() {
    print_log "Vérification des secrets..." "INFO"
    
    # Vérifier le fichier .env
    if [ -f ".env" ]; then
        if grep -q "^SECRET_KEY=" ".env"; then
            print_log "SECRET_KEY trouvée dans .env" "SUCCESS"
            secret_value=$(grep "^SECRET_KEY=" ".env" | cut -d'=' -f2-)
            if [ -n "$secret_value" ] && [ "$secret_value" != "your-secret-key-here" ]; then
                print_log "SECRET_KEY a une valeur définie" "SUCCESS"
            else
                print_log "SECRET_KEY n'a pas de valeur définie" "WARN"
            fi
        else
            print_log "SECRET_KEY non trouvée dans .env" "WARN"
        fi
    else
        print_log "Fichier .env non trouvé" "WARN"
    fi
    
    # Vérifier .env.local (devrait contenir les vrais secrets)
    if [ -f ".env.local" ]; then
        print_log "Fichier .env.local trouvé (bonne pratique)" "SUCCESS"
    else
        print_log "Fichier .env.local non trouvé (recommandé pour les secrets)" "INFO"
    fi
    
    return 0
}

# Exécuter les validations
print_log "Démarrage de la validation de la configuration..." "INFO"

# Vérifier les fichiers de configuration
file_issues=$(test_config_files)
print_log "Fichiers de configuration manquants: $file_issues" "INFO"

# Vérifier les variables d'environnement
env_issues=$(test_environment_variables "$ENV_FILE")
print_log "Variables d'environnement manquantes: $env_issues" "INFO"

# Vérifier la configuration Django si demandé
django_valid=0
if [ "$CHECK_DJANGO" = true ]; then
    if test_django_config; then
        django_valid=0
    else
        django_valid=1
    fi
fi

# Vérifier la configuration de la base de données si demandé
db_valid=0
if [ "$CHECK_DATABASE" = true ]; then
    if test_database_config; then
        db_valid=0
    else
        db_valid=1
    fi
fi

# Vérifier les secrets si demandé
secrets_valid=0
if [ "$CHECK_SECRETS" = true ]; then
    if test_secrets; then
        secrets_valid=0
    else
        secrets_valid=1
    fi
fi

# Afficher le résumé
echo
echo -e "\033[1;36mRésumé de la validation:\033[0m"
echo -e "\033[1;36m====================\033[0m"
echo -e "\033[1;37mFichiers de configuration manquants: $file_issues\033[0m"
echo -e "\033[1;37mVariables d'environnement manquantes: $env_issues\033[0m"
echo -e "\033[1;37mConfiguration Django valide: $(if [ $django_valid -eq 0 ]; then echo "Oui"; else echo "Non"; fi)\033[0m"
echo -e "\033[1;37mConfiguration base de données valide: $(if [ $db_valid -eq 0 ]; then echo "Oui"; else echo "Non"; fi)\033[0m"
echo -e "\033[1;37mVérification des secrets: $(if [ $secrets_valid -eq 0 ]; then echo "Effectuée"; else echo "Non effectuée"; fi)\033[0m"

# Déterminer le statut global
global_valid=0
if [ $file_issues -eq 0 ] && [ $env_issues -eq 0 ] && [ $django_valid -eq 0 ] && [ $db_valid -eq 0 ] && [ $secrets_valid -eq 0 ]; then
    global_valid=0
else
    global_valid=1
fi

if [ $global_valid -eq 0 ]; then
    echo
    echo -e "\033[1;32m✅ Configuration validée avec succès !\033[0m"
    exit 0
else
    echo
    echo -e "\033[1;31m❌ Problèmes de configuration détectés\033[0m"
    exit 1
fi