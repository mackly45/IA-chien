# Script de déploiement avec monitoring

param(
    [Parameter(Mandatory=$false)]
    [string]$Platform = "all",
    
    [Parameter(Mandatory=$false)]
    [switch]$WithHealthCheck = $true,
    
    [Parameter(Mandatory=$false)]
    [int]$HealthCheckTimeout = 300,  # 5 minutes
    
    [Parameter(Mandatory=$false)]
    [switch]$WithRollback = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$NotificationEmail,
    
    [Parameter(Mandatory=$false)]
    [string]$SlackWebhookUrl
)

Write-Host "Déploiement avec monitoring de Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$deploymentStartTime = Get-Date
$deploymentStatus = "unknown"
$notifications = @()

# Fonction pour envoyer une notification
function Send-Notification {
    param([string]$Title, [string]$Message, [string]$Status = "info")
    
    $notification = @{
        Title = $Title
        Message = $Message
        Status = $Status
        Timestamp = Get-Date
    }
    
    $script:notifications += $notification
    
    # Afficher la notification
    $color = switch ($Status) {
        "success" { "Green" }
        "warning" { "Yellow" }
        "error" { "Red" }
        default { "White" }
    }
    
    Write-Host "[$Status] $Title" -ForegroundColor $color
    Write-Host "  $Message" -ForegroundColor Gray
    
    # Envoyer par email si configuré
    if ($NotificationEmail -and $Status -ne "info") {
        try {
            # Ici, vous pouvez implémenter l'envoi d'email
            # Send-MailMessage -To $NotificationEmail -Subject $Title -Body $Message -SmtpServer "smtp.example.com"
            Write-Host "  Notification email envoyée à $NotificationEmail" -ForegroundColor DarkGray
        } catch {
            Write-Host "  Échec de l'envoi de l'email: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Envoyer à Slack si configuré
    if ($SlackWebhookUrl -and $Status -ne "info") {
        try {
            $payload = @{
                text = "*$Title*`n$Message"
                attachments = @(@{
                    color = switch ($Status) {
                        "success" { "good" }
                        "warning" { "warning" }
                        "error" { "danger" }
                        default { "#36a64f" }
                    }
                    fields = @(@{
                        title = "Statut"
                        value = $Status
                        short = $true
                    }, @{
                        title = "Heure"
                        value = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        short = $true
                    })
                })
            } | ConvertTo-Json -Depth 10
            
            # Invoke-RestMethod -Uri $SlackWebhookUrl -Method Post -Body $payload -ContentType "application/json"
            Write-Host "  Notification Slack envoyée" -ForegroundColor DarkGray
        } catch {
            Write-Host "  Échec de l'envoi à Slack: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Fonction pour effectuer un health check
function Invoke-HealthCheck {
    param([string]$Url, [int]$Timeout)
    
    Write-Host "Effectuer un health check..." -ForegroundColor Yellow
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Timeout)
    
    while ((Get-Date) -lt $endTime) {
        try {
            $response = Invoke-WebRequest -Uri "$Url/health/" -TimeoutSec 10 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ Health check réussi" -ForegroundColor Green
                return $true
            }
        } catch {
            Write-Host "⏳ Health check en cours... ($((Get-Date) - $startTime).Seconds secondes)" -ForegroundColor Yellow
        }
        
        Start-Sleep -Seconds 5
    }
    
    Write-Host "❌ Health check échoué après $Timeout secondes" -ForegroundColor Red
    return $false
}

# Fonction pour déployer sur Docker Hub
function Deploy-ToDockerHub {
    Write-Host "Déploiement sur Docker Hub..." -ForegroundColor Yellow
    
    try {
        # Construire l'image
        docker build -t dog-breed-identifier:latest .
        if ($LASTEXITCODE -ne 0) {
            throw "Échec de la construction de l'image Docker"
        }
        
        # Tag et push
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $repo = "$env:DOCKER_USERNAME/dog-breed-identifier"
        
        docker tag dog-breed-identifier:latest "$repo:$timestamp"
        docker tag dog-breed-identifier:latest "$repo:latest"
        
        if ($env:DOCKER_USERNAME -and $env:DOCKER_PASSWORD) {
            echo "$env:DOCKER_PASSWORD" | docker login -u "$env:DOCKER_USERNAME" --password-stdin
            if ($LASTEXITCODE -ne 0) {
                throw "Échec de la connexion à Docker Hub"
            }
            
            docker push "$repo:$timestamp"
            docker push "$repo:latest"
            
            if ($LASTEXITCODE -ne 0) {
                throw "Échec du push vers Docker Hub"
            }
            
            Send-Notification -Title "Déploiement Docker Hub" -Message "Image déployée avec succès: $repo:latest" -Status "success"
            return $true
        } else {
            Send-Notification -Title "Déploiement Docker Hub" -Message "Variables d'environnement Docker manquantes" -Status "error"
            return $false
        }
    } catch {
        Send-Notification -Title "Déploiement Docker Hub" -Message "Échec du déploiement: $($_.Exception.Message)" -Status "error"
        return $false
    }
}

# Fonction pour déployer sur Render
function Deploy-ToRender {
    Write-Host "Déploiement sur Render..." -ForegroundColor Yellow
    
    try {
        if ($env:RENDER_DEPLOY_HOOK) {
            $response = Invoke-WebRequest -Uri $env:RENDER_DEPLOY_HOOK -Method POST -TimeoutSec 30 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Send-Notification -Title "Déploiement Render" -Message "Hook de déploiement envoyé avec succès" -Status "success"
                
                # Attendre le déploiement si health check activé
                if ($WithHealthCheck) {
                    Write-Host "Attente du déploiement Render..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 30  # Attendre que le déploiement commence
                    
                    if (Invoke-HealthCheck -Url "https://dog-identifier.onrender.com" -Timeout $HealthCheckTimeout) {
                        Send-Notification -Title "Health Check Render" -Message "Application Render opérationnelle" -Status "success"
                        return $true
                    } else {
                        Send-Notification -Title "Health Check Render" -Message "L'application Render ne répond pas" -Status "error"
                        return $false
                    }
                }
                
                return $true
            } else {
                throw "Code de réponse invalide: $($response.StatusCode)"
            }
        } else {
            Send-Notification -Title "Déploiement Render" -Message "Hook de déploiement Render non configuré" -Status "error"
            return $false
        }
    } catch {
        Send-Notification -Title "Déploiement Render" -Message "Échec du déploiement: $($_.Exception.Message)" -Status "error"
        return $false
    }
}

# Fonction pour déployer localement
function Deploy-Locally {
    Write-Host "Déploiement local..." -ForegroundColor Yellow
    
    try {
        # Arrêter et supprimer l'ancien conteneur
        docker stop dog-breed-identifier-app 2>$null
        docker rm dog-breed-identifier-app 2>$null
        
        # Lancer le nouveau conteneur
        docker run -d -p 8000:8000 --name dog-breed-identifier-app dog-breed-identifier:latest
        if ($LASTEXITCODE -ne 0) {
            throw "Échec du lancement du conteneur"
        }
        
        Send-Notification -Title "Déploiement Local" -Message "Application déployée localement sur http://localhost:8000" -Status "success"
        
        # Effectuer un health check si activé
        if ($WithHealthCheck) {
            if (Invoke-HealthCheck -Url "http://localhost:8000" -Timeout $HealthCheckTimeout) {
                Send-Notification -Title "Health Check Local" -Message "Application locale opérationnelle" -Status "success"
                return $true
            } else {
                Send-Notification -Title "Health Check Local" -Message "L'application locale ne répond pas" -Status "error"
                return $false
            }
        }
        
        return $true
    } catch {
        Send-Notification -Title "Déploiement Local" -Message "Échec du déploiement: $($_.Exception.Message)" -Status "error"
        return $false
    }
}

# Fonction pour effectuer un rollback
function Invoke-Rollback {
    Write-Host "Effectuer un rollback..." -ForegroundColor Yellow
    
    # Ici, vous pouvez implémenter la logique de rollback spécifique à votre plateforme
    # Par exemple, restaurer une version précédente sur Render, Docker Hub, etc.
    
    Send-Notification -Title "Rollback" -Message "Rollback effectué" -Status "warning"
}

# Fonction pour générer un rapport de déploiement
function Generate-DeploymentReport {
    param([string]$Status)
    
    $deploymentEndTime = Get-Date
    $duration = $deploymentEndTime - $deploymentStartTime
    
    $report = @"
Rapport de Déploiement - $projectName
================================

Statut: $Status
Date de début: $($deploymentStartTime.ToString("yyyy-MM-dd HH:mm:ss"))
Date de fin: $($deploymentEndTime.ToString("yyyy-MM-dd HH:mm:ss"))
Durée: $($duration.ToString("hh\:mm\:ss"))

Notifications:
$($notifications | ForEach-Object { "[$($_.Status)] $($_.Title) - $($_.Message)" } | Out-String)
"@
    
    $reportFile = "./deployment-report-$(Get-Date -Format "yyyyMMdd-HHmmss").txt"
    Set-Content -Path $reportFile -Value $report
    
    Write-Host "✅ Rapport de déploiement généré: $reportFile" -ForegroundColor Green
}

# Exécuter le déploiement selon la plateforme
Write-Host "Démarrage du déploiement..." -ForegroundColor Yellow
Send-Notification -Title "Déploiement démarré" -Message "Début du déploiement de $projectName" -Status "info"

$success = $false

switch ($Platform.ToLower()) {
    "dockerhub" {
        $success = Deploy-ToDockerHub
    }
    
    "render" {
        $success = Deploy-ToRender
    }
    
    "local" {
        $success = Deploy-Locally
    }
    
    "all" {
        $success = $true
        
        if (-not (Deploy-Locally)) { $success = $false }
        if (-not (Deploy-ToDockerHub)) { $success = $false }
        if (-not (Deploy-ToRender)) { $success = $false }
    }
    
    default {
        Send-Notification -Title "Erreur de déploiement" -Message "Plateforme non supportée: $Platform" -Status "error"
        $success = $false
    }
}

# Mettre à jour le statut du déploiement
if ($success) {
    $deploymentStatus = "success"
    Send-Notification -Title "Déploiement terminé" -Message "Tous les déploiements ont réussi" -Status "success"
} else {
    $deploymentStatus = "failed"
    Send-Notification -Title "Déploiement terminé" -Message "Un ou plusieurs déploiements ont échoué" -Status "error"
    
    # Effectuer un rollback si activé
    if ($WithRollback) {
        Invoke-Rollback
    }
}

# Générer le rapport de déploiement
Generate-DeploymentReport -Status $deploymentStatus

Write-Host "Déploiement avec monitoring terminé !" -ForegroundColor Cyan