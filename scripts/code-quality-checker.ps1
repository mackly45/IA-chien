# Script de vérification de la qualité du code

param(
    [Parameter(Mandatory=$false)]
    [string[]]$Paths = @("./dog_breed_identifier", "./scripts", "./tests"),
    
    [Parameter(Mandatory=$false)]
    [switch]$Fix = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFormat = "console"
)

Write-Host "Vérification de la qualité du code" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$reportsDir = "./reports"
$qualityTools = @("flake8", "black", "isort", "pylint")

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

# Fonction pour vérifier si un outil est installé
function Test-Tool {
    param([string]$Tool)
    
    try {
        $result = Get-Command $Tool -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Fonction pour exécuter une commande et récupérer la sortie
function Invoke-Tool {
    param([string]$Command, [string]$Description)
    
    Write-Log "Exécution: $Description" "INFO"
    
    try {
        if ($Verbose) {
            Invoke-Expression $Command
        } else {
            $output = Invoke-Expression $Command 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Erreurs trouvées: $Description" "WARN"
                if ($Verbose) {
                    Write-Host $output -ForegroundColor Yellow
                }
                return $false
            }
        }
        Write-Log "Succès: $Description" "SUCCESS"
        return $true
    } catch {
        Write-Log "Échec: $Description - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Créer le répertoire des rapports s'il n'existe pas
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    Write-Log "Répertoire des rapports créé: $reportsDir" "INFO"
}

# Vérifier les outils de qualité
Write-Log "Vérification des outils de qualité..." "INFO"
$missingTools = @()
$availableTools = @()

foreach ($tool in $qualityTools) {
    if (Test-Tool $tool) {
        Write-Log "Outil disponible: $tool" "SUCCESS"
        $availableTools += $tool
    } else {
        Write-Log "Outil manquant: $tool" "WARN"
        $missingTools += $tool
    }
}

if ($missingTools.Count -gt 0) {
    Write-Log "Certains outils de qualité sont manquants: $($missingTools -join ', ')" "WARN"
    Write-Log "Installez-les avec: pip install $($missingTools -join ' ')" "INFO"
}

if ($availableTools.Count -eq 0) {
    Write-Log "Aucun outil de qualité disponible, arrêt du script" "ERROR"
    exit 1
}

# Exécuter les vérifications de qualité
$issuesFound = 0
$checksPerformed = 0

foreach ($path in $Paths) {
    if (-not (Test-Path $path)) {
        Write-Log "Chemin non trouvé: $path" "WARN"
        continue
    }
    
    Write-Log "Vérification de la qualité du code dans: $path" "INFO"
    
    # Vérifier avec flake8
    if ($availableTools -contains "flake8") {
        $checksPerformed++
        $flake8Cmd = "flake8 $path"
        if (-not (Invoke-Tool $flake8Cmd "Vérification flake8")) {
            $issuesFound++
        }
    }
    
    # Vérifier avec pylint
    if ($availableTools -contains "pylint") {
        $checksPerformed++
        $pylintCmd = "pylint $path"
        if ($OutputFormat -eq "console") {
            $pylintCmd += " --output-format=text"
        } else {
            $pylintReport = Join-Path $reportsDir "pylint-report.txt"
            $pylintCmd += " --output-format=text > $pylintReport"
        }
        
        if (-not (Invoke-Tool $pylintCmd "Vérification pylint")) {
            $issuesFound++
        }
    }
    
    # Formater avec black (et corriger si demandé)
    if ($availableTools -contains "black") {
        $checksPerformed++
        $blackCmd = "black"
        if (-not $Fix) {
            $blackCmd += " --check"
        }
        $blackCmd += " $path"
        
        if (-not (Invoke-Tool $blackCmd "Formatage black")) {
            $issuesFound++
        }
    }
    
    # Trier les imports avec isort (et corriger si demandé)
    if ($availableTools -contains "isort") {
        $checksPerformed++
        $isortCmd = "isort"
        if (-not $Fix) {
            $isortCmd += " --check-only"
        }
        $isortCmd += " $path"
        
        if (-not (Invoke-Tool $isortCmd "Tri des imports isort")) {
            $issuesFound++
        }
    }
}

# Afficher le résumé
Write-Host "`nRésumé de la vérification de qualité:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Chemins vérifiés: $($Paths -join ', ')" -ForegroundColor White
Write-Host "Outils disponibles: $($availableTools -join ', ')" -ForegroundColor White
Write-Host "Vérifications effectuées: $checksPerformed" -ForegroundColor White
Write-Host "Problèmes trouvés: $issuesFound" -ForegroundColor White

if ($issuesFound -eq 0) {
    Write-Host "✅ Code de qualité vérifié avec succès !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Problèmes de qualité du code détectés ($issuesFound)" -ForegroundColor Red
    if (-not $Fix) {
        Write-Host "💡 Utilisez l'option -Fix pour corriger automatiquement certains problèmes" -ForegroundColor Yellow
    }
    exit 1
}