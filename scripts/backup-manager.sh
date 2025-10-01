#!/bin/bash

# Script de gestion des sauvegardes

# Paramètres par défaut
BACKUP_DIR="./backups"
SOURCE_DIRS="./dog_breed_identifier ./data ./media"
RETENTION_DAYS=30
COMPRESS=true
ENCRYPT=false
ENCRYPTION_KEY=""
VERIFY=true
LIST=false
CLEAN=false

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mGestion des sauvegardes\033[0m"
    echo -e "\033[1;36m===================\033[0m"
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
        -b|--backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -s|--source-dirs)
            SOURCE_DIRS="$2"
            shift 2
            ;;
        -r|--retention)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        --no-compress)
            COMPRESS=false
            shift
            ;;
        --encrypt)
            ENCRYPT=true
            shift
            ;;
        -k|--key)
            ENCRYPTION_KEY="$2"
            shift 2
            ;;
        --no-verify)
            VERIFY=false
            shift
            ;;
        -l|--list)
            LIST=true
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -b, --backup-dir DIR     Répertoire de sauvegarde (défaut: ./backups)"
            echo "  -s, --source-dirs DIRS   Répertoires source (défaut: ./dog_breed_identifier ./data ./media)"
            echo "  -r, --retention DAYS     Jours de rétention (défaut: 30)"
            echo "  --no-compress            Ne pas compresser les sauvegardes"
            echo "  --encrypt                Chiffrer les sauvegardes"
            echo "  -k, --key KEY            Clé de chiffrement"
            echo "  --no-verify              Ne pas vérifier les sauvegardes"
            echo "  -l, --list               Lister les sauvegardes"
            echo "  -c, --clean              Nettoyer les anciennes sauvegardes"
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

# Fonction pour créer une sauvegarde
create_backup() {
    local sources=$1
    local dest_dir=$2
    local timestamp=$3
    
    # Créer le répertoire de destination s'il n'existe pas
    if [ ! -d "$dest_dir" ]; then
        mkdir -p "$dest_dir"
        print_log "Répertoire de sauvegarde créé: $dest_dir" "INFO"
    fi
    
    # Créer le nom de la sauvegarde
    local backup_name="backup-$timestamp"
    local backup_path="$dest_dir/$backup_name"
    
    print_log "Création de la sauvegarde: $backup_name" "INFO"
    
    # Créer un répertoire pour la sauvegarde
    mkdir -p "$backup_path"
    
    # Convertir les sources en tableau
    IFS=' ' read -ra SOURCE_ARRAY <<< "$sources"
    
    # Copier chaque source
    for source in "${SOURCE_ARRAY[@]}"; do
        if [ -d "$source" ] || [ -f "$source" ]; then
            print_log "Sauvegarde de: $source" "INFO"
            
            # Déterminer le nom de destination
            local dest_path="$backup_path/$(basename "$source")"
            
            # Copier le contenu
            cp -r "$source" "$dest_path"
        else
            print_log "Source non trouvée: $source" "WARN"
        fi
    done
    
    # Compresser si demandé
    if [ "$COMPRESS" = true ]; then
        local compressed_path="${backup_path}.tar.gz"
        print_log "Compression de la sauvegarde..." "INFO"
        
        if tar -czf "$compressed_path" -C "$dest_dir" "$backup_name"; then
            rm -rf "$backup_path"
            print_log "Sauvegarde compressée: $compressed_path" "SUCCESS"
            echo "$compressed_path"
            return 0
        else
            print_log "Échec de la compression" "ERROR"
            return 1
        fi
    fi
    
    print_log "Sauvegarde créée: $backup_path" "SUCCESS"
    echo "$backup_path"
    return 0
}

