#!/bin/bash

# Script d'outils de migration de base de données

# Paramètres par défaut
ACTION="migrate"
DATABASE="default"
MIGRATION_NAME=""
DRY_RUN=false
VERBOSE=false

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
DJANGO_PROJECT_DIR="./dog_breed_identifier"
MANAGE_PY="$DJANGO_PROJECT_DIR/manage.py"
MIGRATIONS_DIR="$DJANGO_PROJECT_DIR/classifier/migrations"

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mOutils de migration de base de données\033[0m"
    echo -e "\033[1;36m==============================\033[0m"
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
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -d|--database)
            DATABASE="$2"
            shift 2
            ;;
        -m|--migration)
            MIGRATION_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -a, --action ACTION      Action à effectuer (migrate, makemigrations, showmigrations, sqlmigrate, rollback)"
            echo "  -d, --database DB        Base de données cible (défaut: default)"
            echo "  -m, --migration NAME     Nom de la migration"
            echo "  --dry-run                Mode simulation"
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

# Fonction pour exécuter une commande Django
invoke_django_command() {
    local command=$1
    local description=$2
    
    print_log "Exécution: $description" "INFO"
    
    if [ "$VERBOSE" = true ]; then
        echo "Commande: python $MANAGE_PY $command"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_log "Mode dry-run - commande non exécutée" "WARN"
        return 0
    fi
    
    # Exécuter la commande et capturer la sortie
    output=$(python "$MANAGE_PY" $command 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_log "Succès: $description" "SUCCESS"
        if [ "$VERBOSE" = true ] && [ -n "$output" ]; then
            echo -e "\033[1;37m$output\033[0m"
        fi
        return 0
    else
        print_log "Échec: $description" "ERROR"
        if [ -n "$output" ]; then
            echo -e "\033[1;31m$output\033[0m"
        fi
        return 1
    fi
}

# Vérifier que le projet Django existe
if [ ! -d "$DJANGO_PROJECT_DIR" ]; then
    print_log "Répertoire du projet Django non trouvé: $DJANGO_PROJECT_DIR" "ERROR"
    exit 1
fi

if [ ! -f "$MANAGE_PY" ]; then
    print_log "Script manage.py non trouvé: $MANAGE_PY" "ERROR"
    exit 1
fi

# Vérifier que Python est disponible
if ! command -v python &> /dev/null; then
    print_log "Python non trouvé. Veuillez installer Python." "ERROR"
    exit 1
else
    python_version=$(python --version 2>&1)
    print_log "Python disponible: $python_version" "SUCCESS"
fi

# Exécuter l'action demandée
case $ACTION in
    "migrate")
        print_log "Exécution des migrations pour la base de données: $DATABASE" "INFO"
        
        if [ -n "$MIGRATION_NAME" ]; then
            # Appliquer une migration spécifique
            command="migrate $DATABASE $MIGRATION_NAME"
            description="Migration $MIGRATION_NAME sur la base de données $DATABASE"
        else
            # Appliquer toutes les migrations
            command="migrate $DATABASE"
            description="Toutes les migrations sur la base de données $DATABASE"
        fi
        
        if invoke_django_command "$command" "$description"; then
            print_log "Migrations appliquées avec succès" "SUCCESS"
        else
            print_log "Échec de l'application des migrations" "ERROR"
            exit 1
        fi
        ;;
    
    "makemigrations")
        print_log "Création des migrations pour l'application classifier" "INFO"
        
        if [ -n "$MIGRATION_NAME" ]; then
            command="makemigrations classifier --name $MIGRATION_NAME"
            description="Création de la migration '$MIGRATION_NAME' pour classifier"
        else
            command="makemigrations classifier"
            description="Création des migrations pour classifier"
        fi
        
        if invoke_django_command "$command" "$description"; then
            print_log "Migrations créées avec succès" "SUCCESS"
        else
            print_log "Échec de la création des migrations" "ERROR"
            exit 1
        fi
        ;;
    
    "showmigrations")
        print_log "Affichage des migrations pour la base de données: $DATABASE" "INFO"
        
        command="showmigrations $DATABASE"
        description="Affichage des migrations pour la base de données $DATABASE"
        
        if ! invoke_django_command "$command" "$description"; then
            print_log "Échec de l'affichage des migrations" "ERROR"
            exit 1
        fi
        ;;
    
    "sqlmigrate")
        if [ -z "$MIGRATION_NAME" ]; then
            print_log "Nom de migration requis pour l'action 'sqlmigrate'" "ERROR"
            exit 1
        fi
        
        print_log "Génération du SQL pour la migration: $MIGRATION_NAME" "INFO"
        
        command="sqlmigrate classifier $MIGRATION_NAME"
        description="Génération du SQL pour la migration $MIGRATION_NAME"
        
        if ! invoke_django_command "$command" "$description"; then
            print_log "Échec de la génération du SQL" "ERROR"
            exit 1
        fi
        ;;
    
    "rollback")
        if [ -z "$MIGRATION_NAME" ]; then
            print_log "Nom de migration requis pour l'action 'rollback'" "ERROR"
            exit 1
        fi
        
        print_log "Retour arrière de la migration: $MIGRATION_NAME" "INFO"
        
        command="migrate classifier zero"
        description="Retour arrière de toutes les migrations"
        
        # D'abord, trouver la migration précédente
        if [ "$VERBOSE" = true ]; then
            python "$MANAGE_PY" showmigrations classifier --plan 2>&1
        fi
        
        if [ "$DRY_RUN" = false ]; then
            echo -n "Êtes-vous sûr de vouloir effectuer ce retour arrière ? (yes/no): "
            read confirmation
            if [ "$confirmation" != "yes" ]; then
                print_log "Retour arrière annulé par l'utilisateur" "INFO"
                exit 0
            fi
        fi
        
        if invoke_django_command "$command" "$description"; then
            print_log "Retour arrière effectué avec succès" "SUCCESS"
        else
            print_log "Échec du retour arrière" "ERROR"
            exit 1
        fi
        ;;
    
    *)
        print_log "Action non reconnue: $ACTION" "ERROR"
        print_log "Actions disponibles: migrate, makemigrations, showmigrations, sqlmigrate, rollback" "INFO"
        exit 1
        ;;
esac

print_log "Opération de migration terminée !" "SUCCESS"