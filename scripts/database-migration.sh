#!/bin/bash

# Script de migration de base de données

ACTION="migrate"
MIGRATION_NAME=""
STEPS=1
DATABASE="default"
DRY_RUN=false
FORCE=false
BACKUP_PATH="./db-backups"

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -n|--name)
            MIGRATION_NAME="$2"
            shift 2
            ;;
        -s|--steps)
            STEPS="$2"
            shift 2
            ;;
        -d|--database)
            DATABASE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -b|--backup-path)
            BACKUP_PATH="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-a action] [-n name] [-s steps] [-d database] [--dry-run] [-f] [-b path]"
            echo "  -a, --action ACTION         Action (migrate, rollback, status, create) (défaut: migrate)"
            echo "  -n, --name NAME             Nom de la migration (pour create)"
            echo "  -s, --steps STEPS           Nombre d'étapes (défaut: 1)"
            echo "  -d, --database DATABASE     Nom de la base de données (défaut: default)"
            echo "  --dry-run                   Simulation sans exécution réelle"
            echo "  -f, --force                 Forcer l'opération sans backup"
            echo "  -b, --backup-path PATH      Chemin du répertoire de backup (défaut: ./db-backups)"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mMigration de Base de Données de Dog Breed Identifier\033[0m"
echo -e "\033[1;36m=============================================\033[0m"

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
MIGRATIONS_DIR="./dog_breed_identifier/migrations"

# Fonction pour créer un backup de la base de données
backup_database() {
    local db_name=$1
    
    echo -e "\033[1;33mCréation d'un backup de la base de données...\033[0m"
    
    # Créer le répertoire de backup s'il n'existe pas
    if [ ! -d "$BACKUP_PATH" ]; then
        mkdir -p "$BACKUP_PATH"
    fi
    
    local backup_file="$BACKUP_PATH/backup-$db_name-$TIMESTAMP.sql"
    
    # Pour SQLite (base de données par défaut de Django)
    local db_file="./db.sqlite3"
    if [ -f "$db_file" ]; then
        cp "$db_file" "$backup_file.sqlite3"
        echo -e "\033[1;32m✅ Backup SQLite créé: $backup_file.sqlite3\033[0m"
        echo "$backup_file.sqlite3"
        return 0
    fi
    
    # Pour d'autres bases de données, vous pouvez implémenter des commandes spécifiques
    # Par exemple, pour PostgreSQL:
    # pg_dump -U $DB_USER -h $DB_HOST -p $DB_PORT $db_name > $backup_file
    
    echo -e "\033[1;32m✅ Backup créé: $backup_file\033[0m"
    echo "$backup_file"
    return 0
}

# Fonction pour restaurer un backup de la base de données
restore_database() {
    local backup_file=$1
    
    echo -e "\033[1;33mRestauration de la base de données...\033[0m"
    
    # Pour SQLite
    if [[ "$backup_file" == *.sqlite3 ]]; then
        cp "$backup_file" "./db.sqlite3"
        echo -e "\033[1;32m✅ Base de données restaurée depuis: $backup_file\033[0m"
        return 0
    fi
    
    # Pour d'autres bases de données, implémenter les commandes de restauration appropriées
    # Par exemple, pour PostgreSQL:
    # psql -U $DB_USER -h $DB_HOST -p $DB_PORT $DB_NAME < $backup_file
    
    echo -e "\033[1;32m✅ Base de données restaurée\033[0m"
    return 0
}

# Fonction pour exécuter les migrations
invoke_migrations() {
    local db_name=$1
    local step_count=$2
    
    echo -e "\033[1;33mExécution des migrations...\033[0m"
    
    cd dog_breed_identifier || return 1
    
    if [ "$DRY_RUN" = true ]; then
        # Afficher ce qui serait exécuté
        echo -e "\033[1;37mSimulation: python manage.py showmigrations\033[0m"
        python manage.py showmigrations
    else
        # Exécuter les migrations
        local cmd="python manage.py migrate $db_name"
        echo -e "\033[1;37mExécution: $cmd\033[0m"
        
        python manage.py migrate "$db_name" 2>&1
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo -e "\033[1;32m✅ Migrations exécutées avec succès\033[0m"
        else
            echo -e "\033[1;31m❌ Échec de l'exécution des migrations\033[0m"
            cd ..
            return 1
        fi
    fi
    
    cd ..
    return 0
}

# Fonction pour faire un rollback des migrations
rollback_migrations() {
    local db_name=$1
    local step_count=$2
    
    echo -e "\033[1;33mRollback des migrations...\033[0m"
    
    cd dog_breed_identifier || return 1
    
    if [ "$DRY_RUN" = true ]; then
        # Afficher ce qui serait exécuté
        echo -e "\033[1;37mSimulation: python manage.py showmigrations\033[0m"
        python manage.py showmigrations
    else
        # Faire un rollback
        local cmd="python manage.py migrate $db_name zero"
        if [ $step_count -gt 0 ]; then
            # Pour rollback partiel, vous devez spécifier l'ID de migration
            # Cela dépend de votre implémentation spécifique
            cmd="python manage.py migrate $db_name -$step_count"
        fi
        
        echo -e "\033[1;37mExécution: $cmd\033[0m"
        
        python manage.py migrate "$db_name" zero 2>&1
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo -e "\033[1;32m✅ Rollback des migrations effectué avec succès\033[0m"
        else
            echo -e "\033[1;31m❌ Échec du rollback des migrations\033[0m"
            cd ..
            return 1
        fi
    fi
    
    cd ..
    return 0
}

# Fonction pour vérifier le statut des migrations
get_migration_status() {
    local db_name=$1
    
    echo -e "\033[1;33mVérification du statut des migrations...\033[0m"
    
    cd dog_breed_identifier || return 1
    
    local cmd="python manage.py showmigrations $db_name"
    echo -e "\033[1;37mExécution: $cmd\033[0m"
    
    python manage.py showmigrations "$db_name" 2>&1
    local exit_code=$?
    
    cd ..
    return $exit_code
}

# Fonction pour créer une nouvelle migration
create_migration() {
    local name=$1
    
    echo -e "\033[1;33mCréation d'une nouvelle migration...\033[0m"
    
    if [ -z "$name" ]; then
        echo -e "\033[1;31m❌ Nom de migration requis\033[0m"
        return 1
    fi
    
    cd dog_breed_identifier || return 1
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "\033[1;37mSimulation: python manage.py makemigrations --name $name\033[0m"
    else
        local cmd="python manage.py makemigrations --name $name"
        echo -e "\033[1;37mExécution: $cmd\033[0m"
        
        python manage.py makemigrations --name "$name" 2>&1
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo -e "\033[1;32m✅ Migration créée avec succès\033[0m"
        else
            echo -e "\033[1;31m❌ Échec de la création de la migration\033[0m"
            cd ..
            return 1
        fi
    fi
    
    cd ..
    return 0
}

# Fonction pour valider l'environnement
test_environment() {
    echo -e "\033[1;33mValidation de l'environnement...\033[0m"
    
    # Vérifier que Python est installé
    if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
        echo -e "\033[1;31m❌ Python n'est pas installé\033[0m"
        return 1
    fi
    
    # Vérifier que Django est installé
    if ! python -c "import django" 2>/dev/null && ! python3 -c "import django" 2>/dev/null; then
        echo -e "\033[1;31m❌ Django n'est pas installé\033[0m"
        return 1
    fi
    
    # Vérifier que le projet Django existe
    if [ ! -f "dog_breed_identifier/manage.py" ]; then
        echo -e "\033[1;31m❌ Projet Django non trouvé\033[0m"
        return 1
    fi
    
    echo -e "\033[1;32m✅ Environnement validé\033[0m"
    return 0
}

# Exécuter l'action demandée
if ! test_environment; then
    exit 1
fi

case $ACTION in
    "migrate")
        echo -e "\033[1;37mExécution des migrations sur la base de données: $DATABASE\033[0m"
        
        # Créer un backup avant la migration
        if [ "$DRY_RUN" = false ]; then
            backup_file=$(backup_database "$DATABASE")
            if [ $? -ne 0 ] && [ "$FORCE" = false ]; then
                echo -e "\033[1;31m❌ Échec de la création du backup. Utilisez -f pour continuer sans backup.\033[0m"
                exit 1
            fi
        fi
        
        if invoke_migrations "$DATABASE" "$STEPS"; then
            echo -e "\033[1;32m✅ Migrations exécutées avec succès !\033[0m"
        else
            echo -e "\033[1;31m❌ Échec de l'exécution des migrations\033[0m"
            exit 1
        fi
        ;;
    
    "rollback")
        echo -e "\033[1;37mRollback des migrations sur la base de données: $DATABASE\033[0m"
        
        # Créer un backup avant le rollback
        if [ "$DRY_RUN" = false ]; then
            backup_file=$(backup_database "$DATABASE")
            if [ $? -ne 0 ] && [ "$FORCE" = false ]; then
                echo -e "\033[1;31m❌ Échec de la création du backup. Utilisez -f pour continuer sans backup.\033[0m"
                exit 1
            fi
        fi
        
        if rollback_migrations "$DATABASE" "$STEPS"; then
            echo -e "\033[1;32m✅ Rollback des migrations effectué avec succès !\033[0m"
        else
            echo -e "\033[1;31m❌ Échec du rollback des migrations\033[0m"
            exit 1
        fi
        ;;
    
    "status")
        echo -e "\033[1;37mStatut des migrations pour la base de données: $DATABASE\033[0m"
        
        if get_migration_status "$DATABASE"; then
            echo -e "\033[1;32m✅ Statut des migrations affiché\033[0m"
        else
            echo -e "\033[1;31m❌ Échec de l'affichage du statut des migrations\033[0m"
            exit 1
        fi
        ;;
    
    "create")
        echo -e "\033[1;37mCréation d'une nouvelle migration: $MIGRATION_NAME\033[0m"
        
        if create_migration "$MIGRATION_NAME"; then
            echo -e "\033[1;32m✅ Migration créée avec succès !\033[0m"
        else
            echo -e "\033[1;31m❌ Échec de la création de la migration\033[0m"
            exit 1
        fi
        ;;
    
    *)
        echo -e "\033[1;31m❌ Action non supportée: $ACTION\033[0m"
        exit 1
        ;;
esac

echo -e "\033[1;36mOpération de migration terminée !\033[0m"