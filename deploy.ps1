# Script de déploiement automatique pour Dog Breed Identifier

param(
    [Parameter(Mandatory=$false)]
    [string]$Platform = "all",
    
    [Parameter(Mandatory=$false)]
    [switch]$Auto = $false
)

Write-Host "Dog Breed Identifier - Déploiement Automatique" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Variables de configuration
$DOCKER_IMAGE = "dog-breed-identifier"
$DOCKER_HUB_REPO = "$env:DOCKER_USERNAME/$DOCKER_IMAGE"
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"

# Chargement des variables d'environnement depuis .env.local
$envFile = ".env.local"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -notmatch "^\s*#" -and $_ -match "([^=]+)=(.*)") {
            $name = $matches[1]
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value)
        }
    }
} else {
    Write-Host "Fichier $envFile non trouvé. Utilisation des variables d'environnement du système." -ForegroundColor Yellow
}

# Fonction pour construire l'image Docker
function Build-DockerImage {
    Write-Host "Construction de l'image Docker..." -ForegroundColor Yellow
    
    # Tag avec timestamp
    $taggedImage = "$DOCKER_IMAGE`:$TIMESTAMP"
    
    docker build -t $taggedImage .
    if ($LASTEXITCODE -eq 0) {
        docker tag $taggedImage "$DOCKER_IMAGE`:latest"
        Write-Host "Image Docker construite avec succès!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Échec de la construction de l'image Docker!" -ForegroundColor Red
        return $false
    }
}

# Fonction pour déployer sur Docker Hub
function Deploy-ToDockerHub {
    Write-Host "Déploiement sur Docker Hub..." -ForegroundColor Yellow
    
    # Tag avec timestamp et latest
    $timestampTag = "$DOCKER_HUB_REPO`:$TIMESTAMP"
    $latestTag = "$DOCKER_HUB_REPO`:latest"
    
    docker tag "$DOCKER_IMAGE`:latest" $timestampTag
    docker tag "$DOCKER_IMAGE`:latest" $latestTag
    
    # Push les deux tags
    docker push $timestampTag
    docker push $latestTag
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Image déployée sur Docker Hub avec succès!" -ForegroundColor Green
        Write-Host "Image URL: docker.io/$DOCKER_HUB_REPO`:latest" -ForegroundColor Green
    } else {
        Write-Host "Échec du déploiement sur Docker Hub!" -ForegroundColor Red
        exit 1
    }
}

# Fonction pour déployer sur Render
function Deploy-ToRender {
    Write-Host "Déploiement sur Render..." -ForegroundColor Yellow
    
    if ($env:RENDER_DEPLOY_HOOK) {
        curl.exe -X POST $env:RENDER_DEPLOY_HOOK
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Hook de déploiement Render envoyé avec succès!" -ForegroundColor Green
        } else {
            Write-Host "Échec de l'envoi du hook Render!" -ForegroundColor Red
        }
    } else {
        Write-Host "Variable RENDER_DEPLOY_HOOK non définie!" -ForegroundColor Red
    }
}


# Fonction pour déployer localement
function Deploy-Locally {
    Write-Host "Déploiement local..." -ForegroundColor Yellow
    
    # Stop et supprime le container existant
    docker stop dog-breed-identifier-app 2>$null
    docker rm dog-breed-identifier-app 2>$null
    
    # Lance le nouveau container
    docker run -d -p 8000:8000 --name dog-breed-identifier-app "$DOCKER_IMAGE`:latest"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Application déployée localement!" -ForegroundColor Green
        Write-Host "Accès: http://localhost:8000" -ForegroundColor Green
    } else {
        Write-Host "Échec du déploiement local!" -ForegroundColor Red
        exit 1
    }
}

# Fonction de déploiement automatique
function Deploy-Automatically {
    Write-Host "Déploiement automatique sur toutes les plateformes..." -ForegroundColor Cyan
    
    # Construire l'image
    if (-not (Build-DockerImage)) {
        Write-Host "Échec de la construction de l'image!" -ForegroundColor Red
        exit 1
    }
    
    # Déploiement sur toutes les plateformes
    Deploy-ToDockerHub
    Deploy-ToRender
    
    Write-Host "Déploiement automatique terminé!" -ForegroundColor Green
}

# Menu principal
if ($Auto) {
    Deploy-Automatically
} else {
    switch ($Platform.ToLower()) {
        "all" {
            Write-Host "Sélectionnez une option de déploiement:" -ForegroundColor White
            Write-Host "1. Déploiement local" -ForegroundColor White
            Write-Host "2. Déploiement sur Docker Hub" -ForegroundColor White
            Write-Host "3. Déploiement sur Render" -ForegroundColor White
            Write-Host "4. Déploiement automatique complet" -ForegroundColor White
            Write-Host "5. Construire seulement l'image Docker" -ForegroundColor White
            Write-Host ""
            
            $choice = Read-Host "Entrez votre choix (1-5)"
            
            switch ($choice) {
                1 { Deploy-Locally }
                2 { 
                    if (Build-DockerImage) { Deploy-ToDockerHub } 
                }
                3 { 
                    if (Build-DockerImage) { Deploy-ToRender } 
                }
                4 { Deploy-Automatically }
                5 { Build-DockerImage }
                default { 
                    Write-Host "Choix invalide!" -ForegroundColor Red
                    exit 1
                }
            }
        }
        "local" { 
            if (Build-DockerImage) { Deploy-Locally } 
        }
        "dockerhub" { 
            if (Build-DockerImage) { Deploy-ToDockerHub } 
        }
        "render" { 
            if (Build-DockerImage) { Deploy-ToRender } 
        }
        default {
            Write-Host "Plateforme non reconnue: $Platform" -ForegroundColor Red
            exit 1
        }
    }
}