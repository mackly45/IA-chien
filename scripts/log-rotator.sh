#!/bin/bash

# Script de rotation des logs

# Paramètres par défaut
LOG_DIR="./logs"
MAX_SIZE_MB=10
RETENTION_DAYS=30
RETENTION_COUNT=10
COMPRESS=true
VERBOSE=false

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
MAX_SIZE_BYTES=$((MAX_SIZE_MB * 1024 * 1024))

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mRotation des logs\033[0m"
    echo -e "\033[1;36m===============\033[0m"
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
        -d|--dir)
            LOG_DIR="$2"
            shift 2
            ;;
        -s|--size)
            MAX_SIZE_MB="$2"
            MAX_SIZE_BYTES=$((MAX_SIZE_MB * 1024 * 1024))
            shift 2
            ;;
        -r|--retention-days)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        -c|--count)
            RETENTION_COUNT="$2"
            shift 2
            ;;
        --no-compress)
            COMPRESS=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -d, --dir DIR           Répertoire des logs (défaut: ./logs)"
            echo "  -s, --size MB           Taille maximale en MB (défaut: 10)"
            echo "  -r, --retention-days    Jours de rétention (défaut: 30)"
            echo "  -c, --count COUNT       Nombre maximum de fichiers (défaut: 10)"
            echo "  --no-compress           Ne pas compresser les fichiers"
            echo "  -v, --verbose           Mode verbeux"
            echo "  -h, --help              Afficher cette aide"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

print_header

# Fonction pour obtenir la taille d'un fichier
get_file_size() {
    local file_path=$1
    
    if [ -f "$file_path" ]; then
        stat -c %s "$file_path" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Fonction pour effectuer la rotation d'un fichier log
rotate_log() {
    local log_path=$1
    
    local log_name=$(basename "$log_path")
    local log_directory=$(dirname "$log_path")
    
    print_log "Rotation du fichier: $log_path" "INFO"
    
    # Créer un nouveau nom pour le fichier archivé
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local rotated_name="${log_name%.*}_${timestamp}.${log_name##*.}"
    local rotated_path="$log_directory/$rotated_name"
    
    # Renommer le fichier
    if mv "$log_path" "$rotated_path"; then
        # Compresser si demandé
        if [ "$COMPRESS" = true ]; then
            local compressed_path="${rotated_path}.gz"
            print_log "Compression du fichier..." "INFO"
            
            if gzip "$rotated_path"; then
                print_log "Fichier compressé: $compressed_path" "SUCCESS"
                echo "$compressed_path"
                return 0
            else
                print_log "Échec de la compression" "ERROR"
                return 1
            fi
        fi
        
        print_log "Fichier archivé: $rotated_path" "SUCCESS"
        echo "$rotated_path"
        return 0
    else
        print_log "Échec de la rotation du fichier $log_path" "ERROR"
        return 1
    fi
}

# Fonction pour nettoyer les anciens fichiers log
clean_old_logs() {
    local log_directory=$1
    local days=$2
    local max_count=$3
    
    if [ ! -d "$log_directory" ]; then
        print_log "Répertoire de logs non trouvé: $log_directory" "WARN"
        return 1
    fi
    
    print_log "Nettoyage des anciens fichiers log..." "INFO"
    
    # Obtenir tous les fichiers log archivés (avec timestamp)
    local log_files=()
    while IFS= read -r -d '' file; do
        log_files+=("$file")
    done < <(find "$log_directory" -type f -name "*_[0-9]*-[0-9]*.*" -print0 | sort -rz)
    
    local deleted_count=0
    
    # Supprimer les fichiers trop anciens
    local cutoff_date=$(date -d "$days days ago" +%s)
    
    for file in "${log_files[@]}"; do
        local file_date=$(stat -c %Y "$file")
        
        if [ $file_date -lt $cutoff_date ]; then
            rm -f "$file"
            print_log "Fichier supprimé (trop ancien): $(basename "$file")" "INFO"
            deleted_count=$((deleted_count + 1))
        fi
    done
    
    # Supprimer les fichiers en trop par rapport au nombre maximum
    local remaining_count=$(find "$log_directory" -type f -name "*_[0-9]*-[0-9]*.*" | wc -l)
    if [ $remaining_count -gt $max_count ]; then
        local files_to_delete=$((remaining_count - max_count))
        local deleted_files=0
        
        # Supprimer les fichiers les plus anciens
        while IFS= read -r -d '' file; do
            if [ $deleted_files -lt $files_to_delete ]; then
                rm -f "$file"
                print_log "Fichier supprimé (limite atteinte): $(basename "$file")" "INFO"
                deleted_files=$((deleted_files + 1))
                deleted_count=$((deleted_count + 1))
            fi
        done < <(find "$log_directory" -type f -name "*_[0-9]*-[0-9]*.*" -print0 | sort -rz)
    fi
    
    if [ $deleted_count -gt 0 ]; then
        print_log "Nettoyage terminé: $deleted_count fichiers supprimés" "SUCCESS"
    else
        print_log "Aucun fichier ancien à supprimer" "INFO"
    fi
}

# Fonction pour traiter un répertoire de logs
process_log_directory() {
    local directory=$1
    
    if [ ! -d "$directory" ]; then
        print_log "Répertoire non trouvé: $directory" "WARN"
        return 1
    fi
    
    print_log "Traitement du répertoire: $directory" "INFO"
    
    # Obtenir tous les fichiers log (exclure les fichiers déjà archivés)
    local log_files=()
    while IFS= read -r -d '' file; do
        # Vérifier que le fichier n'a pas déjà un timestamp
        local filename=$(basename "$file")
        if [[ ! $filename =~ _[0-9]{8}-[0-9]{6}\. ]]; then
            log_files+=("$file")
        fi
    done < <(find "$directory" -type f -print0)
    
    local rotated_count=0
    
    for file in "${log_files[@]}"; do
        local file_size=$(get_file_size "$file")
        
        # Vérifier si le fichier dépasse la taille maximale
        if [ $file_size -gt $MAX_SIZE_BYTES ]; then
            print_log "Fichier trop volumineux: $(basename "$file") ($(echo "scale=2; $file_size/1024/1024" | bc) MB)" "WARN"
            
            # Effectuer la rotation
            if rotate_log "$file"; then
                rotated_count=$((rotated_count + 1))
            fi
        else
            if [ "$VERBOSE" = true ]; then
                print_log "Fichier OK: $(basename "$file") ($(echo "scale=2; $file_size/1024/1024" | bc) MB)" "INFO"
            fi
        fi
    done
    
    if [ $rotated_count -gt 0 ]; then
        print_log "$rotated_count fichiers ont été archivés" "SUCCESS"
    fi
}

# Créer le répertoire de logs s'il n'existe pas
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    print_log "Répertoire de logs créé: $LOG_DIR" "INFO"
fi

# Traiter le répertoire de logs
process_log_directory "$LOG_DIR"

# Nettoyer les anciens fichiers log
clean_old_logs "$LOG_DIR" "$RETENTION_DAYS" "$RETENTION_COUNT"

print_log "Rotation des logs terminée !" "SUCCESS"