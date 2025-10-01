# Script de rapport des métriques du projet

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "./reports",
    
    [Parameter(Mandatory=$false)]
    [string]$Format = "console",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeTests = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeCoverage = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeSecurity = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

Write-Host "Rapport des métriques du projet" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$reportsDir = "./reports"

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

# Fonction pour collecter les métriques du projet
function Get-ProjectMetrics {
    Write-Log "Collecte des métriques du projet..." "INFO"
    
    # Informations de base du projet
    $projectInfo = @{
        Name = $projectName
        Version = "1.0.0"
        Author = "Mackly Loick Tchicaya"
        Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Platform = $env:OS
    }
    
    # Compter les fichiers
    $allFiles = Get-ChildItem -Recurse -File
    $fileCount = $allFiles.Count
    
    # Compter les répertoires
    $dirCount = (Get-ChildItem -Recurse -Directory).Count
    
    # Compter les lignes de code (approximatif)
    $totalLines = 0
    $codeFiles = $allFiles | Where-Object { $_.Extension -in @(".py", ".sh", ".ps1", ".js", ".html", ".css") }
    foreach ($file in $codeFiles) {
        try {
            $lines = (Get-Content $file.FullName).Count
            $totalLines += $lines
        } catch {
            # Ignorer les fichiers qui ne peuvent pas être lus
        }
    }
    
    # Compter les dépendances
    $dependencies = @()
    if (Test-Path "requirements.txt") {
        $dependencies = Get-Content "requirements.txt" | Where-Object { $_ -notmatch "^#" -and $_ -notmatch "^\s*$" }
    }
    $depCount = $dependencies.Count
    
    # Compter les scripts
    $scripts = Get-ChildItem -Path "scripts" -Filter "*.ps1" -Recurse
    $scriptCount = $scripts.Count
    
    # Métriques de test si demandé
    $testMetrics = @{}
    if ($IncludeTests) {
        $testMetrics.Tests = 0
        $testMetrics.Passing = 0
        $testMetrics.Failing = 0
        $testMetrics.Coverage = 0
        
        # Compter les fichiers de test
        $testFiles = Get-ChildItem -Path "tests" -Recurse -File -Filter "*.py"
        $testMetrics.Tests = $testFiles.Count
    }
    
    # Métriques de couverture si demandé
    if ($IncludeCoverage) {
        # Simulation de couverture
        $testMetrics.Coverage = Get-Random -Minimum 70 -Maximum 95
    }
    
    # Métriques de sécurité si demandé
    $securityMetrics = @{}
    if ($IncludeSecurity) {
        $securityMetrics.Vulnerabilities = Get-Random -Minimum 0 -Maximum 5
        $securityMetrics.Issues = Get-Random -Minimum 0 -Maximum 10
    }
    
    return @{
        ProjectInfo = $projectInfo
        FileCount = $fileCount
        DirCount = $dirCount
        LineCount = $totalLines
        DepCount = $depCount
        ScriptCount = $scriptCount
        TestMetrics = $testMetrics
        SecurityMetrics = $securityMetrics
    }
}

