# Identificateur de Race de Chien

Une application Django qui utilise l'apprentissage automatique pour identifier les races de chiens à partir d'images.

## Fonctionnalités

- 🐶 **Reconnaissance de Race de Chien** : Identifie plus de 120 races de chiens en utilisant l'apprentissage profond
- 🐕 **Interface Web** : Application web conviviale pour le téléchargement d'images
- 🐳 **Support Docker** : Application conteneurisée pour un déploiement facile
- ☁️ **Déploiement Multi-plateformes** : Déploiement sur Docker Hub, Render, et plus
- 🔄 **Intégration CI/CD** : Tests et déploiement automatisés avec GitHub Actions et GitLab CI

## Déploiement Docker

Ce projet inclut une configuration Docker pour un déploiement facile sur plusieurs plateformes.

### Construction de l'Image Docker

Pour construire l'image Docker :

```bash
# Utilisation du script de construction (Linux/Mac)
./build-docker.sh

# Utilisation du script de construction (Windows)
./build-docker.ps1

# Ou manuellement :
docker build -t dog-breed-identifier .
```

### Exécution de l'Application Localement

```bash
# Utilisation de docker-compose (recommandé pour le développement)
docker-compose up

# Utilisation de docker run
docker run -p 8000:8000 dog-breed-identifier
```

## Déploiement Automatisé

Ce projet inclut des capacités de déploiement automatisé complètes sur plusieurs plateformes.

### Prérequis

1. Docker installé et en cours d'exécution
2. Git installé
3. Comptes sur les plateformes de déploiement (Docker Hub, Render)

### Configuration Initiale

Exécutez le script d'initialisation :

```bash
# Windows
./init-auto-deploy.ps1

# Linux/Mac
./init-auto-deploy.sh
```

### Variables d'Environnement

Créez un fichier `.env.local` à partir de `.env` et configurez vos identifiants personnels :

```bash
cp .env .env.local
```

Ensuite, modifiez `.env.local` avec vos identifiants réels :

```bash
# Identifiants Docker Hub
DOCKER_USERNAME=votre_nom_utilisateur_docker_hub
DOCKER_PASSWORD=votre_mot_de_passe_docker_hub

# Hooks de déploiement
RENDER_DEPLOY_HOOK=https://api.render.com/deploy/votre-hook
```

**Important** : Le fichier `.env.local` est ignoré par Git et ne sera pas commité dans le dépôt, gardant vos identifiants sécurisés.

### Commandes de Déploiement Automatisé

```bash
# Déploiement entièrement automatisé sur toutes les plateformes
./deploy.ps1 -Auto

# Menu de déploiement interactif
./deploy.ps1

# Déploiement sur une plateforme spécifique
./deploy.ps1 -Platform dockerhub
./deploy.ps1 -Platform render
./deploy.ps1 -Platform local
```

### Configuration CI/CD

#### GitHub Actions
- Fichier de workflow : `.github/workflows/auto-deploy.yml`
- Construit et déploie automatiquement lors d'un push sur la branche principale
- Nécessite la configuration des secrets dans les paramètres du dépôt GitHub

##### Configuration des Secrets GitHub
1. Allez dans votre dépôt GitHub
2. Cliquez sur "Settings"
3. Dans le menu de gauche, cliquez sur "Secrets and variables" puis "Actions"
4. Cliquez sur "New repository secret"
5. Ajoutez les secrets suivants :

```
Name: DOCKER_USERNAME
Value: votre_nom_utilisateur_docker_hub

Name: DOCKER_PASSWORD
Value: votre_token_d'accès_personnel_docker_hub

Name: RENDER_DEPLOY_HOOK
Value: https://api.render.com/deploy/votre-url-hook
```

#### GitLab CI/CD
- Fichier de configuration : `.gitlab-ci.yml`
- Supporte les tests, la construction et le déploiement automatisés

##### Configuration des Variables GitLab
1. Allez dans votre projet GitLab
2. Cliquez sur "Settings" puis "CI /CD"
3. Développez la section "Variables"
4. Cliquez sur "Add variable"
5. Ajoutez les variables suivantes :

```
Name: DOCKER_USERNAME
Value: votre_nom_utilisateur_docker_hub

Name: DOCKER_PASSWORD
Value: votre_token_d'accès_personnel_docker_hub

Name: RENDER_DEPLOY_HOOK
Value: https://api.render.com/deploy/votre-url-hook
```

### Plateformes de Déploiement

#### 1. Déploiement Local
```bash
./deploy.ps1 -Platform local
```

#### 2. Docker Hub
```bash
./deploy.ps1 -Platform dockerhub
```

#### 3. Render
1. Connectez le dépôt à Render
2. Ajoutez les variables d'environnement dans le tableau de bord Render
3. Le déploiement est déclenché automatiquement via webhook

### Fichiers de Configuration de Déploiement

- `.github/workflows/auto-deploy.yml` : Workflow GitHub Actions
- `.gitlab-ci.yml` : Configuration GitLab CI/CD
- `deploy.ps1` : Script de déploiement PowerShell
- `init-auto-deploy.ps1` : Script d'initialisation
- `.env` : Modèle de variables d'environnement
- `.env.local` : Vos variables d'environnement personnelles (ignorées par Git)

## Développement

Pour exécuter l'application en mode développement :

```bash
# Utilisation de docker-compose
docker-compose up

# La version de développement utilise le serveur de développement Django
# et monte les volumes locaux pour les mises à jour de code en direct
```

## Production

Pour le déploiement en production, l'application utilise Gunicorn comme serveur WSGI.

L'image Docker de production :
- Utilise Gunicorn pour servir l'application
- S'exécute en tant qu'utilisateur non-root pour la sécurité
- Collecte les fichiers statiques pendant le processus de construction
- Est optimisée pour la taille et les performances

## Structure du Projet

```
IA-chien/
├── dog_breed_identifier/     # Application Django
├── docs/                     # Documentation
├── scripts/                  # Scripts utilitaires
├── tests/                    # Tests automatisés
├── .dockerignore            # Règles d'ignore Docker
├── .env                     # Modèle d'environnement
├── .env.local               # Environnement local (ignoré)
├── .gitignore               # Règles d'ignore Git
├── .github/                 # Workflows GitHub Actions
├── .gitlab-ci.yml           # Configuration GitLab CI/CD
├── Dockerfile               # Configuration Docker
├── README.md                # Ce fichier
├── requirements.txt         # Dépendances Python
└── docker-compose.yml       # Configuration Docker Compose
```

## Dépannage

Si vous rencontrez des problèmes :

1. Assurez-vous que Docker est installé et en cours d'exécution
2. Vérifiez que les ports ne sont pas déjà utilisés
3. Vérifiez que les variables d'environnement sont correctement définies
4. Vérifiez les journaux Docker : `docker logs <nom_du_conteneur>`

Pour plus d'informations, veuillez vous référer aux fichiers de configuration individuels.