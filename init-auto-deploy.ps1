# Script d'initialisation du déploiement automatique

Write-Host "Initialisation du déploiement automatique pour Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan

# Vérifier que Docker est installé
Write-Host "Vérification de Docker..." -ForegroundColor Yellow
docker --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker n'est pas installé!" -ForegroundColor Red
    Write-Host "Veuillez installer Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Vérifier que Git est installé
Write-Host "Vérification de Git..." -ForegroundColor Yellow
git --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "Git n'est pas installé!" -ForegroundColor Red
    Write-Host "Veuillez installer Git: https://git-scm.com/downloads" -ForegroundColor Yellow
    exit 1
}

# Créer le fichier .env si nécessaire
if (-not (Test-Path ".env")) {
    Write-Host "Création du fichier .env à partir de .env.example..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "Fichier .env créé. Veuillez le modifier avec vos informations!" -ForegroundColor Green
}

# Construire l'image Docker
Write-Host "Construction de l'image Docker..." -ForegroundColor Yellow
docker build -t dog-breed-identifier .

if ($LASTEXITCODE -eq 0) {
    Write-Host "Image Docker construite avec succès!" -ForegroundColor Green
} else {
    Write-Host "Échec de la construction de l'image Docker!" -ForegroundColor Red
    exit 1
}

# Configuration des variables d'environnement pour GitHub Actions
Write-Host "Configuration des secrets pour GitHub Actions..." -ForegroundColor Yellow
Write-Host "Veuillez ajouter les secrets suivants dans les paramètres de votre dépôt GitHub:" -ForegroundColor Yellow
Write-Host "1. DOCKER_USERNAME - Votre nom d'utilisateur Docker Hub" -ForegroundColor White
Write-Host "2. DOCKER_PASSWORD - Votre mot de passe Docker Hub" -ForegroundColor White
Write-Host "3. RENDER_DEPLOY_HOOK - L'URL du hook de déploiement Render" -ForegroundColor White

# Configuration pour Render
Write-Host "`nConfiguration pour Render:" -ForegroundColor Yellow
Write-Host "1. Connectez votre dépôt GitHub à Render" -ForegroundColor White
Write-Host "2. Render détectera automatiquement le Dockerfile" -ForegroundColor White
Write-Host "3. Ajoutez les variables d'environnement dans le dashboard Render" -ForegroundColor White

# Configuration pour Dokploy
Write-Host "`nConfiguration pour Dokploy:" -ForegroundColor Yellow
Write-Host "1. Créez un projet dans Dokploy" -ForegroundColor White
Write-Host "2. Connectez votre dépôt Git" -ForegroundColor White
Write-Host "3. Dokploy utilisera le Dockerfile pour le déploiement" -ForegroundColor White

Write-Host "`nInitialisation terminée!" -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser './deploy.ps1 -Auto' pour un déploiement automatique complet." -ForegroundColor Green