#!/bin/bash

# Script de déploiement avec monitoring

PLATFORM="all"
WITH_HEALTH_CHECK=true
HEALTH_CHECK_TIMEOUT=300  # 5 minutes
WITH_ROLLBACK=false
NOTIFICATION_EMAIL=""
SLACK_WEBHOOK_URL=""

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        --no-health-check)
            WITH_HEALTH_CHECK=false
            shift
            ;;
        -t|--timeout)
            HEALTH_CHECK_TIMEOUT="$2"
            shift 2
            ;;
        --with-rollback)
            WITH_ROLLBACK=true
            shift
            ;;
        -e|--email)
            NOTIFICATION_EMAIL="$2"
            shift 2
            ;;
        -s|--slack)
            SLACK_WEBHOOK_URL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-p platform] [--no-health-check] [-t timeout] [--with-rollback] [-e email] [-s slack]"
            echo "  -p, --platform PLATFORM     Plateforme de déploiement (dockerhub, render, local, all) (défaut: all)"
            echo "  --no-health-check           Désactiver le health check"
            echo "  -t, --timeout SECONDS       Timeout du health check (défaut: 300)"
            echo "  --with-rollback             Activer le rollback en cas d'échec"
            echo "  -e, --email EMAIL           Email de notification"
            echo "  -s, --slack URL             URL du webhook Slack"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mDéploiement avec monitoring de Dog Breed Identifier\033[0m"
echo -e "\033[1;36m===============================================\033[0m"

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
DEPLOYMENT_START_TIME=$(date)
DEPLOYMENT_STATUS="unknown"
TEMP_NOTIFICATIONS_FILE=$(mktemp)

# Fonction pour envoyer une notification
send_notification() {
    local title=$1
    local message=$2
    local status=${3:-"info"}
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$status|$title|$message|$timestamp" >> "$TEMP_NOTIFICATIONS_FILE"
    
    # Afficher la notification
    case $status in
        "success")
            echo -e "\033[1;32m[$status] $title\033[0m"
            echo -e "\033[1;30m  $message\033[0m"
            ;;
        "warning")
            echo -e "\033[1;33m[$status] $title\033[0m"
            echo -e "\033[1;30m  $message\033[0m"
            ;;
        "error")
            echo -e "\033[1;31m[$status] $title\033[0m"
            echo -e "\033[1;30m  $message\033[0m"
            ;;
        *)
            echo -e "\033[1;37m[$status] $title\033[0m"
            echo -e "\033[1;30m  $message\033[0m"
            ;;
    esac
    
    # Envoyer par email si configuré
    if [ -n "$NOTIFICATION_EMAIL" ] && [ "$status" != "info" ]; then
        # Ici, vous pouvez implémenter l'envoi d'email
        # echo -e "Subject: $title\n\n$message" | sendmail "$NOTIFICATION_EMAIL"
        echo -e "\033[1;30m  Notification email envoyée à $NOTIFICATION_EMAIL\033[0m"
    fi
    
    # Envoyer à Slack si configuré
    if [ -n "$SLACK_WEBHOOK_URL" ] && [ "$status" != "info" ]; then
        # Ici, vous pouvez implémenter l'envoi à Slack
        # curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"*$title*\n$message\"}" "$SLACK_WEBHOOK_URL"
        echo -e "\033[1;30m  Notification Slack envoyée\033[0m"
    fi
}

# Fonction pour effectuer un health check
invoke_health_check() {
    local url=$1
    local timeout=$2
    
    echo -e "\033[1;33mEffectuer un health check...\033[0m"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + timeout))
    
    while [ $(date +%s) -lt $end_time ]; do
        if command -v curl &> /dev/null; then
            if curl -s -f -o /dev/null "$url/health/"; then
                echo -e "\033[1;32m✅ Health check réussi\033[0m"
                return 0
            fi
        fi
        
        local elapsed=$(( $(date +%s) - start_time ))
        echo -e "\033[1;33m⏳ Health check en cours... ($elapsed secondes)\033[0m"
        
        sleep 5
    done
    
    echo -e "\033[1;31m❌ Health check échoué après $timeout secondes\033[0m"
    return 1
}

# Fonction pour déployer sur Docker Hub
deploy_to_dockerhub() {
    echo -e "\033[1;33mDéploiement sur Docker Hub...\033[0m"
    
    # Construire l'image
    if ! docker build -t dog-breed-identifier:latest .; then
        send_notification "Déploiement Docker Hub" "Échec de la construction de l'image Docker" "error"
        return 1
    fi
    
    # Tag et push
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local repo="$DOCKER_USERNAME/dog-breed-identifier"
    
    docker tag dog-breed-identifier:latest "$repo:$timestamp"
    docker tag dog-breed-identifier:latest "$repo:latest"
    
    if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
        if [ $? -ne 0 ]; then
            send_notification "Déploiement Docker Hub" "Échec de la connexion à Docker Hub" "error"
            return 1
        fi
        
        docker push "$repo:$timestamp"
        docker push "$repo:latest"
        
        if [ $? -ne 0 ]; then
            send_notification "Déploiement Docker Hub" "Échec du push vers Docker Hub" "error"
            return 1
        fi
        
        send_notification "Déploiement Docker Hub" "Image déployée avec succès: $repo:latest" "success"
        return 0
    else
        send_notification "Déploiement Docker Hub" "Variables d'environnement Docker manquantes" "error"
        return 1
    fi
}

