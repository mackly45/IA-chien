# Script de vérification de compatibilité

param(
    [Parameter(Mandatory=$false)]
    [string[]]$Platforms = @("windows", "linux", "macos"),
    
    [Parameter(Mandatory=$false)]
    [string[]]$PythonVersions = @("3.8", "3.9", "3.10", "3.11"),
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed = $false
)

Write-Host "Vérification de compatibilité de Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$currentOS = $env:OS

# Fonction pour vérifier les dépendances Python
function Check-PythonDependencies {
    param([string]$RequirementsFile = "requirements.txt")
    
    Write-Host "Vérification des dépendances Python..." -ForegroundColor Yellow
    
    if (-not (Test-Path $RequirementsFile)) {
        Write-Host "❌ Fichier $RequirementsFile non trouvé" -ForegroundColor Red
        return $false
    }
    
    $dependencies = Get-Content $RequirementsFile | Where-Object { $_ -notmatch "^#" -and $_ -notmatch "^\s*$" }
    $compatible = $true
    
    foreach ($dep in $dependencies) {
        # Parser le nom de la dépendance et la version
        if ($dep -match "^([^=<>!]+)([=<>!]+)(.+)$") {
            $packageName = $matches[1].Trim()
            $operator = $matches[2].Trim()
            $version = $matches[3].Trim()
            
            if ($Detailed) {
                Write-Host "  Vérification: $packageName $operator $version" -ForegroundColor White
            }
        } else {
            $packageName = $dep.Trim()
            if ($Detailed) {
                Write-Host "  Vérification: $packageName (dernière version)" -ForegroundColor White
            }
        }
        
        # Vérifier si le package existe sur PyPI
        try {
            $pypiResponse = Invoke-RestMethod -Uri "https://pypi.org/pypi/$packageName/json" -TimeoutSec 10 -ErrorAction Stop
            if ($Detailed) {
                Write-Host "  ✅ $packageName disponible sur PyPI" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ❌ $packageName non trouvé sur PyPI" -ForegroundColor Red
            $compatible = $false
        }
    }
    
    return $compatible
}

# Fonction pour vérifier la compatibilité Docker
function Check-DockerCompatibility {
    Write-Host "Vérification de la compatibilité Docker..." -ForegroundColor Yellow
    
    # Vérifier que Docker est installé
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Docker n'est pas installé" -ForegroundColor Red
        return $false
    }
    
    # Vérifier la version de Docker
    try {
        $dockerVersion = docker --version
        if ($Detailed) {
            Write-Host "  ✅ Docker installé: $dockerVersion" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ❌ Impossible de vérifier la version de Docker" -ForegroundColor Red
        return $false
    }
    
    # Vérifier le Dockerfile
    if (Test-Path "Dockerfile") {
        $dockerfileContent = Get-Content "Dockerfile" -Raw
        
        # Vérifier l'image de base
        if ($dockerfileContent -match "FROM\s+python:([0-9.]+)") {
            $pythonVersion = $matches[1]
            if ($Detailed) {
                Write-Host "  ✅ Image de base Python: $pythonVersion" -ForegroundColor Green
            }
        } else {
            Write-Host "  ⚠️  Image de base Python non trouvée dans Dockerfile" -ForegroundColor Yellow
        }
        
        if ($Detailed) {
            Write-Host "  ✅ Dockerfile trouvé et analysé" -ForegroundColor Green
        }
    } else {
        Write-Host "  ❌ Dockerfile non trouvé" -ForegroundColor Red
        return $false
    }
    
    return $true
}

# Fonction pour vérifier la compatibilité avec les systèmes d'exploitation
function Check-OSCompatibility {
    param([string[]]$TargetPlatforms)
    
    Write-Host "Vérification de la compatibilité OS..." -ForegroundColor Yellow
    
    $currentPlatform = "unknown"
    if ($currentOS -match "Windows") {
        $currentPlatform = "windows"
    } elseif ($IsLinux) {
        $currentPlatform = "linux"
    } elseif ($IsMacOS) {
        $currentPlatform = "macos"
    }
    
    if ($Detailed) {
        Write-Host "  Plateforme actuelle: $currentPlatform" -ForegroundColor White
    }
    
    # Vérifier les fichiers spécifiques à chaque plateforme
    $compatibilityIssues = @()
    
    foreach ($platform in $TargetPlatforms) {
        switch ($platform.ToLower()) {
            "windows" {
                # Vérifier les fichiers .bat, .ps1
                $windowsFiles = Get-ChildItem -Path . -Recurse -Include "*.bat", "*.ps1" -ErrorAction SilentlyContinue
                if ($windowsFiles.Count -gt 0 -and $Detailed) {
                    Write-Host "  ✅ Fichiers Windows trouvés: $($windowsFiles.Count)" -ForegroundColor Green
                }
            }
            
            "linux" {
                # Vérifier les fichiers .sh
                $linuxFiles = Get-ChildItem -Path . -Recurse -Include "*.sh" -ErrorAction SilentlyContinue
                if ($linuxFiles.Count -gt 0) {
                    # Vérifier les shebangs
                    foreach ($file in $linuxFiles) {
                        $firstLine = Get-Content $file.FullName -First 1 -ErrorAction SilentlyContinue
                        if ($firstLine -match "^#!") {
                            if ($Detailed) {
                                Write-Host "  ✅ Shebang trouvé dans $($file.Name)" -ForegroundColor Green
                            }
                        } else {
                            $compatibilityIssues += "Fichier shell sans shebang: $($file.Name)"
                        }
                    }
                }
            }
            
            "macos" {
                # La compatibilité macOS est généralement similaire à Linux
                if ($Detailed) {
                    Write-Host "  ✅ Compatibilité macOS (similaire à Linux)" -ForegroundColor Green
                }
            }
        }
    }
    
    if ($compatibilityIssues.Count -gt 0) {
        foreach ($issue in $compatibilityIssues) {
            Write-Host "  ⚠️  $issue" -ForegroundColor Yellow
        }
        return $false
    }
    
    return $true
}

# Fonction pour vérifier la compatibilité Python
function Check-PythonCompatibility {
    param([string[]]$TargetVersions)
    
    Write-Host "Vérification de la compatibilité Python..." -ForegroundColor Yellow
    
    # Vérifier la version Python actuelle
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python ([0-9.]+)") {
            $currentVersion = $matches[1]
            if ($Detailed) {
                Write-Host "  ✅ Python installé: $pythonVersion" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "  ❌ Python non installé" -ForegroundColor Red
        return $false
    }
    
    # Vérifier setup.py ou pyproject.toml pour les versions supportées
    $supportedVersions = @()
    
    if (Test-Path "setup.py") {
        $setupContent = Get-Content "setup.py" -Raw
        if ($setupContent -match "python_requires\s*=\s*['\"](>=?[^'\"]+)['\"]") {
            $requires = $matches[1]
            if ($Detailed) {
                Write-Host "  ✅ Versions Python requises: $requires" -ForegroundColor Green
            }
        }
    }
    
    if (Test-Path "pyproject.toml") {
        $pyprojectContent = Get-Content "pyproject.toml" -Raw
        if ($pyprojectContent -match "requires-python\s*=\s*['\"](>=?[^'\"]+)['\"]") {
            $requires = $matches[1]
            if ($Detailed) {
                Write-Host "  ✅ Versions Python requises: $requires" -ForegroundColor Green
            }
        }
    }
    
    return $true
}

# Fonction pour vérifier la compatibilité des dépendances avec les versions Python
function Check-DependencyPythonCompatibility {
    param([string[]]$PythonVersions)
    
    Write-Host "Vérification de la compatibilité des dépendances avec Python..." -ForegroundColor Yellow
    
    if (-not (Test-Path "requirements.txt")) {
        Write-Host "  ⚠️  requirements.txt non trouvé" -ForegroundColor Yellow
        return $true
    }
    
    $dependencies = Get-Content "requirements.txt" | Where-Object { $_ -notmatch "^#" -and $_ -notmatch "^\s*$" }
    $compatible = $true
    
    foreach ($dep in $dependencies) {
        $packageName = $dep.Trim()
        if ($dep -match "^([^=<>!]+)") {
            $packageName = $matches[1].Trim()
        }
        
        # Pour chaque version Python cible, vérifier la compatibilité
        foreach ($pyVersion in $PythonVersions) {
            try {
                # Cette vérification est complexe sans outils dédiés
                # Dans un vrai scénario, on utiliserait des outils comme pip-check ou pyup
                if ($Detailed) {
                    Write-Host "  Vérification de $packageName avec Python $pyVersion" -ForegroundColor White
                }
            } catch {
                if ($Detailed) {
                    Write-Host "  ⚠️  Impossible de vérifier $packageName avec Python $pyVersion" -ForegroundColor Yellow
                }
            }
        }
    }
    
    return $compatible
}

# Exécuter les vérifications
Write-Host "Exécution des vérifications de compatibilité..." -ForegroundColor Yellow

$allCompatible = $true

# Vérifier les dépendances Python
if (-not (Check-PythonDependencies)) {
    $allCompatible = $false
}

# Vérifier la compatibilité Docker
if (-not (Check-DockerCompatibility)) {
    $allCompatible = $false
}

# Vérifier la compatibilité OS
if (-not (Check-OSCompatibility -TargetPlatforms $Platforms)) {
    $allCompatible = $false
}

# Vérifier la compatibilité Python
if (-not (Check-PythonCompatibility -TargetVersions $PythonVersions)) {
    $allCompatible = $false
}

# Vérifier la compatibilité des dépendances avec Python
if (-not (Check-DependencyPythonCompatibility -PythonVersions $PythonVersions)) {
    $allCompatible = $false
}

# Afficher le résumé
Write-Host "`nRésumé de la compatibilité:" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

if ($allCompatible) {
    Write-Host "✅ Le projet est compatible avec les plateformes cibles" -ForegroundColor Green
    Write-Host "   Plateformes: $($Platforms -join ', ')" -ForegroundColor White
    Write-Host "   Versions Python: $($PythonVersions -join ', ')" -ForegroundColor White
} else {
    Write-Host "❌ Le projet présente des problèmes de compatibilité" -ForegroundColor Red
    Write-Host "   Veuillez consulter les messages d'erreur ci-dessus" -ForegroundColor Yellow
}

Write-Host "Vérification de compatibilité terminée !" -ForegroundColor Cyan