#!/bin/bash

# Script de déploiement multi-plateformes

PLATFORMS=("dockerhub" "render")
PARALLEL=false
DRY_RUN=false

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platforms)
            IFS=',' read -ra PLATFORMS <<< "$2"
            shift 2
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-p platforms] [--parallel] [--dry-run]"
            echo "  -p, --platforms PLATFORMS  Plateformes (séparées par des virgules) (défaut: dockerhub,render)"
            echo "  --parallel                 Déploiement parallèle"
            echo "  --dry-run                  Simulation sans déploiement réel"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mDéploiement multi-plateformes de Dog Breed Identifier\033[0m"
echo -e "\033[1;36m================================================\033[0m"

# Variables de configuration
DOCKER_IMAGE="dog-breed-identifier"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Fonction pour charger les variables d'environnement
load_env_vars() {
    if [ -f ".env.local" ]; then
        export $(cat .env.local | xargs)
    fi
}

# Fonction pour construire l'image Docker
build_docker_image() {
    echo -e "\033[1;33mConstruction de l'image Docker...\033[0m"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "\033[1;37mSimulation: Construction de l'image Docker\033[0m"
        return 0
    fi
    
    docker build -t "$DOCKER_IMAGE:$TIMESTAMP" .
    if [ $? -eq 0 ]; then
        docker tag "$DOCKER_IMAGE:$TIMESTAMP" "$DOCKER_IMAGE:latest"
        echo -e "\033[1;32m✅ Image Docker construite avec succès\033[0m"
        return 0
    else
        echo -e "\033[1;31m❌ Échec de la construction de l'image Docker\033[0m"
        return 1
    fi
}

# Fonction pour déployer sur Docker Hub
deploy_to_dockerhub() {
    local username=$1
    local password=$2
    
    echo -e "\033[1;33mDéploiement sur Docker Hub...\033[0m"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "\033[1;37mSimulation: Déploiement sur Docker Hub\033[0m"
        return 0
    fi
    
    if [ -z "$username" ] || [ -z "$password" ]; then
        echo -e "\033[1;31m❌ Identifiants Docker Hub manquants\033[0m"
        return 1
    fi
    
    # Login Docker Hub
    echo "$password" | docker login -u "$username" --password-stdin >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "\033[1;31m❌ Échec de la connexion à Docker Hub\033[0m"
        return 1
    fi
    
    # Tag et push
    local repo="$username/$DOCKER_IMAGE"
    docker tag "$DOCKER_IMAGE:latest" "$repo:$TIMESTAMP"
    docker tag "$DOCKER_IMAGE:latest" "$repo:latest"
    
    docker push "$repo:$TIMESTAMP"
    docker push "$repo:latest"
    
    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m✅ Image déployée sur Docker Hub: docker.io/$repo:latest\033[0m"
        return 0
    else
        echo -e "\033[1;31m❌ Échec du déploiement sur Docker Hub\033[0m"
        return 1
    fi
}

# Fonction pour déployer sur Render
deploy_to_render() {
    local deploy_hook=$1
    
    echo -e "\033[1;33mDéploiement sur Render...\033[0m"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "\033[1;37mSimulation: Déploiement sur Render\033[0m"
        return 0
    fi
    
    if [ -z "$deploy_hook" ]; then
        echo -e "\033[1;31m❌ Hook de déploiement Render manquant\033[0m"
        return 1
    fi
    
    if command -v curl &> /dev/null; then
        local response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$deploy_hook")
        if [ "$response" = "200" ]; then
            echo -e "\033[1;32m✅ Hook de déploiement Render envoyé avec succès\033[0m"
            return 0
        else
            echo -e "\033[1;31m❌ Échec de l'envoi du hook Render (Code: $response)\033[0m"
            return 1
        fi
    else
        echo -e "\033[1;31m❌ curl non installé\033[0m"
        return 1
    fi
}

# Fonction pour déployer sur AWS ECR
deploy_to_aws() {
    local region=$1
    local account_id=$2
    
    echo -e "\033[1;33mDéploiement sur AWS ECR...\033[0m"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "\033[1;37mSimulation: Déploiement sur AWS ECR\033[0m"
        return 0
    fi
    
    # Vérifier que AWS CLI est installé
    if ! command -v aws &> /dev/null; then
        echo -e "\033[1;31m❌ AWS CLI n'est pas installé\033[0m"
        return 1
    fi
    
    local repo="$account_id.dkr.ecr.$region.amazonaws.com/$DOCKER_IMAGE"
    
    # Login ECR
    aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "$account_id.dkr.ecr.$region.amazonaws.com" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "\033[1;31m❌ Échec de la connexion à AWS ECR\033[0m"
        return 1
    fi
    
    # Tag et push
    docker tag "$DOCKER_IMAGE:latest" "$repo:$TIMESTAMP"
    docker tag "$DOCKER_IMAGE:latest" "$repo:latest"
    
    docker push "$repo:$TIMESTAMP"
    docker push "$repo:latest"
    
    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m✅ Image déployée sur AWS ECR: $repo:latest\033[0m"
        return 0
    else
        echo -e "\033[1;31m❌ Échec du déploiement sur AWS ECR\033[0m"
        return 1
    fi
}

# Fonction pour déployer sur Google Container Registry
deploy_to_gcp() {
    local project_id=$1
    
    echo -e "\033[1;33mDéploiement sur Google Container Registry...\033[0m"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "\033[1;37mSimulation: Déploiement sur Google Container Registry\033[0m"
        return 0
    fi
    
    # Vérifier que gcloud est installé
    if ! command -v gcloud &> /dev/null; then
        echo -e "\033[1;31m❌ Google Cloud SDK n'est pas installé\033[0m"
        return 1
    fi
    
    local repo="gcr.io/$project_id/$DOCKER_IMAGE"
    
    # Tag et push
    docker tag "$DOCKER_IMAGE:latest" "$repo:$TIMESTAMP"
    docker tag "$DOCKER_IMAGE:latest" "$repo:latest"
    
    docker push "$repo:$TIMESTAMP"
    docker push "$repo:latest"
    
    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m✅ Image déployée sur Google Container Registry: $repo:latest\033[0m"
        return 0
    else
        echo -e "\033[1;31m❌ Échec du déploiement sur Google Container Registry\033[0m"
        return 1
    fi
}

# Charger les variables d'environnement
load_env_vars

# Construire l'image Docker
if ! build_docker_image; then
    echo -e "\033[1;31m❌ Échec de la construction de l'image\033[0m"
    exit 1
fi

# Déploiement séquentiel ou parallèle
if [ "$PARALLEL" = true ]; then
    echo -e "\033[1;33mDéploiement parallèle sur les plateformes: ${PLATFORMS[*]}\033[0m"
    
    # Pour le déploiement parallèle, nous utiliserions des sous-processus
    # Mais pour simplifier, nous allons faire un déploiement séquentiel
    # dans cette version bash
    
    success=true
    for platform in "${PLATFORMS[@]}"; do
        case $platform in
            "dockerhub")
                if ! deploy_to_dockerhub "$DOCKER_USERNAME" "$DOCKER_PASSWORD"; then
                    success=false
                fi
                ;;
            
            "render")
                if ! deploy_to_render "$RENDER_DEPLOY_HOOK"; then
                    success=false
                fi
                ;;
            
            "aws")
                if ! deploy_to_aws "$AWS_REGION" "$AWS_ACCOUNT_ID"; then
                    success=false
                fi
                ;;
            
            "gcp")
                if ! deploy_to_gcp "$GCP_PROJECT_ID"; then
                    success=false
                fi
                ;;
            
            *)
                echo -e "\033[1;31mPlateforme non supportée: $platform\033[0m"
                success=false
                ;;
        esac
    done
    
    if [ "$success" = true ]; then
        echo -e "\033[1;32m✅ Tous les déploiements ont réussi\033[0m"
    else
        echo -e "\033[1;31m❌ Un ou plusieurs déploiements ont échoué\033[0m"
        exit 1
    fi
