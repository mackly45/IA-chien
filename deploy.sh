#!/bin/bash

# Script de déploiement automatique pour Dog Breed Identifier

# Variables de configuration
DOCKER_IMAGE="dog-breed-identifier"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Fonction pour afficher les messages
print_message() {
    echo -e "\033[1;36m$1\033[0m"
}

print_success() {
    echo -e "\033[1;32m$1\033[0m"
}

print_error() {
    echo -e "\033[1;31m$1\033[0m"
}

# Fonction pour construire l'image Docker
build_docker_image() {
    print_message "Construction de l'image Docker..."
    
    # Tag avec timestamp
    docker build -t "$DOCKER_IMAGE:$TIMESTAMP" .
    if [ $? -eq 0 ]; then
        docker tag "$DOCKER_IMAGE:$TIMESTAMP" "$DOCKER_IMAGE:latest"
        print_success "Image Docker construite avec succès!"
        return 0
    else
        print_error "Échec de la construction de l'image Docker!"
        return 1
    fi
}

# Fonction pour déployer sur Docker Hub
deploy_to_dockerhub() {
    print_message "Déploiement sur Docker Hub..."
    
    if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]; then
        print_error "Variables DOCKER_USERNAME et DOCKER_PASSWORD non définies!"
        return 1
    fi
    
    # Login Docker Hub
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    if [ $? -ne 0 ]; then
        print_error "Échec de la connexion à Docker Hub!"
        return 1
    fi
    
    # Tag avec Docker Hub repo
    DOCKER_HUB_REPO="$DOCKER_USERNAME/$DOCKER_IMAGE"
    docker tag "$DOCKER_IMAGE:latest" "$DOCKER_HUB_REPO:$TIMESTAMP"
    docker tag "$DOCKER_IMAGE:latest" "$DOCKER_HUB_REPO:latest"
    
    # Push les deux tags
    docker push "$DOCKER_HUB_REPO:$TIMESTAMP"
    docker push "$DOCKER_HUB_REPO:latest"
    
    if [ $? -eq 0 ]; then
        print_success "Image déployée sur Docker Hub avec succès!"
        print_success "Image URL: docker.io/$DOCKER_HUB_REPO:latest"
    else
        print_error "Échec du déploiement sur Docker Hub!"
        return 1
    fi
}

# Fonction pour déployer sur Render
deploy_to_render() {
    print_message "Déploiement sur Render..."
    
    if [ -z "$RENDER_DEPLOY_HOOK" ]; then
        print_error "Variable RENDER_DEPLOY_HOOK non définie!"
        return 1
    fi
    
    curl -X POST "$RENDER_DEPLOY_HOOK"
    if [ $? -eq 0 ]; then
        print_success "Hook de déploiement Render envoyé avec succès!"
    else
        print_error "Échec de l'envoi du hook Render!"
        return 1
    fi
}

# Fonction pour déployer localement
deploy_locally() {
    print_message "Déploiement local..."
    
    # Stop et supprime le container existant
    docker stop dog-breed-identifier-app 2>/dev/null
    docker rm dog-breed-identifier-app 2>/dev/null
    
    # Lance le nouveau container
    docker run -d -p 8000:8000 --name dog-breed-identifier-app "$DOCKER_IMAGE:latest"
    
    if [ $? -eq 0 ]; then
        print_success "Application déployée localement!"
        print_success "Accès: http://localhost:8000"
    else
        print_error "Échec du déploiement local!"
        return 1
    fi
}

# Fonction de déploiement automatique
deploy_automatically() {
    print_message "Déploiement automatique sur toutes les plateformes..."
    
    # Construire l'image
    if ! build_docker_image; then
        print_error "Échec de la construction de l'image!"
        exit 1
    fi
    
    # Déploiement sur toutes les plateformes
    deploy_to_dockerhub
    deploy_to_render
    
    print_success "Déploiement automatique terminé!"
}

# Menu principal
show_menu() {
    print_message "Sélectionnez une option de déploiement:"
    echo "1. Déploiement local"
    echo "2. Déploiement sur Docker Hub"
    echo "3. Déploiement sur Render"
    echo "4. Déploiement automatique complet"
    echo "5. Construire seulement l'image Docker"
    echo ""
    
    read -p "Entrez votre choix (1-5): " choice
    
    case $choice in
        1)
            if build_docker_image; then
                deploy_locally
            fi
            ;;
        2)
            if build_docker_image; then
                deploy_to_dockerhub
            fi
            ;;
        3)
            if build_docker_image; then
                deploy_to_render
            fi
            ;;
        4)
            deploy_automatically
            ;;
        5)
            build_docker_image
            ;;
        *)
            print_error "Choix invalide!"
            exit 1
            ;;
    esac
}

# Traitement des arguments
AUTO=false
PLATFORM="all"

while [[ $# -gt 0 ]]; do
    case $1 in
        -Auto|--auto)
            AUTO=true
            shift
            ;;
        -Platform|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

# Chargement des variables d'environnement
if [ -f ".env" ]; then
    export $(cat .env | xargs)
fi

# Exécution
if [ "$AUTO" = true ]; then
    deploy_automatically
else
    case $PLATFORM in
        "all")
            show_menu
            ;;
        "local")
            if build_docker_image; then
                deploy_locally
            fi
            ;;
        "dockerhub")
            if build_docker_image; then
                deploy_to_dockerhub
            fi
            ;;
        "render")
            if build_docker_image; then
                deploy_to_render
            fi
            ;;
        *)
            print_error "Plateforme non reconnue: $PLATFORM"
            exit 1
            ;;
    esac
fi