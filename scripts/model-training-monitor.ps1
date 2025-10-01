# Script de surveillance de l'entraînement du modèle

param(
    [Parameter(Mandatory=$false)]
    [int]$PollingInterval = 30,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxDuration = 3600,
    
    [Parameter(Mandatory=$false)]
    [string]$LogDir = "./logs",
    
    [Parameter(Mandatory=$false)]
    [switch]$Notify = $false
)

Write-Host "Surveillance de l'entraînement du modèle" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$startTime = Get-Date
$endTime = $startTime.AddSeconds($MaxDuration)
$trainingLogFile = Join-Path $LogDir "training.log"
$statsFile = Join-Path $LogDir "training-stats.json"

# Fonction pour afficher les messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor White }
        "WARN" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
    }
    
    # Écrire dans le fichier de log
    if (Test-Path $LogDir) {
        $logMessage | Out-File -FilePath $trainingLogFile -Append
    }
}

# Fonction pour envoyer une notification
function Send-Notification {
    param([string]$Title, [string]$Message)
    
    if ($Notify) {
        # Sur Windows, utiliser une notification toast
        try {
            # Créer une notification toast basique
            $notification = New-Object -ComObject Wscript.Shell
            $notification.Popup($Message, 0, $Title, 0x40) | Out-Null
        } catch {
            Write-Log "Impossible d'envoyer la notification: $($_.Exception.Message)" "WARN"
        }
    }
}

# Fonction pour récupérer les statistiques d'entraînement
function Get-TrainingStats {
    try {
        # Dans une implémentation réelle, cela ferait un appel API à l'application
        # Pour cette simulation, nous générons des statistiques aléatoires
        $stats = @{
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            epoch = Get-Random -Minimum 1 -Maximum 50
            loss = Get-Random -Minimum 0.1 -Maximum 2.0
            accuracy = Get-Random -Minimum 0.7 -Maximum 0.95
            val_loss = Get-Random -Minimum 0.2 -Maximum 2.5
            val_accuracy = Get-Random -Minimum 0.6 -Maximum 0.9
            learning_rate = Get-Random -Minimum 0.0001 -Maximum 0.01
        }
        
        return $stats
    } catch {
        Write-Log "Erreur lors de la récupération des statistiques: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Fonction pour afficher les statistiques
function Show-TrainingStats {
    param([hashtable]$Stats)
    
    if ($Stats) {
        Write-Host "  Époque: $($Stats.epoch)" -ForegroundColor Gray
        Write-Host "  Précision: $("{0:P2}" -f $Stats.accuracy)" -ForegroundColor Gray
        Write-Host "  Précision validation: $("{0:P2}" -f $Stats.val_accuracy)" -ForegroundColor Gray
        Write-Host "  Perte: $("{0:N4}" -f $Stats.loss)" -ForegroundColor Gray
        Write-Host "  Perte validation: $("{0:N4}" -f $Stats.val_loss)" -ForegroundColor Gray
    }
}

# Créer le répertoire de logs s'il n'existe pas
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    Write-Log "Répertoire de logs créé: $LogDir" "INFO"
}

# Initialiser la surveillance
Write-Log "Démarrage de la surveillance de l'entraînement" "INFO"
Write-Log "Intervalle de polling: ${PollingInterval}s" "INFO"
Write-Log "Durée maximale: ${MaxDuration}s" "INFO"
Send-Notification "Surveillance démarrée" "La surveillance de l'entraînement du modèle a commencé"

# Boucle de surveillance
$iteration = 0
while ((Get-Date) -lt $endTime) {
    $iteration++
    Write-Log "Vérification #$iteration..." "INFO"
    
    # Récupérer les statistiques d'entraînement
    $stats = Get-TrainingStats
    
    if ($stats) {
        # Afficher les statistiques
        Show-TrainingStats -Stats $stats
        
        # Enregistrer les statistiques dans un fichier JSON
        $stats | ConvertTo-Json | Out-File -FilePath $statsFile -Force
        
        # Vérifier si l'entraînement est terminé (simulation)
        if ($stats.epoch -ge 50) {
            Write-Log "Entraînement terminé!" "SUCCESS"
            Send-Notification "Entraînement terminé" "Le modèle a atteint l'époque 50"
            break
        }
        
        # Vérifier s'il y a des problèmes (simulation)
        if ($stats.loss -gt 2.0 -or $stats.val_loss -gt 3.0) {
            Write-Log "Problème détecté: Perte élevée" "WARN"
            Send-Notification "Problème d'entraînement" "Perte élevée détectée"
        }
    } else {
        Write-Log "Impossible de récupérer les statistiques" "ERROR"
    }
    
    # Attendre avant la prochaine vérification
    Start-Sleep -Seconds $PollingInterval
}

# Terminer la surveillance
$duration = (Get-Date) - $startTime
Write-Log "Surveillance terminée après $($duration.TotalSeconds) secondes" "INFO"
Send-Notification "Surveillance terminée" "La surveillance de l'entraînement est terminée"