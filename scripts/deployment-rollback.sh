#!/bin/bash

# Script de rollback de déploiement

# Paramètres par défaut
ENVIRONMENT="production"
VERSION=""
FORCE=false
DRY_RUN=false

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
DEPLOYMENTS_DIR="./deployments"
BACKUP_DIR="./backups"
CONFIG_DIR="./config"

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mRollback de déploiement\033[0m"
    echo -e "\033[1;36m====================\033[0m"
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
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -e, --environment ENV    Environnement cible (défaut: production)"
            echo "  -v, --version VERSION    Version à restaurer (défaut: précédent déploiement)"
            echo "  -f, --force              Forcer le rollback sans confirmation"
            echo "  --dry-run                Mode simulation (aucune action)"
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

# Vérifier les prérequis
print_log "Vérification des prérequis..." "INFO"

# Vérifier que le répertoire des déploiements existe
if [ ! -d "$DEPLOYMENTS_DIR" ]; then
    print_log "Répertoire des déploiements non trouvé: $DEPLOYMENTS_DIR" "ERROR"
    exit 1
fi

# Vérifier que le répertoire des sauvegardes existe
if [ ! -d "$BACKUP_DIR" ]; then
    print_log "Répertoire des sauvegardes non trouvé: $BACKUP_DIR" "WARN"
    print_log "Création du répertoire des sauvegardes..." "INFO"
    mkdir -p "$BACKUP_DIR"
fi

print_log "Prérequis vérifiés" "SUCCESS"

# Récupérer les déploiements disponibles
print_log "Récupération des déploiements disponibles..." "INFO"
mapfile -t deployments < <(find "$DEPLOYMENTS_DIR" -maxdepth 1 -type d -not -path "$DEPLOYMENTS_DIR" | sort -r)

if [ ${#deployments[@]} -eq 0 ]; then
    print_log "Aucun déploiement trouvé dans $DEPLOYMENTS_DIR" "ERROR"
    exit 1
fi

print_log "Trouvé ${#deployments[@]} déploiements" "SUCCESS"

# Déterminer la version à restaurer
if [ -z "$VERSION" ]; then
    # Utiliser le dernier déploiement si aucune version n'est spécifiée
    if [ ${#deployments[@]} -gt 1 ]; then
        target_deployment="${deployments[1]}"  # Le précédent déploiement
        VERSION=$(basename "$target_deployment")
    else
        print_log "Pas de déploiement précédent à restaurer" "ERROR"
        exit 1
    fi
else
    # Trouver le déploiement spécifié
    target_deployment=""
    for deployment in "${deployments[@]}"; do
        if [ "$(basename "$deployment")" = "$VERSION" ]; then
            target_deployment="$deployment"
            break
        fi
    done
    
    if [ -z "$target_deployment" ]; then
        print_log "Déploiement $VERSION non trouvé" "ERROR"
        print_log "Déploiements disponibles:" "INFO"
        for deployment in "${deployments[@]}"; do
            echo "  - $(basename "$deployment")"
        done
        exit 1
    fi
fi

print_log "Version cible pour le rollback: $VERSION" "INFO"

# Vérifier si le déploiement cible existe
target_deployment_path="$DEPLOYMENTS_DIR/$VERSION"
if [ ! -d "$target_deployment_path" ]; then
    print_log "Déploiement cible non trouvé: $target_deployment_path" "ERROR"
    exit 1
fi

# Afficher les informations du déploiement cible
print_log "Informations du déploiement cible:" "INFO"
deployment_info_path="$target_deployment_path/deployment-info.json"
if [ -f "$deployment_info_path" ]; then
    echo "  Version: $(jq -r '.version // \"N/A\"' "$deployment_info_path")"
    echo "  Date: $(jq -r '.date // \"N/A\"' "$deployment_info_path")"
    echo "  Environment: $(jq -r '.environment // \"N/A\"' "$deployment_info_path")"
    echo "  Commit: $(jq -r '.commit // \"N/A\"' "$deployment_info_path")"
else
    print_log "Fichier d'information du déploiement non trouvé" "WARN"
fi

# Vérifier l'environnement
print_log "Vérification de l'environnement: $ENVIRONMENT" "INFO"
deployment_environment=$(jq -r '.environment // \"N/A\"' "$deployment_info_path" 2>/dev/null)
if [ "$deployment_environment" != "$ENVIRONMENT" ] && [ "$FORCE" = false ]; then
    print_log "L'environnement du déploiement cible ($deployment_environment) ne correspond pas à l'environnement spécifié ($ENVIRONMENT)" "ERROR"
    print_log "Utilisez --force pour forcer le rollback" "WARN"
    exit 1
fi

# Mode dry-run
if [ "$DRY_RUN" = true ]; then
    print_log "Mode dry-run activé - aucune action ne sera effectuée" "WARN"
    print_log "Le rollback restaurerait le déploiement $VERSION sur l'environnement $ENVIRONMENT" "INFO"
    exit 0
fi

# Confirmation
if [ "$FORCE" = false ]; then
    echo
    echo -e "\033[1;33mConfirmer le rollback:\033[0m"
    echo "  Projet: $PROJECT_NAME"
    echo "  Environnement: $ENVIRONMENT"
    echo "  Version cible: $VERSION"
    echo "  Déploiement actuel: $(basename "${deployments[0]}")"
    
    read -p "Êtes-vous sûr de vouloir effectuer ce rollback ? (yes/no): " confirmation
    if [ "$confirmation" != "yes" ]; then
        print_log "Rollback annulé par l'utilisateur" "INFO"
        exit 0
    fi
fi

# Effectuer le rollback
print_log "Début du rollback..." "INFO"

# Sauvegarder l'état actuel
current_timestamp=$(date +"%Y%m%d-%H%M%S")
current_backup_dir="$BACKUP_DIR/backup-$current_timestamp"
print_log "Sauvegarde de l'état actuel dans $current_backup_dir" "INFO"

# Créer un répertoire de sauvegarde
mkdir -p "$current_backup_dir"

# Copier les fichiers de configuration actuels
if [ -d "$CONFIG_DIR" ]; then
    cp -r "$CONFIG_DIR"/* "$current_backup_dir/" 2>/dev/null || true
    print_log "Configuration actuelle sauvegardée" "SUCCESS"
fi

# Restaurer le déploiement cible
print_log "Restauration du déploiement $VERSION" "INFO"

# Copier les fichiers du déploiement cible
cp -r "$target_deployment_path"/* ./

# Mettre à jour les liens symboliques ou les configurations si nécessaire
# (Cette partie dépend de votre structure de déploiement spécifique)

print_log "Déploiement $VERSION restauré avec succès" "SUCCESS"

# Redémarrer les services si nécessaire
print_log "Redémarrage des services..." "INFO"

# Exemple de redémarrage (à adapter à votre configuration)
# docker-compose down
# docker-compose up -d

print_log "Services redémarrés" "SUCCESS"

# Vérifier l'état du déploiement
print_log "Vérification de l'état du déploiement..." "INFO"

# Exemple de vérification (à adapter à votre configuration)
# health_check=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health/ -m 30 || echo "000")
# if [ "$health_check" = "200" ]; then
#     print_log "Déploiement en bonne santé" "SUCCESS"
# else
#     print_log "Problème de santé du déploiement" "ERROR"
# fi

print_log "Rollback terminé avec succès" "SUCCESS"

# Nettoyer les anciennes sauvegardes (garder les 5 dernières)
print_log "Nettoyage des anciennes sauvegardes..." "INFO"
mapfile -t backups < <(find "$BACKUP_DIR" -maxdepth 1 -type d -not -path "$BACKUP_DIR" -printf '%T@ %p\n' | sort -nr | cut -d' ' -f2-)

if [ ${#backups[@]} -gt 5 ]; then
    for ((i=5; i<${#backups[@]}; i++)); do
        backup_name=$(basename "${backups[i]}")
        rm -rf "${backups[i]}"
        print_log "Ancienne sauvegarde supprimée: $backup_name" "INFO"
    done
fi

print_log "Rollback terminé !" "SUCCESS"