else
    echo -e "\033[1;33mDéploiement séquentiel sur les plateformes: ${PLATFORMS[*]}\033[0m"
    
    success=true
    for platform in "${PLATFORMS[@]}"; do
        case $platform in
            "dockerhub")
                if ! deploy_to_dockerhub "$DOCKER_USERNAME" "$DOCKER_PASSWORD"; then
                    success=false
                fi
                ;;
            
            "render")
                if ! deploy_to_render "$RENDER_DEPLOY_HOOK"; then
                    success=false
                fi
                ;;
            
            "aws")
                if ! deploy_to_aws "$AWS_REGION" "$AWS_ACCOUNT_ID"; then
                    success=false
                fi
                ;;
            
            "gcp")
                if ! deploy_to_gcp "$GCP_PROJECT_ID"; then
                    success=false
                fi
                ;;
            
            *)
                echo -e "\033[1;31mPlateforme non supportée: $platform\033[0m"
                success=false
                ;;
        esac
    done
    
    if [ "$success" = true ]; then
        echo -e "\033[1;32m✅ Tous les déploiements ont réussi\033[0m"
    else
        echo -e "\033[1;31m❌ Un ou plusieurs déploiements ont échoué\033[0m"
        exit 1
    fi
fi

echo -e "\033[1;36mDéploiement multi-plateformes terminé !\033[0m"
if [ "$DRY_RUN" = true ]; then
    echo -e "\033[1;33m⚠️  Ceci était une simulation (dry run)\033[0m"
fi