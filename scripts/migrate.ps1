# Script de migration de base de données

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowSql = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Fake = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$App = ""
)

Write-Host "Migration de la base de données" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

# Vérifier que Django est installé
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Python n'est pas installé" -ForegroundColor Red
    exit 1
}

# Construire la commande de migration
$cmd = "python manage.py migrate"

if ($ShowSql) {
    $cmd += " --plan"
}

if ($Fake) {
    $cmd += " --fake"
}

if ($App) {
    $cmd += " $App"
}

# Exécuter la migration
Write-Host "Exécution: $cmd" -ForegroundColor Yellow
Set-Location -Path "dog_breed_identifier"

try {
    Invoke-Expression $cmd
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Migration réussie !" -ForegroundColor Green
    } else {
        Write-Host "❌ Migration échouée" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Erreur lors de la migration: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Set-Location -Path ".."
Write-Host "Migration terminée !" -ForegroundColor Cyan