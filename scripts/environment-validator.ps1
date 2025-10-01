# Script de validation de l'environnement

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "development",
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckDocker = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckPython = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckDependencies = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckConfig = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

Write-Host "Validation de l'environnement" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$requiredPythonVersion = "3.8"
$requiredDockerVersion = "20.0"

# Fonction pour afficher les messages de debug
function Write-VerboseMessage {
    param([string]$Message)
    if ($Verbose) {
        Write-Host "  [DEBUG] $Message" -ForegroundColor Gray
    }
}

# Fonction pour vérifier une commande
function Test-Command {
    param([string]$Command)
    
    try {
        $result = Get-Command $Command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Fonction pour exécuter une commande et récupérer la sortie
function Invoke-CommandWithOutput {
    param([string]$Command)
    
    try {
        $output = Invoke-Expression $Command 2>$null
        return $output
    } catch {
        return $null
    }
}

# Initialiser les compteurs
$checksPassed = 0
$checksTotal = 0

# Vérifier l'environnement
Write-Host "Environnement cible: $Environment" -ForegroundColor Yellow

# Vérifier Python
if ($CheckPython) {
    $checksTotal++
    Write-Host "Vérification de Python..." -ForegroundColor Yellow
    Write-VerboseMessage "Recherche de l'exécutable Python"
    
    if (Test-Command "python") {
        $pythonVersion = Invoke-CommandWithOutput "python --version"
        Write-Host "✅ Python trouvé: $pythonVersion" -ForegroundColor Green
        $checksPassed++
    } elseif (Test-Command "python3") {
        $pythonVersion = Invoke-CommandWithOutput "python3 --version"
        Write-Host "✅ Python trouvé: $pythonVersion" -ForegroundColor Green
        $checksPassed++
    } else {
        Write-Host "❌ Python non trouvé" -ForegroundColor Red
    }
}

# Vérifier Docker
if ($CheckDocker) {
    $checksTotal++
    Write-Host "Vérification de Docker..." -ForegroundColor Yellow
    
    if (Test-Command "docker") {
        $dockerVersion = Invoke-CommandWithOutput "docker --version"
        Write-Host "✅ Docker trouvé: $dockerVersion" -ForegroundColor Green
        $checksPassed++
    } else {
        Write-Host "❌ Docker non trouvé" -ForegroundColor Red
    }
}

# Vérifier les dépendances
if ($CheckDependencies) {
    $checksTotal++
    Write-Host "Vérification des dépendances..." -ForegroundColor Yellow
    
    if (Test-Path "requirements.txt") {
        $requirements = Get-Content "requirements.txt" | Where-Object { $_ -notmatch "^#" -and $_ -notmatch "^\s*$" }
        $missingDeps = @()
        
        foreach ($req in $requirements) {
            # Extraire le nom du paquet (sans version)
            $packageName = $req -replace "([>=<~!]=?.*$)", ""
            Write-VerboseMessage "Vérification de la dépendance: $packageName"
            
            try {
                # Vérifier si le paquet est installé
                $importResult = python -c "import $packageName" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-VerboseMessage "✅ Dépendance trouvée: $packageName"
                } else {
                    $missingDeps += $req
                    Write-VerboseMessage "❌ Dépendance manquante: $packageName"
                }
            } catch {
                $missingDeps += $req
                Write-VerboseMessage "❌ Dépendance manquante: $packageName"
            }
        }
        
        if ($missingDeps.Count -eq 0) {
            Write-Host "✅ Toutes les dépendances sont installées ($($requirements.Count) paquets)" -ForegroundColor Green
            $checksPassed++
        } else {
            Write-Host "❌ $($missingDeps.Count) dépendances manquantes:" -ForegroundColor Red
            foreach ($dep in $missingDeps) {
                Write-Host "  - $dep" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "❌ Fichier requirements.txt non trouvé" -ForegroundColor Red
    }
}

# Vérifier la configuration
if ($CheckConfig) {
    $checksTotal++
    Write-Host "Vérification de la configuration..." -ForegroundColor Yellow
    
    # Vérifier les fichiers de configuration
    $configFiles = @(
        @{ Path = "./config/settings.py"; Required = $true },
        @{ Path = "./config/database.py"; Required = $false },
        @{ Path = "./.env"; Required = $false }
    )
    
    $missingConfigs = @()
    $foundConfigs = @()
    
    foreach ($config in $configFiles) {
        if (Test-Path $config.Path) {
            $foundConfigs += $config.Path
            Write-VerboseMessage "✅ Fichier de configuration trouvé: $($config.Path)"
        } elseif ($config.Required) {
            $missingConfigs += $config.Path
            Write-VerboseMessage "❌ Fichier de configuration requis manquant: $($config.Path)"
        } else {
            Write-VerboseMessage "ℹ️  Fichier de configuration optionnel non trouvé: $($config.Path)"
        }
    }
    
    if ($missingConfigs.Count -eq 0) {
        Write-Host "✅ Configuration vérifiée ($($foundConfigs.Count) fichiers trouvés)" -ForegroundColor Green
        $checksPassed++
    } else {
        Write-Host "❌ $($missingConfigs.Count) fichiers de configuration requis manquants:" -ForegroundColor Red
        foreach ($config in $missingConfigs) {
            Write-Host "  - $config" -ForegroundColor Red
        }
    }
}

# Vérifier les variables d'environnement
$checksTotal++
Write-Host "Vérification des variables d'environnement..." -ForegroundColor Yellow

$requiredEnvVars = @(
    "SECRET_KEY",
    "DEBUG"
)

$missingEnvVars = @()
$foundEnvVars = @()

foreach ($var in $requiredEnvVars) {
    if (Test-Path "env:$var") {
        $foundEnvVars += $var
        Write-VerboseMessage "✅ Variable d'environnement trouvée: $var"
    } else {
        # Vérifier dans le fichier .env
        if (Test-Path ".env") {
            $envContent = Get-Content ".env"
            if ($envContent -match "^$var=") {
                $foundEnvVars += $var
                Write-VerboseMessage "✅ Variable d'environnement trouvée dans .env: $var"
            } else {
                $missingEnvVars += $var
                Write-VerboseMessage "❌ Variable d'environnement manquante: $var"
            }
        } else {
            $missingEnvVars += $var
            Write-VerboseMessage "❌ Variable d'environnement manquante: $var"
        }
    }
}

if ($missingEnvVars.Count -eq 0) {
    Write-Host "✅ Variables d'environnement vérifiées ($($foundEnvVars.Count) variables trouvées)" -ForegroundColor Green
    $checksPassed++
} else {
    Write-Host "❌ $($missingEnvVars.Count) variables d'environnement manquantes:" -ForegroundColor Red
    foreach ($var in $missingEnvVars) {
        Write-Host "  - $var" -ForegroundColor Red
    }
}

# Afficher le résumé
Write-Host "`nRésumé de validation:" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "Environnement: $Environment" -ForegroundColor White
Write-Host "Vérifications réussies: $checksPassed/$checksTotal" -ForegroundColor White

if ($checksPassed -eq $checksTotal) {
    Write-Host "✅ Environnement validé avec succès" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Environnement non valide ($($checksTotal - $checksPassed) échecs)" -ForegroundColor Red
    exit 1
}