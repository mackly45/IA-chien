#!/bin/bash

# Script de backup du projet

BACKUP_DIR=${1:-"./backups"}

echo -e "\033[1;36mBackup du projet Dog Breed Identifier\033[0m"
echo -e "\033[1;36m===================================\033[0m"

# Créer le répertoire de backup s'il n'existe pas
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo -e "\033[1;33mCréation du répertoire de backup: $BACKUP_DIR\033[0m"
fi

# Générer un nom de fichier de backup avec timestamp
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUP_FILE_NAME="dog-breed-identifier-backup-$TIMESTAMP.zip"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE_NAME"

echo -e "\033[1;33mCréation du backup: $BACKUP_PATH\033[0m"

# Créer le backup en excluant les fichiers/dossiers non nécessaires
if command -v zip &> /dev/null; then
    zip -r "$BACKUP_PATH" . \
        -x "*.git*" \
        -x "*.venv*" \
        -x "*venv*" \
        -x "*__pycache__*" \
        -x "*.pyc" \
        -x "*.DS_Store" \
        -x "*Thumbs.db" \
        -x "*backups*" \
        -x "*node_modules*" \
        -x "*mediafiles*" \
        -x "*staticfiles*" \
        -x "*.log"
    
    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m✅ Backup créé avec succès !\033[0m"
        BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
        echo -e "\033[1;37mTaille du backup: $BACKUP_SIZE\033[0m"
    else
        echo -e "\033[1;31m❌ Échec de la création du backup\033[0m"
        exit 1
    fi
else
    echo -e "\033[1;31mzip n'est pas installé\033[0m"
    exit 1
fi

# Nettoyer les anciens backups (garder seulement les 5 derniers)
echo -e "\033[1;33mNettoyage des anciens backups...\033[0m"
cd "$BACKUP_DIR"
BACKUP_COUNT=$(ls -1 dog-breed-identifier-backup-*.zip 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 5 ]; then
    ls -1t dog-breed-identifier-backup-*.zip | tail -n +6 | xargs rm -f
    echo -e "\033[1;37mAnciens backups supprimés\033[0m"
fi

echo -e "\033[1;36mBackup terminé !\033[0m"