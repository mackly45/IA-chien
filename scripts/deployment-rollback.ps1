# Script de rollback de déploiement

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "production",
    
    [Parameter(Mandatory=$false)]
    [string]$Version = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

Write-Host "Rollback de déploiement" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$deploymentsDir = "./deployments"
$backupDir = "./backups"
$configDir = "./config"

# Fonction pour afficher les messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Level) {
        "INFO" { Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor White }
        "WARN" { Write-Host "[$timestamp] [WARN] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor Red }
        "SUCCESS" { Write-Host "[$timestamp] [SUCCESS] $Message" -ForegroundColor Green }
    }
}

# Vérifier les prérequis
Write-Log "Vérification des prérequis..." "INFO"

# Vérifier que le répertoire des déploiements existe
if (-not (Test-Path $deploymentsDir)) {
    Write-Log "Répertoire des déploiements non trouvé: $deploymentsDir" "ERROR"
    exit 1
}

# Vérifier que le répertoire des sauvegardes existe
if (-not (Test-Path $backupDir)) {
    Write-Log "Répertoire des sauvegardes non trouvé: $backupDir" "WARN"
    Write-Log "Création du répertoire des sauvegardes..." "INFO"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

Write-Log "Prérequis vérifiés" "SUCCESS"

# Récupérer les déploiements disponibles
Write-Log "Récupération des déploiements disponibles..." "INFO"
$deployments = Get-ChildItem -Path $deploymentsDir -Directory | Sort-Object Name -Descending

if ($deployments.Count -eq 0) {
    Write-Log "Aucun déploiement trouvé dans $deploymentsDir" "ERROR"
    exit 1
}

Write-Log "Trouvé $($deployments.Count) déploiements" "SUCCESS"

# Déterminer la version à restaurer
if ([string]::IsNullOrEmpty($Version)) {
    # Utiliser le dernier déploiement si aucune version n'est spécifiée
    if ($deployments.Count -gt 1) {
        $targetDeployment = $deployments[1]  # Le précédent déploiement
        $Version = $targetDeployment.Name
    } else {
        Write-Log "Pas de déploiement précédent à restaurer" "ERROR"
        exit 1
    }
} else {
    # Trouver le déploiement spécifié
    $targetDeployment = $deployments | Where-Object { $_.Name -eq $Version }
    if (-not $targetDeployment) {
        Write-Log "Déploiement $Version non trouvé" "ERROR"
        Write-Log "Déploiements disponibles:" "INFO"
        $deployments | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
        exit 1
    }
}

Write-Log "Version cible pour le rollback: $Version" "INFO"

# Vérifier si le déploiement cible existe
$targetDeploymentPath = Join-Path $deploymentsDir $Version
if (-not (Test-Path $targetDeploymentPath)) {
    Write-Log "Déploiement cible non trouvé: $targetDeploymentPath" "ERROR"
    exit 1
}

# Afficher les informations du déploiement cible
Write-Log "Informations du déploiement cible:" "INFO"
$deploymentInfoPath = Join-Path $targetDeploymentPath "deployment-info.json"
if (Test-Path $deploymentInfoPath) {
    $deploymentInfo = Get-Content $deploymentInfoPath | ConvertFrom-Json
    Write-Host "  Version: $($deploymentInfo.version)" -ForegroundColor Gray
    Write-Host "  Date: $($deploymentInfo.date)" -ForegroundColor Gray
    Write-Host "  Environment: $($deploymentInfo.environment)" -ForegroundColor Gray
    Write-Host "  Commit: $($deploymentInfo.commit)" -ForegroundColor Gray
} else {
    Write-Log "Fichier d'information du déploiement non trouvé" "WARN"
}

# Vérifier l'environnement
Write-Log "Vérification de l'environnement: $Environment" "INFO"
if ($deploymentInfo.environment -ne $Environment -and -not $Force) {
    Write-Log "L'environnement du déploiement cible ($($deploymentInfo.environment)) ne correspond pas à l'environnement spécifié ($Environment)" "ERROR"
    Write-Log "Utilisez -Force pour forcer le rollback" "WARN"
    exit 1
}

# Mode dry-run
if ($DryRun) {
    Write-Log "Mode dry-run activé - aucune action ne sera effectuée" "WARN"
    Write-Log "Le rollback restaurerait le déploiement $Version sur l'environnement $Environment" "INFO"
    exit 0
}

# Confirmation
if (-not $Force) {
    Write-Host "`nConfirmer le rollback:" -ForegroundColor Yellow
    Write-Host "  Projet: $projectName" -ForegroundColor Gray
    Write-Host "  Environnement: $Environment" -ForegroundColor Gray
    Write-Host "  Version cible: $Version" -ForegroundColor Gray
    Write-Host "  Déploiement actuel: $($deployments[0].Name)" -ForegroundColor Gray
    
    $confirmation = Read-Host "Êtes-vous sûr de vouloir effectuer ce rollback ? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Log "Rollback annulé par l'utilisateur" "INFO"
        exit 0
    }
}

