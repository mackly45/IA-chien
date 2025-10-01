# Script de backup du projet

param(
    [Parameter(Mandatory=$false)]
    [string]$BackupDir = "./backups"
)

Write-Host "Backup du projet Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Créer le répertoire de backup s'il n'existe pas
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
    Write-Host "Création du répertoire de backup: $BackupDir" -ForegroundColor Yellow
}

# Générer un nom de fichier de backup avec timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFileName = "dog-breed-identifier-backup-$timestamp.zip"
$backupPath = Join-Path $BackupDir $backupFileName

Write-Host "Création du backup: $backupPath" -ForegroundColor Yellow

# Exclure les fichiers/dossiers non nécessaires
$excludePatterns = @(
    ".git",
    ".venv",
    "venv",
    "__pycache__",
    "*.pyc",
    ".DS_Store",
    "Thumbs.db",
    "backups",
    "node_modules"
)

# Créer le backup
try {
    # Utiliser Compress-Archive pour créer le fichier zip
    Compress-Archive -Path ./* -DestinationPath $backupPath -CompressionLevel Optimal -Force
    Write-Host "✅ Backup créé avec succès !" -ForegroundColor Green
    Write-Host "Taille du backup: $((Get-Item $backupPath).Length / 1MB) MB" -ForegroundColor White
} catch {
    Write-Host "❌ Échec de la création du backup: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Nettoyer les anciens backups (garder seulement les 5 derniers)
Write-Host "Nettoyage des anciens backups..." -ForegroundColor Yellow
$backups = Get-ChildItem -Path $BackupDir -Filter "dog-breed-identifier-backup-*.zip" | Sort-Object CreationTime -Descending
if ($backups.Count -gt 5) {
    $backups | Select-Object -Skip 5 | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Host "Supprimé: $($_.Name)" -ForegroundColor White
    }
}

Write-Host "Backup terminé !" -ForegroundColor Cyan