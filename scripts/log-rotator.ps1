# Script de rotation des logs

param(
    [Parameter(Mandatory=$false)]
    [string]$LogDir = "./logs",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxSizeMB = 10,
    
    [Parameter(Mandatory=$false)]
    [int]$RetentionDays = 30,
    
    [Parameter(Mandatory=$false)]
    [int]$RetentionCount = 10,
    
    [Parameter(Mandatory=$false)]
    [switch]$Compress = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

Write-Host "Rotation des logs" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$maxSizeBytes = $MaxSizeMB * 1024 * 1024

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

# Fonction pour obtenir la taille d'un fichier
function Get-FileSize {
    param([string]$FilePath)
    
    if (Test-Path $FilePath) {
        $file = Get-Item $FilePath
        return $file.Length
    }
    return 0
}

# Fonction pour effectuer la rotation d'un fichier log
function Rotate-Log {
    param([string]$LogPath)
    
    try {
        $logName = [System.IO.Path]::GetFileNameWithoutExtension($LogPath)
        $logExtension = [System.IO.Path]::GetExtension($LogPath)
        $logDirectory = Split-Path $LogPath -Parent
        
        Write-Log "Rotation du fichier: $LogPath" "INFO"
        
        # Créer un nouveau nom pour le fichier archivé
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $rotatedName = "${logName}_${timestamp}${logExtension}"
        $rotatedPath = Join-Path $logDirectory $rotatedName
        
        # Renommer le fichier
        Rename-Item -Path $LogPath -NewName $rotatedName
        
        # Compresser si demandé
        if ($Compress) {
            $compressedPath = "$rotatedPath.gz"
            Write-Log "Compression du fichier..." "INFO"
            
            # Lire le contenu du fichier
            $content = Get-Content $rotatedPath -Raw
            
            # Compresser avec GZip
            $compressedStream = New-Object System.IO.Compression.GZipStream(
                (New-Object System.IO.FileStream($compressedPath, [System.IO.FileMode]::Create)),
                [System.IO.Compression.CompressionMode]::Compress
            )
            
            $writer = New-Object System.IO.StreamWriter($compressedStream)
            $writer.Write($content)
            $writer.Close()
            $compressedStream.Close()
            
            # Supprimer le fichier non compressé
            Remove-Item -Path $rotatedPath -Force
            
            Write-Log "Fichier compressé: $compressedPath" "SUCCESS"
            return $compressedPath
        }
        
        Write-Log "Fichier archivé: $rotatedPath" "SUCCESS"
        return $rotatedPath
    } catch {
        Write-Log "Erreur lors de la rotation du fichier $LogPath: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Fonction pour nettoyer les anciens fichiers log
function Clean-OldLogs {
    param([string]$LogDirectory, [int]$Days, [int]$MaxCount)
    
    if (-not (Test-Path $LogDirectory)) {
        Write-Log "Répertoire de logs non trouvé: $LogDirectory" "WARN"
        return
    }
    
    Write-Log "Nettoyage des anciens fichiers log..." "INFO"
    
    # Obtenir tous les fichiers log archivés
    $logFiles = Get-ChildItem -Path $LogDirectory -File | Where-Object { 
        $_.Name -match ".*_\d{8}-\d{6}\..*" 
    } | Sort-Object CreationTime -Descending
    
    $deletedCount = 0
    
    # Supprimer les fichiers trop anciens
    $cutoffDate = (Get-Date).AddDays(-$Days)
    $oldFiles = $logFiles | Where-Object { $_.CreationTime -lt $cutoffDate }
    
    foreach ($file in $oldFiles) {
        Remove-Item -Path $file.FullName -Force
        Write-Log "Fichier supprimé (trop ancien): $($file.Name)" "INFO"
        $deletedCount++
    }
    
    # Supprimer les fichiers en trop par rapport au nombre maximum
    $remainingFiles = $logFiles | Where-Object { $_.CreationTime -ge $cutoffDate }
    if ($remainingFiles.Count -gt $MaxCount) {
        $filesToDelete = $remainingFiles | Select-Object -Skip $MaxCount
        foreach ($file in $filesToDelete) {
            Remove-Item -Path $file.FullName -Force
            Write-Log "Fichier supprimé (limite atteinte): $($file.Name)" "INFO"
            $deletedCount++
        }
    }
    
    if ($deletedCount -gt 0) {
        Write-Log "Nettoyage terminé: $deletedCount fichiers supprimés" "SUCCESS"
    } else
        Write-Log "Aucun fichier ancien à supprimer" "INFO"
    }
}

# Fonction pour traiter un répertoire de logs
function Process-LogDirectory {
    param([string]$Directory)
    
    if (-not (Test-Path $Directory)) {
        Write-Log "Répertoire non trouvé: $Directory" "WARN"
        return
    }
    
    Write-Log "Traitement du répertoire: $Directory" "INFO"
    
    # Obtenir tous les fichiers log
    $logFiles = Get-ChildItem -Path $Directory -File | Where-Object { 
        $_.Name -notmatch ".*_\d{8}-\d{6}\..*"  # Exclure les fichiers déjà archivés
    }
    
    $rotatedCount = 0
    
    foreach ($file in $logFiles) {
        $fileSize = Get-FileSize -FilePath $file.FullName
        
        # Vérifier si le fichier dépasse la taille maximale
        if ($fileSize -gt $maxSizeBytes) {
            Write-Log "Fichier trop volumineux: $($file.Name) ($([math]::Round($fileSize/1MB, 2)) MB)" "WARN"
            
            # Effectuer la rotation
            $rotatedFile = Rotate-Log -LogPath $file.FullName
            if ($rotatedFile) {
                $rotatedCount++
            }
        } else {
            if ($Verbose) {
                Write-Log "Fichier OK: $($file.Name) ($([math]::Round($fileSize/MB, 2)) MB)" "INFO"
            }
        }
    }
    
    if ($rotatedCount -gt 0) {
        Write-Log "$rotatedCount fichiers ont été archivés" "SUCCESS"
    }
}

# Créer le répertoire de logs s'il n'existe pas
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    Write-Log "Répertoire de logs créé: $LogDir" "INFO"
}

# Traiter le répertoire de logs
Process-LogDirectory -Directory $LogDir

# Nettoyer les anciens fichiers log
Clean-OldLogs -LogDirectory $LogDir -Days $RetentionDays -MaxCount $RetentionCount

Write-Log "Rotation des logs terminée !" "SUCCESS"