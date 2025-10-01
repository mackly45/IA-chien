# Script de validation de configuration

param(
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

Write-Host "Validation de la configuration" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

# Variables pour le suivi des erreurs
$errors = 0
$warnings = 0

# Fonction pour afficher les messages
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    switch ($Level) {
        "ERROR" {
            Write-Host "❌ $Message" -ForegroundColor Red
            $script:errors++
        }
        "WARNING" {
            Write-Host "⚠️  $Message" -ForegroundColor Yellow
            $script:warnings++
        }
        "SUCCESS" {
            Write-Host "✅ $Message" -ForegroundColor Green
        }
        default {
            if ($Verbose) {
                Write-Host "ℹ️  $Message" -ForegroundColor White
            }
        }
    }
}

# Vérifier la structure du projet
Write-Host "Vérification de la structure du projet..." -ForegroundColor Yellow

$requiredFiles = @(
    "requirements.txt",
    "Dockerfile",
    "docker-compose.yml",
    "README.md",
    ".gitignore",
    ".env"
)

$requiredDirs = @(
    "dog_breed_identifier",
    "docs",
    "scripts",
    "tests"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Log "Fichier trouvé: $file" "SUCCESS"
    } else {
        Write-Log "Fichier manquant: $file" "ERROR"
    }
}

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Log "Répertoire trouvé: $dir" "SUCCESS"
    } else {
        Write-Log "Répertoire manquant: $dir" "ERROR"
    }
}

# Vérifier les fichiers de configuration Docker
Write-Host "Vérification des fichiers Docker..." -ForegroundColor Yellow

$dockerFiles = @(
    "Dockerfile",
    "docker-compose.yml",
    ".dockerignore"
)

foreach ($file in $dockerFiles) {
    if (Test-Path $file) {
        # Vérifier que le fichier n'est pas vide
        $content = Get-Content $file -Raw
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Log "Fichier Docker vide: $file" "ERROR"
        } else {
            Write-Log "Fichier Docker valide: $file" "SUCCESS"
        }
    } else {
        Write-Log "Fichier Docker manquant: $file" "ERROR"
    }
}

# Vérifier les fichiers de documentation
Write-Host "Vérification des fichiers de documentation..." -ForegroundColor Yellow

$docFiles = @(
    "docs/architecture.md",
    "docs/development.md",
    "docs/deployment.md"
)

foreach ($file in $docFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Log "Fichier de documentation vide: $file" "WARNING"
        } else {
            Write-Log "Fichier de documentation valide: $file" "SUCCESS"
        }
    } else {
        Write-Log "Fichier de documentation manquant: $file" "WARNING"
    }
}

# Vérifier les scripts
Write-Host "Vérification des scripts..." -ForegroundColor Yellow

$scriptFiles = Get-ChildItem -Path "scripts" -Filter "*.ps1" -Recurse
foreach ($file in $scriptFiles) {
    $content = Get-Content $file.FullName -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        Write-Log "Script vide: $($file.Name)" "WARNING"
    } else {
        Write-Log "Script valide: $($file.Name)" "SUCCESS"
    }
}

# Vérifier les dépendances Python
Write-Host "Vérification des dépendances Python..." -ForegroundColor Yellow

if (Test-Path "requirements.txt") {
    $requirements = Get-Content "requirements.txt" | Where-Object { $_ -notmatch "^#" -and $_ -notmatch "^\s*$" }
    if ($requirements.Count -gt 0) {
        Write-Log "Dépendances Python trouvées: $($requirements.Count)" "SUCCESS"
    } else {
        Write-Log "Aucune dépendance Python trouvée" "WARNING"
    }
} else {
    Write-Log "Fichier requirements.txt manquant" "ERROR"
}

# Vérifier les variables d'environnement
Write-Host "Vérification des variables d'environnement..." -ForegroundColor Yellow

$envVars = @(
    "DOCKER_USERNAME",
    "DOCKER_PASSWORD",
    "RENDER_DEPLOY_HOOK"
)

foreach ($var in $envVars) {
    if (Test-Path "env:$var") {
        Write-Log "Variable d'environnement définie: $var" "SUCCESS"
    } else {
        Write-Log "Variable d'environnement non définie: $var" "WARNING"
    }
}

# Afficher le résumé
Write-Host "`nRésumé de la validation:" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host "Erreurs: $errors" -ForegroundColor Red
Write-Host "Avertissements: $warnings" -ForegroundColor Yellow

if ($errors -eq 0) {
    Write-Host "✅ Configuration valide !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Configuration invalide ($errors erreurs)" -ForegroundColor Red
    exit 1
}