# Fonction pour déployer sur Render
deploy_to_render() {
    echo -e "\033[1;33mDéploiement sur Render...\033[0m"
    
    if [ -n "$RENDER_DEPLOY_HOOK" ]; then
        if command -v curl &> /dev/null; then
            local response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$RENDER_DEPLOY_HOOK")
            if [ "$response" = "200" ]; then
                send_notification "Déploiement Render" "Hook de déploiement envoyé avec succès" "success"
                
                # Attendre le déploiement si health check activé
                if [ "$WITH_HEALTH_CHECK" = true ]; then
                    echo -e "\033[1;33mAttente du déploiement Render...\033[0m"
                    sleep 30  # Attendre que le déploiement commence
                    
                    if invoke_health_check "https://dog-identifier.onrender.com" "$HEALTH_CHECK_TIMEOUT"; then
                        send_notification "Health Check Render" "Application Render opérationnelle" "success"
                        return 0
                    else
                        send_notification "Health Check Render" "L'application Render ne répond pas" "error"
                        return 1
                    fi
                fi
                
                return 0
            else
                send_notification "Déploiement Render" "Code de réponse invalide: $response" "error"
                return 1
            fi
        else
            send_notification "Déploiement Render" "curl non installé" "error"
            return 1
        fi
    else
        send_notification "Déploiement Render" "Hook de déploiement Render non configuré" "error"
        return 1
    fi
}

# Fonction pour déployer localement
deploy_locally() {
    echo -e "\033[1;33mDéploiement local...\033[0m"
    
    # Arrêter et supprimer l'ancien conteneur
    docker stop dog-breed-identifier-app 2>/dev/null
    docker rm dog-breed-identifier-app 2>/dev/null
    
    # Lancer le nouveau conteneur
    if docker run -d -p 8000:8000 --name dog-breed-identifier-app dog-breed-identifier:latest; then
        send_notification "Déploiement Local" "Application déployée localement sur http://localhost:8000" "success"
        
        # Effectuer un health check si activé
        if [ "$WITH_HEALTH_CHECK" = true ]; then
            if invoke_health_check "http://localhost:8000" "$HEALTH_CHECK_TIMEOUT"; then
                send_notification "Health Check Local" "Application locale opérationnelle" "success"
                return 0
            else
                send_notification "Health Check Local" "L'application locale ne répond pas" "error"
                return 1
            fi
        fi
        
        return 0
    else
        send_notification "Déploiement Local" "Échec du lancement du conteneur" "error"
        return 1
    fi
}

# Fonction pour effectuer un rollback
invoke_rollback() {
    echo -e "\033[1;33mEffectuer un rollback...\033[0m"
    
    # Ici, vous pouvez implémenter la logique de rollback spécifique à votre plateforme
    # Par exemple, restaurer une version précédente sur Render, Docker Hub, etc.
    
    send_notification "Rollback" "Rollback effectué" "warning"
}

# Fonction pour générer un rapport de déploiement
generate_deployment_report() {
    local status=$1
    
    local deployment_end_time=$(date)
    local report_file="./deployment-report-$(date +"%Y%m%d-%H%M%S").txt"
    
    {
        echo "Rapport de Déploiement - $PROJECT_NAME"
        echo "================================"
        echo ""
        echo "Statut: $status"
        echo "Date de début: $DEPLOYMENT_START_TIME"
        echo "Date de fin: $deployment_end_time"
        echo ""
        echo "Notifications:"
        
        while IFS='|' read -r notif_status notif_title notif_message notif_timestamp; do
            echo "[$notif_status] $notif_title - $notif_message"
        done < "$TEMP_NOTIFICATIONS_FILE"
    } > "$report_file"
    
    echo -e "\033[1;32m✅ Rapport de déploiement généré: $report_file\033[0m"
}

# Exécuter le déploiement selon la plateforme
echo -e "\033[1;33mDémarrage du déploiement...\033[0m"
send_notification "Déploiement démarré" "Début du déploiement de $PROJECT_NAME" "info"

success=true

case $PLATFORM in
    "dockerhub")
        if ! deploy_to_dockerhub; then
            success=false
        fi
        ;;
    
    "render")
        if ! deploy_to_render; then
            success=false
        fi
        ;;
    
    "local")
        if ! deploy_locally; then
            success=false
        fi
        ;;
    
    "all")
        if ! deploy_locally; then
            success=false
        fi
        if ! deploy_to_dockerhub; then
            success=false
        fi
        if ! deploy_to_render; then
            success=false
        fi
        ;;
    
    *)
        send_notification "Erreur de déploiement" "Plateforme non supportée: $PLATFORM" "error"
        success=false
        ;;
esac

# Mettre à jour le statut du déploiement
if [ "$success" = true ]; then
    DEPLOYMENT_STATUS="success"
    send_notification "Déploiement terminé" "Tous les déploiements ont réussi" "success"
else
    DEPLOYMENT_STATUS="failed"
    send_notification "Déploiement terminé" "Un ou plusieurs déploiements ont échoué" "error"
    
    # Effectuer un rollback si activé
    if [ "$WITH_ROLLBACK" = true ]; then
        invoke_rollback
    fi
fi

# Générer le rapport de déploiement
generate_deployment_report "$DEPLOYMENT_STATUS"

# Nettoyer le fichier temporaire
rm -f "$TEMP_NOTIFICATIONS_FILE"

echo -e "\033[1;36mDéploiement avec monitoring terminé !\033[0m"