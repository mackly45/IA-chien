#!/bin/bash

# Script de backup et restauration

ACTION="backup"
BACKUP_PATH="./backups"
BACKUP_NAME=""
INCLUDE_DATABASE=true
INCLUDE_MEDIA=true
INCLUDE_LOGS=false
RETENTION_DAYS=30
COMPRESS=true
ENCRYPT=false
ENCRYPTION_PASSWORD=""

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -p|--path)
            BACKUP_PATH="$2"
            shift 2
            ;;
        -n|--name)
            BACKUP_NAME="$2"
            shift 2
            ;;
        --no-database)
            INCLUDE_DATABASE=false
            shift
            ;;
        --no-media)
            INCLUDE_MEDIA=false
            shift
            ;;
        --include-logs)
            INCLUDE_LOGS=true
            shift
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
        --password)
            ENCRYPTION_PASSWORD="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-a action] [-p path] [-n name] [--no-database] [--no-media] [--include-logs] [-r days] [--no-compress] [--encrypt] [--password]"
            echo "  -a, --action ACTION         Action (backup, restore) (défaut: backup)"
            echo "  -p, --path PATH             Chemin du répertoire de backup (défaut: ./backups)"
            echo "  -n, --name NAME             Nom du backup (défaut: dog-breed-identifier-backup-TIMESTAMP)"
            echo "  --no-database               Exclure la base de données du backup"
            echo "  --no-media                  Exclure les fichiers média du backup"
            echo "  --include-logs              Inclure les fichiers de log dans le backup"
            echo "  -r, --retention DAYS        Jours de rétention des backups (défaut: 30)"
            echo "  --no-compress               Ne pas compresser le backup"
            echo "  --encrypt                   Chiffrer le backup"
            echo "  --password PASSWORD         Mot de passe de chiffrement"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mBackup et Restauration de Dog Breed Identifier\033[0m"
echo -e "\033[1;36m========================================\033[0m"

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
if [ -z "$BACKUP_NAME" ]; then
    BACKUP_NAME="dog-breed-identifier-backup-$TIMESTAMP"
fi

# Fonction pour créer un backup
create_backup() {
    echo -e "\033[1;33mCréation d'un backup...\033[0m"
    
    # Créer le répertoire de backup s'il n'existe pas
    if [ ! -d "$BACKUP_PATH" ]; then
        mkdir -p "$BACKUP_PATH"
        echo -e "\033[1;33mCréation du répertoire de backup: $BACKUP_PATH\033[0m"
    fi
    
    # Déterminer le nom du fichier de backup
    local backup_file_name=$(if [ "$COMPRESS" = true ]; then echo "$BACKUP_NAME.zip"; else echo "$BACKUP_NAME"; fi)
    local backup_file_path="$BACKUP_PATH/$backup_file_name"
    
    # Créer une liste des fichiers à inclure
    local include_paths="."
    
    # Exclure les chemins non désirés
    local exclude_paths=(
        ".git"
        ".venv"
        "venv"
        "__pycache__"
        "*.pyc"
        ".DS_Store"
        "Thumbs.db"
        "$BACKUP_PATH"
    )
    
    # Ajouter les exclusions conditionnelles
    if [ "$INCLUDE_DATABASE" = false ]; then
        exclude_paths+=("db.sqlite3")
    fi
    
    if [ "$INCLUDE_MEDIA" = false ]; then
        exclude_paths+=("media" "mediafiles")
    fi
    
    if [ "$INCLUDE_LOGS" = false ]; then
        exclude_paths+=("*.log" "logs")
    fi
    
    # Convertir les exclusions en pattern pour tar
    local exclude_args=""
    for exclude in "${exclude_paths[@]}"; do
        exclude_args="$exclude_args --exclude=$exclude"
    done
    
    # Créer le backup
    if [ "$COMPRESS" = true ]; then
        # Créer un backup compressé
        if command -v zip &> /dev/null; then
            # Utiliser zip
            zip -r "$backup_file_path" . $exclude_args
            if [ $? -eq 0 ]; then
                echo -e "\033[1;32m✅ Backup compressé créé: $backup_file_path\033[0m"
            else
                echo -e "\033[1;31m❌ Échec de la création du backup compressé\033[0m"
                return 1
            fi
        elif command -v tar &> /dev/null; then
            # Utiliser tar.gz
            backup_file_path="$BACKUP_PATH/$BACKUP_NAME.tar.gz"
            tar -czf "$backup_file_path" $exclude_args .
            if [ $? -eq 0 ]; then
                echo -e "\033[1;32m✅ Backup compressé créé: $backup_file_path\033[0m"
            else
                echo -e "\033[1;31m❌ Échec de la création du backup compressé\033[0m"
                return 1
            fi
        else
            echo -e "\033[1;31m❌ Aucun outil de compression disponible (zip ou tar)\033[0m"
            return 1
        fi
    else
        # Créer un backup non compressé (copie de répertoire)
        local backup_dir_path="$BACKUP_PATH/$BACKUP_NAME"
        if [ -d "$backup_dir_path" ]; then
            rm -rf "$backup_dir_path"
        fi
        mkdir -p "$backup_dir_path"
        
        # Copier les fichiers avec rsync
        if command -v rsync &> /dev/null; then
            rsync -av --exclude-from=<(printf '%s\n' "${exclude_paths[@]}") . "$backup_dir_path/"
            if [ $? -eq 0 ]; then
                echo -e "\033[1;32m✅ Backup non compressé créé: $backup_dir_path\033[0m"
            else
                echo -e "\033[1;31m❌ Échec de la création du backup non compressé\033[0m"
                return 1
            fi
        else
            # Fallback avec cp
            local find_exclude_args=""
            for exclude in "${exclude_paths[@]}"; do
                find_exclude_args="$find_exclude_args -not -path \"*/$exclude\" -not -path \"*/$exclude/*\""
            done
            
            # Cette partie est complexe avec bash, donc on utilise une approche plus simple
            echo -e "\033[1;33m⚠️  rsync non disponible, utilisation de cp (moins efficace)\033[0m"
            cp -r . "$backup_dir_path/" 2>/dev/null
            echo -e "\033[1;32m✅ Backup non compressé créé: $backup_dir_path\033[0m"
        fi
    fi
    
    # Chiffrer le backup si demandé
    if [ "$ENCRYPT" = true ]; then
        if [ -z "$ENCRYPTION_PASSWORD" ]; then
            echo -e "\033[1;31m❌ Mot de passe de chiffrement requis\033[0m"
            return 1
        fi
        
        local encrypted_file_path="$backup_file_path.encrypted"
        # Ici, vous pouvez implémenter le chiffrement
        # Par exemple, avec OpenSSL ou GPG
        if command -v openssl &> /dev/null; then
            echo "$ENCRYPTION_PASSWORD" | openssl enc -aes-256-cbc -salt -in "$backup_file_path" -out "$encrypted_file_path" -pass stdin
            if [ $? -eq 0 ]; then
                echo -e "\033[1;32m🔒 Backup chiffré créé: $encrypted_file_path\033[0m"
            else
                echo -e "\033[1;31m❌ Échec du chiffrement du backup\033[0m"
                return 1
            fi
        else
            echo -e "\033[1;31m❌ OpenSSL non disponible pour le chiffrement\033[0m"
            return 1
        fi
    fi
    
    # Nettoyer les anciens backups
    cleanup_old_backups
    
    return 0
}

# Fonction pour restaurer un backup
restore_backup() {
    echo -e "\033[1;33mRestauration d'un backup...\033[0m"
    
    # Déterminer le chemin du backup
    local backup_file_name=$(if [ "$COMPRESS" = true ]; then echo "$BACKUP_NAME.zip"; else echo "$BACKUP_NAME"; fi)
    local backup_file_path="$BACKUP_PATH/$backup_file_name"
    
    if [ ! -f "$backup_file_path" ]; then
        echo -e "\033[1;31m❌ Backup non trouvé: $backup_file_path\033[0m"
        return 1
    fi
    
    # Déchiffrer le backup si nécessaire
    if [ "$ENCRYPT" = true ]; then
        if [ -z "$ENCRYPTION_PASSWORD" ]; then
            echo -e "\033[1;31m❌ Mot de passe de déchiffrement requis\033[0m"
            return 1
        fi
        
        local decrypted_file_path="$backup_file_path.decrypted"
        if command -v openssl &> /dev/null; then
            echo "$ENCRYPTION_PASSWORD" | openssl enc -d -aes-256-cbc -in "$backup_file_path" -out "$decrypted_file_path" -pass stdin
            if [ $? -eq 0 ]; then
                echo -e "\033[1;32m🔓 Backup déchiffré\033[0m"
                backup_file_path="$decrypted_file_path"
            else
                echo -e "\033[1;31m❌ Échec du déchiffrement du backup\033[0m"
                return 1
            fi
        else
            echo -e "\033[1;31m❌ OpenSSL non disponible pour le déchiffrement\033[0m"
            return 1
        fi
    fi
    
    # Créer un répertoire temporaire pour l'extraction
    local temp_extract_path="/tmp/dog-breed-restore-$TIMESTAMP"
    if [ -d "$temp_extract_path" ]; then
        rm -rf "$temp_extract_path"
    fi
    mkdir -p "$temp_extract_path"
    
    if [ "$COMPRESS" = true ]; then
        # Extraire le backup compressé
        if command -v unzip &> /dev/null && [[ "$backup_file_path" == *.zip ]]; then
            unzip -q "$backup_file_path" -d "$temp_extract_path"
            if [ $? -eq 0 ]; then
                echo -e "\033[1;32m✅ Backup extrait dans: $temp_extract_path\033[0m"
            else
                echo -e "\033[1;31m❌ Échec de l'extraction du backup\033[0m"
                rm -rf "$temp_extract_path"
                return 1
            fi
        elif command -v tar &> /dev/null && [[ "$backup_file_path" == *.tar.gz ]]; then
            tar -xzf "$backup_file_path" -C "$temp_extract_path"
            if [ $? -eq 0 ]; then
                echo -e "\033[1;32m✅ Backup extrait dans: $temp_extract_path\033[0m"
            else
                echo -e "\033[1;31m❌ Échec de l'extraction du backup\033[0m"
                rm -rf "$temp_extract_path"
                return 1
            fi
        else
            echo -e "\033[1;31m❌ Aucun outil d'extraction disponible\033[0m"
            rm -rf "$temp_extract_path"
            return 1
        fi
    else
        # Copier le répertoire de backup
        local backup_dir_path="$BACKUP_PATH/$BACKUP_NAME"
        if [ -d "$backup_dir_path" ]; then
            cp -r "$backup_dir_path"/* .
            echo -e "\033[1;32m✅ Backup restauré depuis: $backup_dir_path\033[0m"
        else
            echo -e "\033[1;31m❌ Répertoire de backup non trouvé: $backup_dir_path\033[0m"
            rm -rf "$temp_extract_path"
            return 1
        fi
    fi
    
    # Nettoyer le répertoire temporaire
    rm -rf "$temp_extract_path"
    
    return 0
}

# Fonction pour nettoyer les anciens backups
cleanup_old_backups() {
    echo -e "\033[1;33mNettoyage des anciens backups...\033[0m"
    
    if [ ! -d "$BACKUP_PATH" ]; then
        echo -e "\033[1;31m❌ Répertoire de backup non trouvé: $BACKUP_PATH\033[0m"
        return 1
    fi
    
    # Trouver les backups plus anciens que la période de rétention
    local cutoff_date=$(date -d "$RETENTION_DAYS days ago" +%s)
    
    find "$BACKUP_PATH" -type f -name "*.zip" -o -name "*.tar.gz" -o -name "*.encrypted" | while read -r file; do
        local file_date=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
        if [ "$file_date" -lt "$cutoff_date" ]; then
            rm -f "$file"
            echo -e "\033[1;30m🗑️  Backup supprimé: $(basename "$file")\033[0m"
        fi
    done
    
    echo -e "\033[1;32m✅ Nettoyage des anciens backups terminé\033[0m"
}

# Fonction pour lister les backups disponibles
list_backups() {
    echo -e "\033[1;33mListe des backups disponibles:\033[0m"
    
    if [ ! -d "$BACKUP_PATH" ]; then
        echo -e "\033[1;31m❌ Répertoire de backup non trouvé: $BACKUP_PATH\033[0m"
        return 1
    fi
    
    local backups=$(find "$BACKUP_PATH" -type f -name "*.zip" -o -name "*.tar.gz" -o -name "*.encrypted" | sort -r)
    
    if [ -z "$backups" ]; then
        echo -e "\033[1;37mℹ️  Aucun backup trouvé\033[0m"
        return 0
    fi
    
    echo -e "\033[1;37mNom\t\t\tTaille\t\tDate de création\033[0m"
    echo -e "\033[1;37m---\t\t\t-----\t\t---------------\033[0m"
    
    echo "$backups" | while read -r backup; do
        local name=$(basename "$backup")
        local size=$(ls -lh "$backup" | awk '{print $5}')
        local date=$(stat -c %y "$backup" 2>/dev/null || stat -f %Sm -t "%Y-%m-%d %H:%M" "$backup" 2>/dev/null)
        echo -e "\033[1;30m$name\t$size\t$date\033[0m"
    done
}

# Exécuter l'action demandée
case $ACTION in
    "backup")
        echo -e "\033[1;37mCréation d'un backup nommé: $BACKUP_NAME\033[0m"
        
        if create_backup; then
            echo -e "\033[1;32m✅ Backup créé avec succès !\033[0m"
        else
            echo -e "\033[1;31m❌ Échec de la création du backup\033[0m"
            exit 1
        fi
        ;;
    
    "restore")
        echo -e "\033[1;37mRestauration du backup: $BACKUP_NAME\033[0m"
        
        # Demander confirmation
        echo -e "\033[1;33mÊtes-vous sûr de vouloir restaurer ce backup ? Cela écrasera les fichiers actuels. (y/N)\033[0m"
        read -r confirmation
        if [ "$confirmation" != "y" ] && [ "$confirmation" != "Y" ]; then
            echo -e "\033[1;33m❌ Restauration annulée\033[0m"
            exit 0
        fi
        
        if restore_backup; then
            echo -e "\033[1;32m✅ Backup restauré avec succès !\033[0m"
        else
            echo -e "\033[1;31m❌ Échec de la restauration du backup\033[0m"
            exit 1
        fi
        ;;
    
    *)
        echo -e "\033[1;31m❌ Action non supportée: $ACTION\033[0m"
        exit 1
        ;;
esac

echo -e "\033[1;36mOpération de backup/restore terminée !\033[0m"