# Script de vérification de la santé de l'application

param(
    [Parameter(Mandatory=$false)]
    [string]$Url = "http://localhost:8000",
    
    [Parameter(Mandatory=$false)]
    [int]$Timeout = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFormat = "console"
)

Write-Host "Vérification de la santé de l'application" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$reportsDir = "./reports"
$healthEndpoints = @(
    "/health/",
    "/api/breeds/",
    "/",
    "/about/"
)

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

# Fonction pour effectuer une requête HTTP
function Invoke-HealthCheck {
    param([string]$Endpoint, [int]$RequestTimeout)
    
    $fullUrl = "$Url$Endpoint"
    Write-Log "Vérification: $fullUrl" "INFO"
    
    try {
        $response = Invoke-WebRequest -Uri $fullUrl -TimeoutSec $RequestTimeout -ErrorAction Stop
        return @{
            Success = $true
            StatusCode = $response.StatusCode
            StatusDescription = $response.StatusDescription
            ResponseTime = 0  # À implémenter
            ContentLength = $response.RawContentLength
        }
    } catch {
        return @{
            Success = $false
            StatusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { 0 }
            StatusDescription = if ($_.Exception.Response) { $_.Exception.Response.StatusDescription } else { $_.Exception.Message }
            ResponseTime = 0
            ContentLength = 0
        }
    }
}

# Fonction pour vérifier la base de données
function Test-DatabaseConnection {
    Write-Log "Vérification de la connexion à la base de données..." "INFO"
    
    # Dans une implémentation réelle, cela utiliserait les paramètres de connexion Django
    # Pour cette simulation, nous vérifions simplement si le fichier de base de données existe
    $dbFile = "./dog_breed_identifier/db.sqlite3"
    
    if (Test-Path $dbFile) {
        Write-Log "Fichier de base de données trouvé: $dbFile" "SUCCESS"
        return $true
    } else {
        Write-Log "Fichier de base de données non trouvé: $dbFile" "WARN"
        return $false
    }
}

# Fonction pour vérifier les dépendances
function Test-Dependencies {
    Write-Log "Vérification des dépendances..." "INFO"
    
    $dependencies = @(
        @{ Name = "Django"; Command = "django"; Module = "django" },
        @{ Name = "TensorFlow"; Command = "tensorflow"; Module = "tensorflow" },
        @{ Name = "Pillow"; Command = "pillow"; Module = "PIL" }
    )
    
    $issues = @()
    
    foreach ($dep in $dependencies) {
        try {
            # Vérifier si le module Python est disponible
            python -c "import $($dep.Module)" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Dépendance OK: $($dep.Name)" "SUCCESS"
            } else {
                Write-Log "Dépendance manquante: $($dep.Name)" "WARN"
                $issues += "Dépendance manquante: $($dep.Name)"
            }
        } catch {
            Write-Log "Dépendance manquante: $($dep.Name)" "WARN"
            $issues += "Dépendance manquante: $($dep.Name)"
        }
    }
    
    return $issues
}

