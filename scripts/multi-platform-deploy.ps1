# Script de déploiement multi-plateformes

param(
    [Parameter(Mandatory=$false)]
    [string[]]$Platforms = @("dockerhub", "render"),
    
    [Parameter(Mandatory=$false)]
    [switch]$Parallel = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

Write-Host "Déploiement multi-plateformes de Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Variables de configuration
$DOCKER_IMAGE = "dog-breed-identifier"
$TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"

# Fonction pour construire l'image Docker
function Build-DockerImage {
    Write-Host "Construction de l'image Docker..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "Simulation: Construction de l'image Docker" -ForegroundColor White
        return $true
    }
    
    docker build -t "$DOCKER_IMAGE`:$TIMESTAMP" .
    if ($LASTEXITCODE -eq 0) {
        docker tag "$DOCKER_IMAGE`:$TIMESTAMP" "$DOCKER_IMAGE`:latest"
        Write-Host "✅ Image Docker construite avec succès" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Échec de la construction de l'image Docker" -ForegroundColor Red
        return $false
    }
}

# Fonction pour déployer sur Docker Hub
function Deploy-ToDockerHub {
    param([string]$Username, [string]$Password)
    
    Write-Host "Déploiement sur Docker Hub..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "Simulation: Déploiement sur Docker Hub" -ForegroundColor White
        return $true
    }
    
    if (-not $Username -or -not $Password) {
        Write-Host "❌ Identifiants Docker Hub manquants" -ForegroundColor Red
        return $false
    }
    
    # Login Docker Hub
    $loginResult = echo "$Password" | docker login -u "$Username" --password-stdin 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Échec de la connexion à Docker Hub" -ForegroundColor Red
        return $false
    }
    
    # Tag et push
    $repo = "$Username/$DOCKER_IMAGE"
    docker tag "$DOCKER_IMAGE`:latest" "$repo`:$TIMESTAMP"
    docker tag "$DOCKER_IMAGE`:latest" "$repo`:latest"
    
    docker push "$repo`:$TIMESTAMP"
    docker push "$repo`:latest"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Image déployée sur Docker Hub: docker.io/$repo`:latest" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Échec du déploiement sur Docker Hub" -ForegroundColor Red
        return $false
    }
}

# Fonction pour déployer sur Render
function Deploy-ToRender {
    param([string]$DeployHook)
    
    Write-Host "Déploiement sur Render..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "Simulation: Déploiement sur Render" -ForegroundColor White
        return $true
    }
    
    if (-not $DeployHook) {
        Write-Host "❌ Hook de déploiement Render manquant" -ForegroundColor Red
        return $false
    }
    
    try {
        $response = Invoke-WebRequest -Uri $DeployHook -Method POST -TimeoutSec 30 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Hook de déploiement Render envoyé avec succès" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Échec de l'envoi du hook Render (Code: $($response.StatusCode))" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Échec de l'envoi du hook Render: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour déployer sur AWS ECR
function Deploy-ToAWS {
    param([string]$Region, [string]$AccountId)
    
    Write-Host "Déploiement sur AWS ECR..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "Simulation: Déploiement sur AWS ECR" -ForegroundColor White
        return $true
    }
    
    # Vérifier que AWS CLI est installé
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Host "❌ AWS CLI n'est pas installé" -ForegroundColor Red
        return $false
    }
    
    $repo = "$AccountId.dkr.ecr.$Region.amazonaws.com/$DOCKER_IMAGE"
    
    try {
        # Login ECR
        aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin "$AccountId.dkr.ecr.$Region.amazonaws.com"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Échec de la connexion à AWS ECR" -ForegroundColor Red
            return $false
        }
        
        # Tag et push
        docker tag "$DOCKER_IMAGE`:latest" "$repo`:$TIMESTAMP"
        docker tag "$DOCKER_IMAGE`:latest" "$repo`:latest"
        
        docker push "$repo`:$TIMESTAMP"
        docker push "$repo`:latest"
        
        Write-Host "✅ Image déployée sur AWS ECR: $repo`:latest" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Échec du déploiement sur AWS ECR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour déployer sur Google Container Registry
