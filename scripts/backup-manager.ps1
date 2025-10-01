# Script de gestion des sauvegardes

param(
    [Parameter(Mandatory=$false)]
    [string]$BackupDir = "./backups",
    
    [Parameter(Mandatory=$false)]
    [string[]]$SourceDirs = @("./dog_breed_identifier", "./data", "./media"),
    
    [Parameter(Mandatory=$false)]
    [int]$RetentionDays = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$Compress = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$Encrypt = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$EncryptionKey = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Verify = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$List = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean = $false
)

Write-Host "Gestion des sauvegardes" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

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

# Fonction pour créer une sauvegarde
function Create-Backup {
    param(
        [array]$Sources,
        [string]$DestDir,
        [string]$Timestamp
    )
    
    try {
        # Créer le répertoire de destination s'il n'existe pas
        if (-not (Test-Path $DestDir)) {
            New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
            Write-Log "Répertoire de sauvegarde créé: $DestDir" "INFO"
        }
        
        # Créer le nom de la sauvegarde
        $backupName = "backup-$Timestamp"
        $backupPath = Join-Path $DestDir $backupName
        
        Write-Log "Création de la sauvegarde: $backupName" "INFO"
        
        # Créer un répertoire pour la sauvegarde
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        
        # Copier chaque source
        foreach ($source in $Sources) {
            if (Test-Path $source) {
                Write-Log "Sauvegarde de: $source" "INFO"
                
                # Déterminer le nom de destination
                $destPath = Join-Path $backupPath (Split-Path $source -Leaf)
                
                # Copier le contenu
                Copy-Item -Path $source -Destination $destPath -Recurse -Force
            } else {
                Write-Log "Source non trouvée: $source" "WARN"
            }
        }
        
        # Compresser si demandé
        if ($Compress) {
            $compressedPath = "$backupPath.zip"
            Write-Log "Compression de la sauvegarde..." "INFO"
            Compress-Archive -Path $backupPath -DestinationPath $compressedPath -Force
            Remove-Item -Path $backupPath -Recurse -Force
            Write-Log "Sauvegarde compressée: $compressedPath" "SUCCESS"
            return $compressedPath
        }
        
        Write-Log "Sauvegarde créée: $backupPath" "SUCCESS"
        return $backupPath
    } catch {
        Write-Log "Erreur lors de la création de la sauvegarde: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Fonction pour lister les sauvegardes
function Get-Backups {
    param([string]$BackupDirectory)
    
    if (-not (Test-Path $BackupDirectory)) {
        Write-Log "Répertoire de sauvegarde non trouvé: $BackupDirectory" "WARN"
        return @()
    }
    
    $backups = Get-ChildItem -Path $BackupDirectory -File | Sort-Object CreationTime -Descending
    return $backups
}

# Fonction pour nettoyer les anciennes sauvegardes
function Remove-OldBackups {
    param([string]$BackupDirectory, [int]$Days)
    
    if (-not (Test-Path $BackupDirectory)) {
        Write-Log "Répertoire de sauvegarde non trouvé: $BackupDirectory" "WARN"
        return
    }
    
    $cutoffDate = (Get-Date).AddDays(-$Days)
    $oldBackups = Get-ChildItem -Path $BackupDirectory -File | Where-Object { $_.CreationTime -lt $cutoffDate }
    
    if ($oldBackups.Count -gt 0) {
        Write-Log "Nettoyage des sauvegardes plus anciennes que $Days jours..." "INFO"
        foreach ($backup in $oldBackups) {
            Remove-Item -Path $backup.FullName -Force
            Write-Log "Sauvegarde supprimée: $($backup.Name)" "INFO"
        }
        Write-Log "Nettoyage terminé: $($oldBackups.Count) sauvegardes supprimées" "SUCCESS"
    } else {
        Write-Log "Aucune sauvegarde ancienne à supprimer" "INFO"
    }
}

# Fonction pour vérifier une sauvegarde
function Test-Backup {
    param([string]$BackupPath)
    
    if (-not (Test-Path $BackupPath)) {
        Write-Log "Sauvegarde non trouvée: $BackupPath" "ERROR"
        return $false
    }
    
    # Vérifier l'intégrité de l'archive si c'est un fichier ZIP
    if ($BackupPath -like "*.zip") {
        try {
            Expand-Archive -Path $BackupPath -DestinationPath "$BackupPath-test" -Force
            Remove-Item -Path "$BackupPath-test" -Recurse -Force
            Write-Log "Sauvegarde vérifiée avec succès: $BackupPath" "SUCCESS"
            return $true
        } catch {
            Write-Log "Sauvegarde corrompue: $BackupPath" "ERROR"
            return $false
        }
    } else {
        # Pour les sauvegardes non compressées, vérifier l'existence
        if (Test-Path $BackupPath) {
            Write-Log "Sauvegarde vérifiée avec succès: $BackupPath" "SUCCESS"
            return $true
        } else {
            Write-Log "Sauvegarde non trouvée: $BackupPath" "ERROR"
            return $false
        }
    }
}

# Fonction pour restaurer une sauvegarde
function Restore-Backup {
    param([string]$BackupPath, [string]$RestoreDir)
    
    if (-not (Test-Path $BackupPath)) {
        Write-Log "Sauvegarde non trouvée: $BackupPath" "ERROR"
        return $false
    }
    
    try {
        Write-Log "Restauration de la sauvegarde: $BackupPath" "INFO"
        
        # Créer le répertoire de restauration s'il n'existe pas
        if (-not (Test-Path $RestoreDir)) {
            New-Item -ItemType Directory -Path $RestoreDir -Force | Out-Null
        }
        
        # Extraire ou copier la sauvegarde
        if ($BackupPath -like "*.zip") {
            Expand-Archive -Path $BackupPath -DestinationPath $RestoreDir -Force
        } else {
            Copy-Item -Path $BackupPath -Destination $RestoreDir -Recurse -Force
        }
        
        Write-Log "Sauvegarde restaurée dans: $RestoreDir" "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de la restauration: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Mode liste
if ($List) {
    Write-Log "Liste des sauvegardes dans $BackupDir" "INFO"
    $backups = Get-Backups -BackupDirectory $BackupDir
    
    if ($backups.Count -gt 0) {
        Write-Host "Sauvegardes disponibles:" -ForegroundColor White
        foreach ($backup in $backups) {
            $age = (Get-Date) - $backup.CreationTime
            Write-Host "  $($backup.Name) - Taille: $($backup.Length) octets - Age: $($age.Days) jours" -ForegroundColor Gray
        }
    } else {
        Write-Log "Aucune sauvegarde trouvée" "INFO"
    }
    
    exit 0
}

# Mode nettoyage
if ($Clean) {
    Remove-OldBackups -BackupDirectory $BackupDir -Days $RetentionDays
    exit 0
}

# Créer une sauvegarde
Write-Log "Création d'une sauvegarde des répertoires: $($SourceDirs -join ', ')" "INFO"
$backupResult = Create-Backup -Sources $SourceDirs -DestDir $BackupDir -Timestamp $timestamp

if ($backupResult) {
    # Vérifier la sauvegarde si demandé
    if ($Verify) {
        Write-Log "Vérification de la sauvegarde..." "INFO"
        $verificationResult = Test-Backup -BackupPath $backupResult
        if ($verificationResult) {
            Write-Log "Sauvegarde vérifiée avec succès" "SUCCESS"
        } else {
            Write-Log "Échec de la vérification de la sauvegarde" "ERROR"
            exit 1
        }
    }
    
    # Nettoyer les anciennes sauvegardes
    Remove-OldBackups -BackupDirectory $BackupDir -Days $RetentionDays
    
    Write-Log "Sauvegarde terminée avec succès !" "SUCCESS"
} else {
    Write-Log "Échec de la sauvegarde" "ERROR"
    exit 1
}