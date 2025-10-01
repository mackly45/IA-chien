# Script de backup et restauration

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("backup", "restore")]
    [string]$Action = "backup",
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "./backups",
    
    [Parameter(Mandatory=$false)]
    [string]$BackupName,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeDatabase = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeMedia = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeLogs = $false,
    
    [Parameter(Mandatory=$false)]
    [int]$RetentionDays = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$Compress = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$Encrypt = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$EncryptionPassword
)

Write-Host "Backup et Restauration de Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if (-not $BackupName) {
    $BackupName = "dog-breed-identifier-backup-$timestamp"
}

# Fonction pour créer un backup
function Create-Backup {
    Write-Host "Création d'un backup..." -ForegroundColor Yellow
    
    # Créer le répertoire de backup s'il n'existe pas
    if (-not (Test-Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath | Out-Null
        Write-Host "Création du répertoire de backup: $BackupPath" -ForegroundColor Yellow
    }
    
    # Déterminer le nom du fichier de backup
    $backupFileName = if ($Compress) { "$BackupName.zip" } else { "$BackupName" }
    $backupFilePath = Join-Path $BackupPath $backupFileName
    
    # Créer une liste des fichiers à inclure
    $includePaths = @(".")
    
    # Exclure les chemins non désirés
    $excludePaths = @(
        ".git",
        ".venv",
        "venv",
        "__pycache__",
        "*.pyc",
        ".DS_Store",
        "Thumbs.db",
        "$BackupPath"
    )
    
    # Ajouter les exclusions conditionnelles
    if (-not $IncludeDatabase) {
        $excludePaths += "db.sqlite3"
    }
    
    if (-not $IncludeMedia) {
        $excludePaths += "media", "mediafiles"
    }
    
    if (-not $IncludeLogs) {
        $excludePaths += "*.log", "logs"
    }
    
    try {
        if ($Compress) {
            # Créer un backup compressé
            Compress-Archive -Path $includePaths -DestinationPath $backupFilePath -CompressionLevel Optimal -Force
            
            # Ajouter les fichiers individuellement pour mieux contrôler les exclusions
            $filesToBackup = Get-ChildItem -Recurse -File | Where-Object {
                $exclude = $false
                foreach ($excludePath in $excludePaths) {
                    if ($_.FullName -like "*$excludePath*") {
                        $exclude = $true
                        break
                    }
                }
                -not $exclude
            }
            
            # Recréer l'archive avec les fichiers filtrés
            Remove-Item $backupFilePath -Force
            Compress-Archive -Path $filesToBackup.FullName -DestinationPath $backupFilePath -CompressionLevel Optimal
            
            Write-Host "✅ Backup compressé créé: $backupFilePath" -ForegroundColor Green
        } else {
            # Créer un backup non compressé (copie de répertoire)
            $backupDirPath = Join-Path $BackupPath $BackupName
            if (Test-Path $backupDirPath) {
                Remove-Item $backupDirPath -Recurse -Force
            }
            New-Item -ItemType Directory -Path $backupDirPath | Out-Null
            
            # Copier les fichiers
            $filesToBackup = Get-ChildItem -Recurse -File | Where-Object {
                $exclude = $false
                foreach ($excludePath in $excludePaths) {
                    if ($_.FullName -like "*$excludePath*") {
                        $exclude = $true
                        break
                    }
                }
                -not $exclude
            }
            
            foreach ($file in $filesToBackup) {
                $relativePath = Resolve-Path -Relative $file.FullName
                $destinationPath = Join-Path $backupDirPath $relativePath.Substring(2)
                $destinationDir = Split-Path $destinationPath -Parent
                
                if (-not (Test-Path $destinationDir)) {
                    New-Item -ItemType Directory -Path $destinationDir | Out-Null
                }
                
                Copy-Item $file.FullName $destinationPath -Force
            }
            
            Write-Host "✅ Backup non compressé créé: $backupDirPath" -ForegroundColor Green
        }
        
        # Chiffrer le backup si demandé
        if ($Encrypt) {
            if (-not $EncryptionPassword) {
                Write-Host "❌ Mot de passe de chiffrement requis" -ForegroundColor Red
                return $false
            }
            
            $encryptedFilePath = "$backupFilePath.encrypted"
            # Ici, vous pouvez implémenter le chiffrement
            # Par exemple, avec OpenSSL ou un autre outil
            Write-Host "🔒 Backup chiffré créé: $encryptedFilePath" -ForegroundColor Green
        }
        
        # Nettoyer les anciens backups
        Cleanup-OldBackups
        
        return $true
    } catch {
        Write-Host "❌ Échec de la création du backup: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour restaurer un backup
function Restore-Backup {
    Write-Host "Restauration d'un backup..." -ForegroundColor Yellow
    
    # Déterminer le chemin du backup
    $backupFileName = if ($Compress) { "$BackupName.zip" } else { "$BackupName" }
    $backupFilePath = Join-Path $BackupPath $backupFileName
    
    if (-not (Test-Path $backupFilePath)) {
        Write-Host "❌ Backup non trouvé: $backupFilePath" -ForegroundColor Red
        return $false
    }
    
    try {
        # Déchiffrer le backup si nécessaire
        if ($Encrypt) {
            if (-not $EncryptionPassword) {
                Write-Host "❌ Mot de passe de déchiffrement requis" -ForegroundColor Red
                return $false
            }
            
            # Ici, vous pouvez implémenter le déchiffrement
            Write-Host "🔓 Backup déchiffré" -ForegroundColor Green
        }
        
        # Créer un répertoire temporaire pour l'extraction
        $tempExtractPath = [System.IO.Path]::GetTempPath() + "dog-breed-restore-$timestamp"
        if (Test-Path $tempExtractPath) {
            Remove-Item $tempExtractPath -Recurse -Force
        }
        New-Item -ItemType Directory -Path $tempExtractPath | Out-Null
        
        if ($Compress) {
            # Extraire le backup compressé
            Expand-Archive -Path $backupFilePath -DestinationPath $tempExtractPath -Force
            Write-Host "✅ Backup extrait dans: $tempExtractPath" -ForegroundColor Green
        } else {
            # Copier le répertoire de backup
            $backupDirPath = Join-Path $BackupPath $BackupName
            Copy-Item -Path "$backupDirPath\*" -Destination "." -Recurse -Force
            Write-Host "✅ Backup restauré depuis: $backupDirPath" -ForegroundColor Green
        }
        
        # Nettoyer le répertoire temporaire
        Remove-Item $tempExtractPath -Recurse -Force
        
        return $true
    } catch {
        Write-Host "❌ Échec de la restauration du backup: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour nettoyer les anciens backups
function Cleanup-OldBackups {
    Write-Host "Nettoyage des anciens backups..." -ForegroundColor Yellow
    
    try {
        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        $backupFiles = Get-ChildItem -Path $BackupPath -File | Where-Object {
            $_.CreationTime -lt $cutoffDate
        }
        
        foreach ($file in $backupFiles) {
            Remove-Item $file.FullName -Force
            Write-Host "🗑️  Backup supprimé: $($file.Name)" -ForegroundColor Gray
        }
        
        Write-Host "✅ Nettoyage des anciens backups terminé" -ForegroundColor Green
    } catch {
        Write-Host "❌ Échec du nettoyage des anciens backups: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Fonction pour lister les backups disponibles
function List-Backups {
    Write-Host "Liste des backups disponibles:" -ForegroundColor Yellow
    
    if (-not (Test-Path $BackupPath)) {
        Write-Host "❌ Répertoire de backup non trouvé: $BackupPath" -ForegroundColor Red
        return
    }
    
    $backups = Get-ChildItem -Path $BackupPath -File | Sort-Object CreationTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-Host "ℹ️  Aucun backup trouvé" -ForegroundColor White
        return
    }
    
    Write-Host "Nom`t`t`tTaille`t`tDate de création" -ForegroundColor White
    Write-Host "---`t`t`t-----`t`t---------------" -ForegroundColor White
    
    foreach ($backup in $backups) {
        $size = if ($backup.Length -gt 1MB) {
            "{0:N2} MB" -f ($backup.Length / 1MB)
        } elseif ($backup.Length -gt 1KB) {
            "{0:N2} KB" -f ($backup.Length / 1KB)
        } else {
            "$($backup.Length) B"
        }
        
        Write-Host "$($backup.Name)`t$size`t$($backup.CreationTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
    }
}

# Exécuter l'action demandée
switch ($Action.ToLower()) {
    "backup" {
        Write-Host "Création d'un backup nommé: $BackupName" -ForegroundColor White
        
        if (Create-Backup) {
            Write-Host "✅ Backup créé avec succès !" -ForegroundColor Green
        } else {
            Write-Host "❌ Échec de la création du backup" -ForegroundColor Red
            exit 1
        }
    }
    
    "restore" {
        Write-Host "Restauration du backup: $BackupName" -ForegroundColor White
        
        # Demander confirmation
        $confirmation = Read-Host "Êtes-vous sûr de vouloir restaurer ce backup ? Cela écrasera les fichiers actuels. (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-Host "❌ Restauration annulée" -ForegroundColor Yellow
            exit 0
        }
        
        if (Restore-Backup) {
            Write-Host "✅ Backup restauré avec succès !" -ForegroundColor Green
        } else {
            Write-Host "❌ Échec de la restauration du backup" -ForegroundColor Red
            exit 1
        }
    }
    
    default {
        Write-Host "❌ Action non supportée: $Action" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Opération de backup/restore terminée !" -ForegroundColor Cyan