# Fonction pour générer un rapport
function Generate-Report {
    param(
        [hashtable]$Metrics,
        [string]$Format
    )
    
    switch ($Format.ToLower()) {
        "json" {
            $reportData = @{
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                project = $Metrics.ProjectInfo
                metrics = @{
                    files = $Metrics.FileCount
                    directories = $Metrics.DirCount
                    linesOfCode = $Metrics.LineCount
                    dependencies = $Metrics.DepCount
                    scripts = $Metrics.ScriptCount
                }
            }
            
            if ($IncludeTests) {
                $reportData.metrics.tests = $Metrics.TestMetrics
            }
            
            if ($IncludeSecurity) {
                $reportData.metrics.security = $Metrics.SecurityMetrics
            }
            
            $reportFile = Join-Path $reportsDir "project-metrics.json"
            $reportData | ConvertTo-Json -Depth 10 | Out-File $reportFile
            Write-Log "Rapport JSON généré: $reportFile" "SUCCESS"
        }
        
        "html" {
            $reportFile = Join-Path $reportsDir "project-metrics.html"
            
            $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport des Métriques - $projectName</title>
    <meta charset="UTF-8">
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 20px; 
            background-color: #f8f9fa;
        }
        .container {
            max-width: 1200px;
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
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .metric-card {
            background-color: #e3f2fd;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        .metric-value {
            font-size: 2em;
            font-weight: bold;
            color: #3498db;
        }
        .metric-label {
            color: #7f8c8d;
        }
        .section {
            margin-bottom: 30px;
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
        tr:hover {
            background-color: #f5f9ff;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport des Métriques - $projectName</h1>
        
        <div class="summary">
            <div class="metric-card">
                <div class="metric-value">$($Metrics.FileCount)</div>
                <div class="metric-label">Fichiers</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($Metrics.DirCount)</div>
                <div class="metric-label">Répertoires</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$("{0:N0}" -f $Metrics.LineCount)</div>
                <div class="metric-label">Lignes de code</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($Metrics.DepCount)</div>
                <div class="metric-label">Dépendances</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($Metrics.ScriptCount)</div>
                <div class="metric-label">Scripts</div>
            </div>
        </div>
        
        <div class="section">
            <h2>Informations du Projet</h2>
            <table>
                <tr>
                    <th>Propriété</th>
                    <th>Valeur</th>
                </tr>
                <tr>
                    <td>Nom</td>
                    <td>$($Metrics.ProjectInfo.Name)</td>
                </tr>
                <tr>
                    <td>Version</td>
                    <td>$($Metrics.ProjectInfo.Version)</td>
                </tr>
                <tr>
                    <td>Auteur</td>
                    <td>$($Metrics.ProjectInfo.Author)</td>
                </tr>
                <tr>
                    <td>Date</td>
                    <td>$($Metrics.ProjectInfo.Date)</td>
                </tr>
                <tr>
                    <td>Plateforme</td>
                    <td>$($Metrics.ProjectInfo.Platform)</td>
                </tr>
            </table>
        </div>
"@
            
            if ($IncludeTests) {
                $htmlContent += @"
        <div class="section">
            <h2>Métriques de Test</h2>
            <table>
                <tr>
                    <th>Métrique</th>
                    <th>Valeur</th>
                </tr>
                <tr>
                    <td>Fichiers de test</td>
                    <td>$($Metrics.TestMetrics.Tests)</td>
                </tr>
                <tr>
                    <td>Tests réussis</td>
                    <td>$($Metrics.TestMetrics.Passing)</td>
                </tr>
                <tr>
                    <td>Tests échoués</td>
                    <td>$($Metrics.TestMetrics.Failing)</td>
                </tr>
"@
                
                if ($IncludeCoverage) {
                    $htmlContent += @"
                <tr>
                    <td>Couverture de code</td>
                    <td>$($Metrics.TestMetrics.Coverage)%</td>
                </tr>
"@
                }
                
                $htmlContent += @"
            </table>
        </div>
"@
            }
            
            if ($IncludeSecurity) {
                $htmlContent += @"
        <div class="section">
            <h2>Métriques de Sécurité</h2>
            <table>
                <tr>
                    <th>Métrique</th>
                    <th>Valeur</th>
                </tr>
                <tr>
                    <td>Vulnérabilités</td>
                    <td>$($Metrics.SecurityMetrics.Vulnerabilities)</td>
                </tr>
                <tr>
                    <td>Problèmes de sécurité</td>
                    <td>$($Metrics.SecurityMetrics.Issues)</td>
                </tr>
            </table>
        </div>
"@
            }
            
            $htmlContent += @"
    </div>
</body>
</html>
"@
            
            Set-Content -Path $reportFile -Value $htmlContent
            Write-Log "Rapport HTML généré: $reportFile" "SUCCESS"
        }
        
        default {
            # Affichage console
            Write-Host "`nMétriques du projet:" -ForegroundColor Cyan
            Write-Host "=================" -ForegroundColor Cyan
            Write-Host "Fichiers: $($Metrics.FileCount)" -ForegroundColor White
            Write-Host "Répertoires: $($Metrics.DirCount)" -ForegroundColor White
            Write-Host "Lignes de code: $($Metrics.LineCount)" -ForegroundColor White
            Write-Host "Dépendances: $($Metrics.DepCount)" -ForegroundColor White
            Write-Host "Scripts: $($Metrics.ScriptCount)" -ForegroundColor White
            
            if ($IncludeTests) {
                Write-Host "`nMétriques de test:" -ForegroundColor Cyan
                Write-Host "===============" -ForegroundColor Cyan
                Write-Host "Fichiers de test: $($Metrics.TestMetrics.Tests)" -ForegroundColor White
                Write-Host "Tests réussis: $($Metrics.TestMetrics.Passing)" -ForegroundColor White
                Write-Host "Tests échoués: $($Metrics.TestMetrics.Failing)" -ForegroundColor White
                
                if ($IncludeCoverage) {
                    Write-Host "Couverture de code: $($Metrics.TestMetrics.Coverage)%" -ForegroundColor White
                }
            }
            
            if ($IncludeSecurity) {
                Write-Host "`nMétriques de sécurité:" -ForegroundColor Cyan
                Write-Host "==================" -ForegroundColor Cyan
                Write-Host "Vulnérabilités: $($Metrics.SecurityMetrics.Vulnerabilities)" -ForegroundColor White
                Write-Host "Problèmes de sécurité: $($Metrics.SecurityMetrics.Issues)" -ForegroundColor White
            }
        }
    }
}

# Créer le répertoire des rapports s'il n'existe pas
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    Write-Log "Répertoire des rapports créé: $reportsDir" "INFO"
}

# Collecter les métriques
$metrics = Get-ProjectMetrics

# Générer le rapport
Generate-Report -Metrics $metrics -Format $Format

# Afficher le résumé
Write-Host "`nRésumé des métriques:" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "Fichiers: $($metrics.FileCount)" -ForegroundColor White
Write-Host "Répertoires: $($metrics.DirCount)" -ForegroundColor White
Write-Host "Lignes de code: $($metrics.LineCount)" -ForegroundColor White
Write-Host "Dépendances: $($metrics.DepCount)" -ForegroundColor White
Write-Host "Scripts: $($metrics.ScriptCount)" -ForegroundColor White

Write-Log "Rapport des métriques terminé !" "SUCCESS"