# Fonction pour lister les sauvegardes
list_backups() {
    local backup_directory=$1
    
    if [ ! -d "$backup_directory" ]; then
        print_log "Répertoire de sauvegarde non trouvé: $backup_directory" "WARN"
        return 1
    fi
    
    print_log "Liste des sauvegardes dans $backup_directory" "INFO"
    
    # Lister les fichiers de sauvegarde
    local backup_count=0
    for backup_file in "$backup_directory"/*; do
        if [ -f "$backup_file" ]; then
            local file_size=$(du -h "$backup_file" | cut -f1)
            local file_date=$(stat -c %y "$backup_file" | cut -d' ' -f1)
            echo "  $(basename "$backup_file") - Taille: $file_size - Date: $file_date"
            backup_count=$((backup_count + 1))
        fi
    done
    
    if [ $backup_count -eq 0 ]; then
        print_log "Aucune sauvegarde trouvée" "INFO"
    else
        print_log "$backup_count sauvegardes trouvées" "INFO"
    fi
}

# Fonction pour nettoyer les anciennes sauvegardes
clean_old_backups() {
    local backup_directory=$1
    local days=$2
    
    if [ ! -d "$backup_directory" ]; then
        print_log "Répertoire de sauvegarde non trouvé: $backup_directory" "WARN"
        return 1
    fi
    
    local cutoff_date=$(date -d "$days days ago" +%s)
    local deleted_count=0
    
    print_log "Nettoyage des sauvegardes plus anciennes que $days jours..." "INFO"
    
    for backup_file in "$backup_directory"/*; do
        if [ -f "$backup_file" ]; then
            local file_date=$(stat -c %Y "$backup_file")
            
            if [ $file_date -lt $cutoff_date ]; then
                rm -f "$backup_file"
                print_log "Sauvegarde supprimée: $(basename "$backup_file")" "INFO"
                deleted_count=$((deleted_count + 1))
            fi
        fi
    done
    
    if [ $deleted_count -gt 0 ]; then
        print_log "Nettoyage terminé: $deleted_count sauvegardes supprimées" "SUCCESS"
    else
        print_log "Aucune sauvegarde ancienne à supprimer" "INFO"
    fi
}

# Fonction pour vérifier une sauvegarde
verify_backup() {
    local backup_path=$1
    
    if [ ! -f "$backup_path" ]; then
        print_log "Sauvegarde non trouvée: $backup_path" "ERROR"
        return 1
    fi
    
    # Vérifier l'intégrité de l'archive si c'est un fichier tar.gz
    if [[ "$backup_path" == *.tar.gz ]]; then
        print_log "Vérification de l'archive..." "INFO"
        
        if tar -tzf "$backup_path" > /dev/null 2>&1; then
            print_log "Sauvegarde vérifiée avec succès: $backup_path" "SUCCESS"
            return 0
        else
            print_log "Sauvegarde corrompue: $backup_path" "ERROR"
            return 1
        fi
    else
        # Pour les sauvegardes non compressées, vérifier l'existence
        if [ -d "$backup_path" ]; then
            print_log "Sauvegarde vérifiée avec succès: $backup_path" "SUCCESS"
            return 0
        else
            print_log "Sauvegarde non trouvée: $backup_path" "ERROR"
            return 1
        fi
    fi
}

# Fonction pour restaurer une sauvegarde
restore_backup() {
    local backup_path=$1
    local restore_dir=$2
    
    if [ ! -f "$backup_path" ]; then
        print_log "Sauvegarde non trouvée: $backup_path" "ERROR"
        return 1
    fi
    
    print_log "Restauration de la sauvegarde: $backup_path" "INFO"
    
    # Créer le répertoire de restauration s'il n'existe pas
    mkdir -p "$restore_dir"
    
    # Extraire ou copier la sauvegarde
    if [[ "$backup_path" == *.tar.gz ]]; then
        if tar -xzf "$backup_path" -C "$restore_dir"; then
            print_log "Sauvegarde restaurée dans: $restore_dir" "SUCCESS"
            return 0
        else
            print_log "Échec de la restauration" "ERROR"
            return 1
        fi
    else
        if cp -r "$backup_path" "$restore_dir"; then
            print_log "Sauvegarde restaurée dans: $restore_dir" "SUCCESS"
            return 0
        else
            print_log "Échec de la restauration" "ERROR"
            return 1
        fi
    fi
}

# Mode liste
if [ "$LIST" = true ]; then
    list_backups "$BACKUP_DIR"
    exit 0
fi

# Mode nettoyage
if [ "$CLEAN" = true ]; then
    clean_old_backups "$BACKUP_DIR" "$RETENTION_DAYS"
    exit 0
fi

# Obtenir le timestamp
timestamp=$(date +"%Y%m%d-%H%M%S")

# Créer une sauvegarde
print_log "Création d'une sauvegarde des répertoires: $SOURCE_DIRS" "INFO"
backup_result=$(create_backup "$SOURCE_DIRS" "$BACKUP_DIR" "$timestamp")

if [ $? -eq 0 ] && [ -n "$backup_result" ]; then
    # Vérifier la sauvegarde si demandé
    if [ "$VERIFY" = true ]; then
        print_log "Vérification de la sauvegarde..." "INFO"
        
        if verify_backup "$backup_result"; then
            print_log "Sauvegarde vérifiée avec succès" "SUCCESS"
        else
            print_log "Échec de la vérification de la sauvegarde" "ERROR"
            exit 1
        fi
    fi
    
    # Nettoyer les anciennes sauvegardes
    clean_old_backups "$BACKUP_DIR" "$RETENTION_DAYS"
    
    print_log "Sauvegarde terminée avec succès !" "SUCCESS"
else
    print_log "Échec de la sauvegarde" "ERROR"
    exit 1
fi