function Deploy-ToGCP {
    param([string]$ProjectId)
    
    Write-Host "Déploiement sur Google Container Registry..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "Simulation: Déploiement sur Google Container Registry" -ForegroundColor White
        return $true
    }
    
    # Vérifier que gcloud est installé
    if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Google Cloud SDK n'est pas installé" -ForegroundColor Red
        return $false
    }
    
    $repo = "gcr.io/$ProjectId/$DOCKER_IMAGE"
    
    try {
        # Tag et push
        docker tag "$DOCKER_IMAGE`:latest" "$repo`:$TIMESTAMP"
        docker tag "$DOCKER_IMAGE`:latest" "$repo`:latest"
        
        docker push "$repo`:$TIMESTAMP"
        docker push "$repo`:latest"
        
        Write-Host "✅ Image déployée sur Google Container Registry: $repo`:latest" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Échec du déploiement sur Google Container Registry: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Charger les variables d'environnement
$envVars = @{}
if (Test-Path ".env.local") {
    Get-Content ".env.local" | ForEach-Object {
        if ($_ -notmatch "^\s*#" -and $_ -match "([^=]+)=(.*)") {
            $name = $matches[1]
            $value = $matches[2].Trim()
            $envVars[$name] = $value
        }
    }
}

# Construire l'image Docker
if (-not (Build-DockerImage)) {
    Write-Host "❌ Échec de la construction de l'image" -ForegroundColor Red
    exit 1
}

# Déploiement séquentiel ou parallèle
if ($Parallel) {
    Write-Host "Déploiement parallèle sur les plateformes: $($Platforms -join ', ')" -ForegroundColor Yellow
    
    $jobs = @()
    
    foreach ($platform in $Platforms) {
        switch ($platform.ToLower()) {
            "dockerhub" {
                $job = Start-Job -ScriptBlock ${function:Deploy-ToDockerHub} -ArgumentList $envVars.DOCKER_USERNAME, $envVars.DOCKER_PASSWORD
                $jobs += @{Job = $job; Name = "DockerHub"}
            }
            
            "render" {
                $job = Start-Job -ScriptBlock ${function:Deploy-ToRender} -ArgumentList $envVars.RENDER_DEPLOY_HOOK
                $jobs += @{Job = $job; Name = "Render"}
            }
            
            "aws" {
                $job = Start-Job -ScriptBlock ${function:Deploy-ToAWS} -ArgumentList $envVars.AWS_REGION, $envVars.AWS_ACCOUNT_ID
                $jobs += @{Job = $job; Name = "AWS"}
            }
            
            "gcp" {
                $job = Start-Job -ScriptBlock ${function:Deploy-ToGCP} -ArgumentList $envVars.GCP_PROJECT_ID
                $jobs += @{Job = $job; Name = "GCP"}
            }
            
            default {
                Write-Host "Plateforme non supportée: $platform" -ForegroundColor Red
            }
        }
    }
    
    # Attendre la fin de tous les jobs
    $results = @()
    foreach ($jobInfo in $jobs) {
        $result = Receive-Job -Job $jobInfo.Job -Wait
        $results += @{Name = $jobInfo.Name; Success = $result}
        Remove-Job -Job $jobInfo.Job
    }
    
    # Afficher les résultats
    Write-Host "`nRésultats des déploiements:" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    foreach ($result in $results) {
        if ($result.Success) {
            Write-Host "✅ $($result.Name): Succès" -ForegroundColor Green
        } else {
            Write-Host "❌ $($result.Name): Échec" -ForegroundColor Red
        }
    }
} else {
    Write-Host "Déploiement séquentiel sur les plateformes: $($Platforms -join ', ')" -ForegroundColor Yellow
    
    $success = $true
    
    foreach ($platform in $Platforms) {
        switch ($platform.ToLower()) {
            "dockerhub" {
                if (-not (Deploy-ToDockerHub -Username $envVars.DOCKER_USERNAME -Password $envVars.DOCKER_PASSWORD)) {
                    $success = $false
                }
            }
            
            "render" {
                if (-not (Deploy-ToRender -DeployHook $envVars.RENDER_DEPLOY_HOOK)) {
                    $success = $false
                }
            }
            
            "aws" {
                if (-not (Deploy-ToAWS -Region $envVars.AWS_REGION -AccountId $envVars.AWS_ACCOUNT_ID)) {
                    $success = $false
                }
            }
            
            "gcp" {
                if (-not (Deploy-ToGCP -ProjectId $envVars.GCP_PROJECT_ID)) {
                    $success = $false
                }
            }
            
            default {
                Write-Host "Plateforme non supportée: $platform" -ForegroundColor Red
                $success = $false
            }
        }
    }
    
    if ($success) {
        Write-Host "✅ Tous les déploiements ont réussi" -ForegroundColor Green
    } else {
        Write-Host "❌ Un ou plusieurs déploiements ont échoué" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Déploiement multi-plateformes terminé !" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "⚠️  Ceci était une simulation (dry run)" -ForegroundColor Yellow
}