# Guide de Déploiement

## Plateformes de déploiement

### 1. Docker Hub

Docker Hub est utilisé pour stocker et distribuer les images Docker de l'application.

#### Configuration requise
- Compte Docker Hub
- Token d'accès personnel Docker Hub

#### Processus de déploiement
1. Construction de l'image Docker
2. Taggage avec version et latest
3. Push vers Docker Hub

### 2. Render

Render est utilisé pour l'hébergement de l'application en production.

#### Configuration requise
- Compte Render
- Webhook de déploiement Render

#### Processus de déploiement
1. Configuration du service sur Render
2. Connexion au dépôt Git
3. Déploiement automatique via webhook

## Configuration des secrets

### GitHub Actions

Ajoutez les secrets suivants dans les paramètres de votre dépôt GitHub :

```
DOCKER_USERNAME = votre_nom_utilisateur_docker_hub
DOCKER_PASSWORD = votre_token_docker_hub
RENDER_DEPLOY_HOOK = url_du_webhook_render
```

### GitLab CI/CD

Ajoutez les variables suivantes dans les paramètres CI/CD de votre projet GitLab :

```
DOCKER_USERNAME = votre_nom_utilisateur_docker_hub
DOCKER_PASSWORD = votre_token_docker_hub
RENDER_DEPLOY_HOOK = url_du_webhook_render
```

## Processus de déploiement automatisé

### Déploiement local

```bash
# Windows
./deploy.ps1 -Platform local

# Linux/Mac
./deploy.sh -Platform local
```

### Déploiement sur Docker Hub

```bash
# Windows
./deploy.ps1 -Platform dockerhub

# Linux/Mac
./deploy.sh -Platform dockerhub
```

### Déploiement sur Render

```bash
# Windows
./deploy.ps1 -Platform render

# Linux/Mac
./deploy.sh -Platform render
```

### Déploiement complet automatique

```bash
# Windows
./deploy.ps1 -Auto

# Linux/Mac
./deploy.sh --auto
```

## Surveillance et maintenance

### Vérification de la santé de l'application

L'application inclut un script de vérification de santé qui peut être exécuté :

```bash
python health_check.py
```

### Logs

Les logs de l'application peuvent être consultés via :

```bash
# Docker
docker logs <nom_du_conteneur>

# Render
Via le dashboard Render
```

## Mise à jour de l'application

### Processus de mise à jour

1. Mise à jour du code source
2. Construction de la nouvelle image
3. Déploiement sur les plateformes cibles
4. Vérification du bon fonctionnement

### Gestion des versions

Utilisez le tagging Git pour gérer les versions :

```bash
git tag -a v1.0.0 -m "Version 1.0.0"
git push origin v1.0.0
```