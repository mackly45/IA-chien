#!/bin/bash

# Script de surveillance du déploiement

# Paramètres par défaut
DEPLOYMENT_URL="http://localhost:8000"
POLLING_INTERVAL=30
MAX_DURATION=3600
LOG_DIR="./logs"
NOTIFY=false
VERBOSE=false

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mSurveillance du déploiement\033[0m"
    echo -e "\033[1;36m========================\033[0m"
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
        echo "$log_message" >> "$LOG_DIR/deployment.log"
    fi
}

# Analyse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            DEPLOYMENT_URL="$2"
            shift 2
            ;;
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
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -u, --url URL           URL de déploiement (défaut: http://localhost:8000)"
            echo "  -i, --interval SECONDS  Intervalle de polling (défaut: 30)"
            echo "  -d, --duration SECONDS  Durée maximale (défaut: 3600)"
            echo "  -l, --log-dir DIR       Répertoire de logs (défaut: ./logs)"
            echo "  -n, --notify            Envoyer des notifications"
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

# Fonction pour vérifier l'état du déploiement
test_deployment_status() {
    local url=$1
    local timeout=${2:-30}
    
    print_log "Vérification de l'état du déploiement: $url" "INFO"
    
    # Utiliser curl pour effectuer la requête
    local response=$(curl -s -w "%{http_code}|%{time_total}" -m $timeout "$url" -o /dev/null)
    local http_code=$(echo "$response" | cut -d'|' -f1)
    local response_time=$(echo "$response" | cut -d'|' -f2)
    
    # Vérifier si la requête a réussi
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 400 ]; then
        echo "true|$http_code|OK|$response_time"
    else
        # Obtenir le message d'erreur
        local error_msg="HTTP $http_code"
        if [ "$http_code" = "000" ]; then
            error_msg="Timeout ou erreur de connexion"
        fi
        echo "false|$http_code|$error_msg|$response_time"
    fi
}

# Fonction pour vérifier les logs de déploiement
get_deployment_logs() {
    print_log "Récupération des logs de déploiement..." "INFO"
    
    # Dans une implémentation réelle, cela récupérerait les logs depuis le système de déploiement
    # Pour cette simulation, nous générons des logs aléatoires
    echo "$(date -d '5 minutes ago' '+%Y-%m-%d %H:%M:%S')|INFO|Démarrage du service"
    echo "$(date -d '4 minutes ago' '+%Y-%m-%d %H:%M:%S')|INFO|Connexion à la base de données établie"
    echo "$(date -d '3 minutes ago' '+%Y-%m-%d %H:%M:%S')|INFO|Chargement du modèle ML"
    echo "$(date -d '2 minutes ago' '+%Y-%m-%d %H:%M:%S')|INFO|Service prêt à recevoir des requêtes"
    echo "$(date -d '1 minute ago' '+%Y-%m-%d %H:%M:%S')|INFO|Traitement d'une requête"
}

# Fonction pour afficher les statistiques
show_deployment_stats() {
    local stats_line=$1
    
    local success=$(echo "$stats_line" | cut -d'|' -f1)
    local status_code=$(echo "$stats_line" | cut -d'|' -f2)
    local status_description=$(echo "$stats_line" | cut -d'|' -f3)
    
    if [ "$success" = "true" ]; then
        echo -e "  Statut: \033[1;32m✅ En ligne\033[0m"
    else
        echo -e "  Statut: \033[1;31m❌ Hors ligne\033[0m"
    fi
    
    echo -e "  Code HTTP: \033[1;37m$status_code\033[0m"
    echo -e "  Description: \033[1;37m$status_description\033[0m"
}

# Créer le répertoire de logs s'il n'existe pas
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    print_log "Répertoire de logs créé: $LOG_DIR" "INFO"
fi

# Initialiser la surveillance
start_time=$(date +%s)
end_time=$((start_time + MAX_DURATION))

print_log "Démarrage de la surveillance du déploiement" "INFO"
print_log "URL cible: $DEPLOYMENT_URL" "INFO"
print_log "Intervalle de polling: ${POLLING_INTERVAL}s" "INFO"
print_log "Durée maximale: ${MAX_DURATION}s" "INFO"
send_notification "Surveillance démarrée" "La surveillance du déploiement a commencé"

# Boucle de surveillance
iteration=0
deployment_online=false
while [ $(date +%s) -lt $end_time ]; do
    iteration=$((iteration + 1))
    print_log "Vérification #$iteration..." "INFO"
    
    # Vérifier l'état du déploiement
    status=$(test_deployment_status "$DEPLOYMENT_URL")
    success=$(echo "$status" | cut -d'|' -f1)
    status_code=$(echo "$status" | cut -d'|' -f2)
    
    if [ "$success" = "true" ]; then
        if [ "$deployment_online" = false ]; then
            print_log "Déploiement en ligne !" "SUCCESS"
            send_notification "Déploiement en ligne" "L'application est maintenant accessible"
            deployment_online=true
        fi
        
        print_log "Déploiement fonctionnel (Code: $status_code)" "SUCCESS"
    else
        if [ "$deployment_online" = true ]; then
            print_log "Déploiement hors ligne !" "ERROR"
            send_notification "Problème de déploiement" "L'application est inaccessible"
            deployment_online=false
        fi
        
        print_log "Déploiement inaccessible (Code: $status_code)" "ERROR"
    fi
    
    # Afficher les statistiques
    show_deployment_stats "$status"
    
    # Récupérer et afficher les logs si en mode verbeux
    if [ "$VERBOSE" = true ]; then
        print_log "Logs récents:" "INFO"
        get_deployment_logs | while IFS='|' read -r timestamp level message; do
            echo -e "  [$timestamp] [$level] $message"
        done
    fi
    
    # Enregistrer les statistiques dans un fichier JSON
    echo "{\"success\": $success, \"status_code\": $status_code}" > "$LOG_DIR/deployment-stats.json"
    
    # Vérifier si le déploiement est terminé (simulation)
    if [ "$status_code" -eq 200 ]; then
        print_log "Déploiement confirmé comme opérationnel" "SUCCESS"
        break
    fi
    
    # Attendre avant la prochaine vérification
    sleep $POLLING_INTERVAL
done

# Terminer la surveillance
duration=$(($(date +%s) - start_time))
print_log "Surveillance terminée après $duration secondes" "INFO"

if [ "$deployment_online" = true ]; then
    print_log "✅ Déploiement opérationnel !" "SUCCESS"
    send_notification "Surveillance terminée" "Le déploiement est opérationnel"
else
    print_log "❌ Déploiement non opérationnel" "ERROR"
    send_notification "Surveillance terminée" "Le déploiement n'est pas opérationnel"
fi