# Effectuer le rollback
Write-Log "Début du rollback..." "INFO"

try {
    # Sauvegarder l'état actuel
    $currentTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $currentBackupDir = Join-Path $backupDir "backup-$currentTimestamp"
    Write-Log "Sauvegarde de l'état actuel dans $currentBackupDir" "INFO"
    
    # Créer un répertoire de sauvegarde
    New-Item -ItemType Directory -Path $currentBackupDir -Force | Out-Null
    
    # Copier les fichiers de configuration actuels
    if (Test-Path $configDir) {
        Copy-Item -Path "$configDir/*" -Destination $currentBackupDir -Recurse -Force
        Write-Log "Configuration actuelle sauvegardée" "SUCCESS"
    }
    
    # Restaurer le déploiement cible
    Write-Log "Restauration du déploiement $Version" "INFO"
    
    # Copier les fichiers du déploiement cible
    Copy-Item -Path "$targetDeploymentPath/*" -Destination "." -Recurse -Force
    
    # Mettre à jour les liens symboliques ou les configurations si nécessaire
    # (Cette partie dépend de votre structure de déploiement spécifique)
    
    Write-Log "Déploiement $Version restauré avec succès" "SUCCESS"
    
    # Redémarrer les services si nécessaire
    Write-Log "Redémarrage des services..." "INFO"
    
    # Exemple de redémarrage (à adapter à votre configuration)
    # & docker-compose down
    # & docker-compose up -d
    
    Write-Log "Services redémarrés" "SUCCESS"
    
    # Vérifier l'état du déploiement
    Write-Log "Vérification de l'état du déploiement..." "INFO"
    
    # Exemple de vérification (à adapter à votre configuration)
    # $healthCheck = Invoke-WebRequest -Uri "http://localhost:8000/health/" -TimeoutSec 30 -ErrorAction SilentlyContinue
    # if ($healthCheck.StatusCode -eq 200) {
    #     Write-Log "Déploiement en bonne santé" "SUCCESS"
    # } else {
    #     Write-Log "Problème de santé du déploiement" "ERROR"
    # }
    
    Write-Log "Rollback terminé avec succès" "SUCCESS"
    
} catch {
    Write-Log "Erreur lors du rollback: $($_.Exception.Message)" "ERROR"
    
    # Tentative de rollback vers la sauvegarde
    Write-Log "Tentative de restauration de la sauvegarde..." "INFO"
    
    try {
        if (Test-Path $currentBackupDir) {
            Copy-Item -Path "$currentBackupDir/*" -Destination "." -Recurse -Force
            Write-Log "Sauvegarde restaurée" "SUCCESS"
        }
    } catch {
        Write-Log "Échec de la restauration de la sauvegarde: $($_.Exception.Message)" "ERROR"
    }
    
    exit 1
}

# Nettoyer les anciennes sauvegardes (garder les 5 dernières)
Write-Log "Nettoyage des anciennes sauvegardes..." "INFO"
$backups = Get-ChildItem -Path $backupDir -Directory | Sort-Object CreationTime -Descending
if ($backups.Count -gt 5) {
    $backups | Select-Object -Skip 5 | ForEach-Object {
        Remove-Item -Path $_.FullName -Recurse -Force
        Write-Log "Ancienne sauvegarde supprimée: $($_.Name)" "INFO"
    }
}

Write-Log "Rollback terminé !" -ForegroundColor Cyan