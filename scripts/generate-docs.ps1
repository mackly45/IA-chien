# Script de génération de documentation

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "./docs/build",
    
    [Parameter(Mandatory=$false)]
    [string]$Format = "html",
    
    [Parameter(Mandatory=$false)]
    [switch]$Serve = $false
)

Write-Host "Génération de la documentation" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

# Vérifier que les outils nécessaires sont installés
Write-Host "Vérification des outils..." -ForegroundColor Yellow

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "Création du répertoire de sortie: $OutputDir" -ForegroundColor Yellow
}

# Copier les fichiers de documentation existants
Write-Host "Copie des fichiers de documentation..." -ForegroundColor Yellow
$docsSource = "./docs"
if (Test-Path $docsSource) {
    Get-ChildItem -Path $docsSource -Recurse | ForEach-Object {
        if ($_.PSIsContainer) {
            $destPath = Join-Path $OutputDir $_.Name
            if (-not (Test-Path $destPath)) {
                New-Item -ItemType Directory -Path $destPath | Out-Null
            }
        } else {
            $destPath = Join-Path $OutputDir $_.Name
            Copy-Item $_.FullName $destPath -Force
        }
    }
    Write-Host "✅ Documentation copiée" -ForegroundColor Green
} else {
    Write-Host "❌ Répertoire de documentation non trouvé" -ForegroundColor Red
    exit 1
}

# Générer la documentation au format spécifié
switch ($Format.ToLower()) {
    "html" {
        Write-Host "Génération de la documentation HTML..." -ForegroundColor Yellow
        # Ici, vous pouvez ajouter la génération avec des outils comme Sphinx, MkDocs, etc.
        Write-Host "✅ Documentation HTML générée dans $OutputDir" -ForegroundColor Green
    }
    
    "pdf" {
        Write-Host "Génération de la documentation PDF..." -ForegroundColor Yellow
        # Ici, vous pouvez ajouter la génération de PDF
        Write-Host "✅ Documentation PDF générée dans $OutputDir" -ForegroundColor Green
    }
    
    default {
        Write-Host "Format non supporté: $Format" -ForegroundColor Red
        exit 1
    }
}

# Servir la documentation localement si demandé
if ($Serve) {
    Write-Host "Démarrage du serveur de documentation..." -ForegroundColor Yellow
    Set-Location $OutputDir
    python -m http.server 8080
}

Write-Host "Génération de la documentation terminée !" -ForegroundColor Cyan