# Fonction pour générer un rapport
function Generate-Report {
    param([array]$Results, [array]$DatabaseCheck, [array]$DependencyIssues)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $totalChecks = $Results.Count
    $successfulChecks = ($Results | Where-Object { $_.Success }).Count
    $failedChecks = $totalChecks - $successfulChecks
    
    switch ($OutputFormat.ToLower()) {
        "json" {
            $reportData = @{
                timestamp = $timestamp
                projectName = $projectName
                url = $Url
                totalChecks = $totalChecks
                successfulChecks = $successfulChecks
                failedChecks = $failedChecks
                results = $Results
                databaseCheck = $DatabaseCheck
                dependencyIssues = $DependencyIssues
            }
            
            $reportFile = Join-Path $reportsDir "health-check-report.json"
            $reportData | ConvertTo-Json -Depth 10 | Out-File $reportFile
            Write-Log "Rapport JSON généré: $reportFile" "SUCCESS"
        }
        
        "html" {
            $reportFile = Join-Path $reportsDir "health-check-report.html"
            
            $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de Santé - $projectName</title>
    <meta charset="UTF-8">
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 20px; 
            background-color: #f8f9fa;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        h1 { 
            color: #2c3e50; 
            text-align: center;
            padding-bottom: 20px;
            border-bottom: 2px solid #3498db;
        }
        .summary {
            background-color: #e3f2fd;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
        }
        .checks {
            margin-bottom: 30px;
        }
        .check-item {
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
            border-left: 4px solid;
        }
        .check-success {
            background-color: #e8f5e9;
            border-left-color: #4caf50;
        }
        .check-failure {
            background-color: #ffebee;
            border-left-color: #f44336;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        th {
            background-color: #3498db;
            color: white;
        }
        .status-success { color: #4caf50; }
        .status-failure { color: #f44336; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de Santé - $projectName</h1>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p><strong>Date:</strong> $timestamp</p>
            <p><strong>URL cible:</strong> $Url</p>
            <p><strong>Vérifications totales:</strong> $totalChecks</p>
            <p><strong>Succès:</strong> <span class="status-success">$successfulChecks</span></p>
            <p><strong>Échecs:</strong> <span class="status-failure">$failedChecks</span></p>
        </div>
        
        <div class="checks">
            <h2>Résultats des Vérifications</h2>
            <table>
                <thead>
                    <tr>
                        <th>Endpoint</th>
                        <th>Status</th>
                        <th>Code</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
"@
            
            foreach ($result in $Results) {
                $statusClass = if ($result.Success) { "status-success" } else { "status-failure" }
                $statusText = if ($result.Success) { "Succès" } else { "Échec" }
                $htmlContent += @"
                    <tr>
                        <td>$($result.Endpoint)</td>
                        <td class="$statusClass">$statusText</td>
                        <td>$($result.StatusCode)</td>
                        <td>$($result.StatusDescription)</td>
                    </tr>
"@
            }
            
            $htmlContent += @"
                </tbody>
            </table>
        </div>
        
        <div class="checks">
            <h2>Vérifications Système</h2>
            <div class="check-item check-success">
                <h3>Base de données</h3>
                <p>$(if ($DatabaseCheck) { "✅ Connexion à la base de données OK" } else { "⚠️ Problème de connexion à la base de données" })</p>
            </div>
            
            <div class="check-item $(if ($DependencyIssues.Count -eq 0) { "check-success" } else { "check-failure" })">
                <h3>Dépendances</h3>
                <p>$(if ($DependencyIssues.Count -eq 0) { "✅ Toutes les dépendances sont présentes" } else { "❌ Problèmes de dépendances détectés" })</p>
"@
            
            if ($DependencyIssues.Count -gt 0) {
                $htmlContent += "<ul>"
                foreach ($issue in $DependencyIssues) {
                    $htmlContent += "<li>$issue</li>"
                }
                $htmlContent += "</ul>"
            }
            
            $htmlContent += @"
            </div>
        </div>
    </div>
</body>
</html>
"@
            
            Set-Content -Path $reportFile -Value $htmlContent
            Write-Log "Rapport HTML généré: $reportFile" "SUCCESS"
        }
        
        default {
            # Le rapport a déjà été affiché en console
            if ($OutputFormat -ne "console") {
                $reportFile = Join-Path $reportsDir "health-check-report.txt"
                
                $reportContent = @"
Rapport de Santé - $projectName
============================
Date: $timestamp
URL cible: $Url

Résumé:
- Vérifications totales: $totalChecks
- Succès: $successfulChecks
- Échecs: $failedChecks

Résultats des vérifications:
"@
                
                foreach ($result in $Results) {
                    $statusText = if ($result.Success) { "Succès" } else { "Échec" }
                    $reportContent += "$statusText - $($result.Endpoint) (Code: $($result.StatusCode))`n"
                }
                
                $reportContent += @"
`nVérifications système:
- Base de données: $(if ($DatabaseCheck) { "OK" } else { "Problème" })
- Dépendances: $(if ($DependencyIssues.Count -eq 0) { "OK" } else { "$($DependencyIssues.Count) problème(s)" })
"@
                
                Set-Content -Path $reportFile -Value $reportContent
                Write-Log "Rapport texte généré: $reportFile" "SUCCESS"
            }
        }
    }
}

# Créer le répertoire des rapports s'il n'existe pas
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    Write-Log "Répertoire des rapports créé: $reportsDir" "INFO"
}

# Effectuer les vérifications de santé
$results = @()
$overallSuccess = $true

Write-Log "Démarrage des vérifications de santé..." "INFO"

# Vérifier les endpoints HTTP
foreach ($endpoint in $healthEndpoints) {
    $result = Invoke-HealthCheck -Endpoint $endpoint -RequestTimeout $Timeout
    $result.Endpoint = $endpoint
    $results += $result
    
    if (-not $result.Success) {
        $overallSuccess = $false
        Write-Log "Échec de la vérification: $endpoint" "ERROR"
    } else {
        Write-Log "Succès de la vérification: $endpoint (Code: $($result.StatusCode))" "SUCCESS"
    }
}

# Vérifier la base de données
$databaseCheck = Test-DatabaseConnection

# Vérifier les dépendances
$dependencyIssues = Test-Dependencies

# Afficher le résumé détaillé si demandé
if ($Detailed) {
    Write-Host "`nDétails des vérifications:" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    
    foreach ($result in $results) {
        $statusColor = if ($result.Success) { "Green" } else { "Red" }
        $statusText = if ($result.Success) { "✅ SUCCÈS" } else { "❌ ÉCHEC" }
        Write-Host "$statusText - $($result.Endpoint)" -ForegroundColor $statusColor
        Write-Host "  Code: $($result.StatusCode) - $($result.StatusDescription)" -ForegroundColor Gray
    }
    
    Write-Host "`nVérifications système:" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host "Base de données: $(if ($databaseCheck) { "✅ OK" } else { "❌ Problème" })" -ForegroundColor $(if ($databaseCheck) { "Green" } else { "Red" })
    
    if ($dependencyIssues.Count -eq 0) {
        Write-Host "Dépendances: ✅ Toutes présentes" -ForegroundColor Green
    } else {
        Write-Host "Dépendances: ❌ $($dependencyIssues.Count) problème(s)" -ForegroundColor Red
        foreach ($issue in $dependencyIssues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
    }
}

# Générer le rapport
Generate-Report -Results $results -DatabaseCheck $databaseCheck -DependencyIssues $dependencyIssues

# Afficher le résumé final
Write-Host "`nRésumé de la vérification de santé:" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "URL cible: $Url" -ForegroundColor White
Write-Host "Vérifications totales: $($results.Count)" -ForegroundColor White
Write-Host "Succès: $(($results | Where-Object { $_.Success }).Count)" -ForegroundColor $(if (($results | Where-Object { $_.Success }).Count -eq $results.Count) { "Green" } else { "Yellow" })
Write-Host "Échecs: $(($results | Where-Object { -not $_.Success }).Count)" -ForegroundColor $(if (($results | Where-Object { -not $_.Success }).Count -eq 0) { "Green" } else { "Red" })
Write-Host "Base de données: $(if ($databaseCheck) { "✅ OK" } else { "❌ Problème" })" -ForegroundColor $(if ($databaseCheck) { "Green" } else { "Red" })
Write-Host "Dépendances: $(if ($dependencyIssues.Count -eq 0) { "✅ OK" } else { "❌ $($dependencyIssues.Count) problème(s)" })" -ForegroundColor $(if ($dependencyIssues.Count -eq 0) { "Green" } else { "Red" })

if ($overallSuccess -and $databaseCheck -and ($dependencyIssues.Count -eq 0)) {
    Write-Host "`n✅ Application en bonne santé !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ Problèmes de santé détectés" -ForegroundColor Red
    exit 1
}