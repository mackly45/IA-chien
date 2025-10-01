#!/bin/bash

# Script de surveillance de l'entraînement du modèle

# Paramètres par défaut
POLLING_INTERVAL=30
MAX_DURATION=3600
LOG_DIR="./logs"
NOTIFY=false

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mSurveillance de l'entraînement du modèle\033[0m"
    echo -e "\033[1;36m===================================\033[0m"
}

print_log() {
    local message=$1
    local level=${2:-"INFO"}
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_message="[$timestamp] [$level] $message"
    
    # Afficher dans la console
    case $level in
        "INFO")
            echo -e "\033[1;37m$log_message\033[0m"
            ;;
        "WARN")
            echo -e "\033[1;33m$log_message\033[0m"
            ;;
        "ERROR")
            echo -e "\033[1;31m$log_message\033[0m"
            ;;
        "SUCCESS")
            echo -e "\033[1;32m$log_message\033[0m"
            ;;
    esac
    
    # Écrire dans le fichier de log
    if [ -d "$LOG_DIR" ]; then
        echo "$log_message" >> "$LOG_DIR/training.log"
    fi
}

# Analyse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interval)
            POLLING_INTERVAL="$2"
            shift 2
            ;;
        -d|--duration)
            MAX_DURATION="$2"
            shift 2
            ;;
        -l|--log-dir)
            LOG_DIR="$2"
            shift 2
            ;;
        -n|--notify)
            NOTIFY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -i, --interval SECONDS   Intervalle de polling (défaut: 30)"
            echo "  -d, --duration SECONDS   Durée maximale (défaut: 3600)"
            echo "  -l, --log-dir DIR        Répertoire de logs (défaut: ./logs)"
            echo "  -n, --notify             Envoyer des notifications"
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

# Fonction pour envoyer une notification
send_notification() {
    local title=$1
    local message=$2
    
    if [ "$NOTIFY" = true ]; then
        # Sur Linux, utiliser notify-send si disponible
        if command -v notify-send &> /dev/null; then
            notify-send "$title" "$message"
        else
            print_log "notify-send non disponible, notification ignorée" "WARN"
        fi
    fi
}

# Fonction pour récupérer les statistiques d'entraînement
get_training_stats() {
    # Dans une implémentation réelle, cela ferait un appel API à l'application
    # Pour cette simulation, nous générons des statistiques aléatoires
    
    # Générer des valeurs aléatoires
    epoch=$((RANDOM % 50 + 1))
    loss=$(awk -v min=0.1 -v max=2.0 'BEGIN{srand(); print min+rand()*(max-min)}')
    accuracy=$(awk -v min=0.7 -v max=0.95 'BEGIN{srand(); print min+rand()*(max-min)}')
    val_loss=$(awk -v min=0.2 -v max=2.5 'BEGIN{srand(); print min+rand()*(max-min)}')
    val_accuracy=$(awk -v min=0.6 -v max=0.9 'BEGIN{srand(); print min+rand()*(max-min)}')
    learning_rate=$(awk -v min=0.0001 -v max=0.01 'BEGIN{srand(); print min+rand()*(max-min)}')
    
    # Créer un JSON avec les statistiques
    cat << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "epoch": $epoch,
  "loss": $loss,
  "accuracy": $accuracy,
  "val_loss": $val_loss,
  "val_accuracy": $val_accuracy,
  "learning_rate": $learning_rate
}
EOF
}

# Fonction pour afficher les statistiques
show_training_stats() {
    local stats_json=$1
    
    # Extraire les valeurs du JSON
    epoch=$(echo "$stats_json" | jq -r '.epoch')
    loss=$(echo "$stats_json" | jq -r '.loss')
    accuracy=$(echo "$stats_json" | jq -r '.accuracy')
    val_loss=$(echo "$stats_json" | jq -r '.val_loss')
    val_accuracy=$(echo "$stats_json" | jq -r '.val_accuracy')
    
    echo "  Époque: $epoch"
    echo "  Précision: $(printf "%.2f%%" $(echo "$accuracy*100" | bc -l))"
    echo "  Précision validation: $(printf "%.2f%%" $(echo "$val_accuracy*100" | bc -l))"
    echo "  Perte: $(printf "%.4f" $loss)"
    echo "  Perte validation: $(printf "%.4f" $val_loss)"
}

# Créer le répertoire de logs s'il n'existe pas
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    print_log "Répertoire de logs créé: $LOG_DIR" "INFO"
fi

# Initialiser la surveillance
start_time=$(date +%s)
end_time=$((start_time + MAX_DURATION))

print_log "Démarrage de la surveillance de l'entraînement" "INFO"
print_log "Intervalle de polling: ${POLLING_INTERVAL}s" "INFO"
print_log "Durée maximale: ${MAX_DURATION}s" "INFO"
send_notification "Surveillance démarrée" "La surveillance de l'entraînement du modèle a commencé"

# Boucle de surveillance
iteration=0
while [ $(date +%s) -lt $end_time ]; do
    iteration=$((iteration + 1))
    print_log "Vérification #$iteration..." "INFO"
    
    # Récupérer les statistiques d'entraînement
    stats=$(get_training_stats)
    
    if [ -n "$stats" ]; then
        # Afficher les statistiques
        show_training_stats "$stats"
        
        # Enregistrer les statistiques dans un fichier JSON
        echo "$stats" > "$LOG_DIR/training-stats.json"
        
        # Vérifier si l'entraînement est terminé (simulation)
        epoch=$(echo "$stats" | jq -r '.epoch')
        if [ "$epoch" -ge 50 ]; then
            print_log "Entraînement terminé!" "SUCCESS"
            send_notification "Entraînement terminé" "Le modèle a atteint l'époque 50"
            break
        fi
        
        # Vérifier s'il y a des problèmes (simulation)
        loss=$(echo "$stats" | jq -r '.loss')
        val_loss=$(echo "$stats" | jq -r '.val_loss')
        
        if (( $(echo "$loss > 2.0" | bc -l) )) || (( $(echo "$val_loss > 3.0" | bc -l) )); then
            print_log "Problème détecté: Perte élevée" "WARN"
            send_notification "Problème d'entraînement" "Perte élevée détectée"
        fi
    else
        print_log "Impossible de récupérer les statistiques" "ERROR"
    fi
    
    # Attendre avant la prochaine vérification
    sleep $POLLING_INTERVAL
done

# Terminer la surveillance
duration=$(($(date +%s) - start_time))
print_log "Surveillance terminée après $duration secondes" "INFO"
send_notification "Surveillance terminée" "La surveillance de l'entraînement est terminée"