# Script de déploiement local

param(
    [Parameter(Mandatory=$false)]
    [int]$Port = 8000,
    
    [Parameter(Mandatory=$false)]
    [switch]$DevMode = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Background = $false
)

Write-Host "Déploiement local de Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Vérifier les prérequis
Write-Host "Vérification des prérequis..." -ForegroundColor Yellow

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker n'est pas installé" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker Compose n'est pas installé" -ForegroundColor Red
    exit 1
}

# Construire l'image Docker
Write-Host "Construction de l'image Docker..." -ForegroundColor Yellow
if ($DevMode) {
    $buildResult = docker-compose build web
} else {
    $buildResult = docker build -t dog-breed-identifier .
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Échec de la construction de l'image Docker" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Image Docker construite avec succès" -ForegroundColor Green

# Lancer l'application
Write-Host "Lancement de l'application..." -ForegroundColor Yellow

if ($Background) {
    $detached = "-d"
} else {
    $detached = ""
}

if ($DevMode) {
    $runCmd = "docker-compose up $detached"
} else {
    if ($Background) {
        $runCmd = "docker run -d -p ${Port}:8000 dog-breed-identifier"
    } else {
        $runCmd = "docker run -p ${Port}:8000 dog-breed-identifier"
    }
}

Write-Host "Exécution: $runCmd" -ForegroundColor Yellow

Invoke-Expression $runCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Application lancée avec succès !" -ForegroundColor Green
    if (-not $Background) {
        Write-Host "Application accessible sur http://localhost:$Port" -ForegroundColor White
    } else {
        Write-Host "Application lancée en arrière-plan sur http://localhost:$Port" -ForegroundColor White
    }
} else {
    Write-Host "❌ Échec du lancement de l'application" -ForegroundColor Red
    exit 1
}

# Afficher les logs si en mode développement
if ($DevMode -and -not $Background) {
    Write-Host "Affichage des logs..." -ForegroundColor Yellow
    docker-compose logs -f
}

Write-Host "Déploiement local terminé !" -ForegroundColor Cyan