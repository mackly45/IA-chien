# Script de mise à jour des dépendances

param(
    [Parameter(Mandatory=$false)]
    [switch]$Dev = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Lock = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Upgrade = $false
)

Write-Host "Mise à jour des dépendances" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

# Vérifier que pip est installé
if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
    Write-Host "❌ pip n'est pas installé" -ForegroundColor Red
    exit 1
}

# Mise à jour de pip
Write-Host "Mise à jour de pip..." -ForegroundColor Yellow
pip install --upgrade pip

# Mise à jour des dépendances principales
Write-Host "Mise à jour des dépendances principales..." -ForegroundColor Yellow
if ($Upgrade) {
    pip install --upgrade -r requirements.txt
} else {
    pip install -r requirements.txt
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Échec de la mise à jour des dépendances principales" -ForegroundColor Red
    exit 1
}

# Mise à jour des dépendances de développement
if ($Dev) {
    Write-Host "Mise à jour des dépendances de développement..." -ForegroundColor Yellow
    if ($Upgrade) {
        pip install --upgrade -r dev-requirements.txt
    } else {
        pip install -r dev-requirements.txt
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Échec de la mise à jour des dépendances de développement" -ForegroundColor Red
        exit 1
    }
}

# Génération du fichier de verrouillage
if ($Lock) {
    Write-Host "Génération du fichier de verrouillage..." -ForegroundColor Yellow
    pip freeze > requirements-lock.txt
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Fichier de verrouillage généré: requirements-lock.txt" -ForegroundColor Green
    } else
    {
        Write-Host "❌ Échec de la génération du fichier de verrouillage" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Mise à jour des dépendances terminée !" -ForegroundColor Cyan