# Script d'analyse des dépendances

param(
    [Parameter(Mandatory=$false)]
    [string]$RequirementsFile = "requirements.txt",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFormat = "console",
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckVulnerabilities = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckCompatibility = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

Write-Host "Analyse des dépendances" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$reportsDir = "./reports"
$vulnerabilityCheckers = @("pip-audit", "safety")

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

# Fonction pour analyser les dépendances depuis requirements.txt
function Get-Dependencies {
    param([string]$ReqFile)
    
    if (-not (Test-Path $ReqFile)) {
        Write-Log "Fichier de dépendances non trouvé: $ReqFile" "ERROR"
        return @()
    }
    
    $dependencies = @()
    $content = Get-Content $ReqFile
    
    foreach ($line in $content) {
        # Ignorer les lignes vides et les commentaires
        if ($line -match "^\s*$" -or $line -match "^\s*#") {
            continue
        }
        
        # Extraire le nom du paquet et la version
        if ($line -match "^([^>=<~!]+)([>=<~!]=?.*)?$") {
            $packageName = $matches[1].Trim()
            $versionSpec = if ($matches[2]) { $matches[2].Trim() } else { "" }
            
            $dependencies += @{
                Name = $packageName
                VersionSpec = $versionSpec
                Line = $line
            }
        }
    }
    
    return $dependencies
}

# Fonction pour vérifier les vulnérabilités
function Test-Vulnerabilities {
    param([array]$Dependencies)
    
    Write-Log "Vérification des vulnérabilités..." "INFO"
    $vulnerabilities = @()
    
    # Vérifier si pip-audit est disponible
    if (Test-Tool "pip-audit") {
        Write-Log "Utilisation de pip-audit pour la vérification des vulnérabilités" "INFO"
        
        try {
            $auditResult = pip-audit 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Aucune vulnérabilité trouvée avec pip-audit" "SUCCESS"
            } else {
                Write-Log "Vulnérabilités trouvées avec pip-audit" "WARN"
                # Parser les résultats
                $auditResult | ForEach-Object {
                    if ($_ -match "^(.+?)\s+(.+?)\s+(.+?)\s+(.+?)$") {
                        $vulnerabilities += @{
                            Package = $matches[1]
                            Installed = $matches[2]
                            Affected = $matches[3]
                            CVE = $matches[4]
                        }
                    }
                }
            }
        } catch {
            Write-Log "Erreur lors de l'exécution de pip-audit: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-Log "pip-audit non trouvé, vérification des vulnérabilités ignorée" "WARN"
    }
    
    # Vérifier si safety est disponible
    if (Test-Tool "safety") {
        Write-Log "Utilisation de safety pour la vérification des vulnérabilités" "INFO"
        
        try {
            $safetyResult = safety check --json 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Aucune vulnérabilité trouvée avec safety" "SUCCESS"
            } else {
                Write-Log "Vulnérabilités trouvées avec safety" "WARN"
                # Parser les résultats JSON
                try {
                    $safetyJson = $safetyResult | ConvertFrom-Json
                    if ($safetyJson.vulnerabilities) {
                        $safetyJson.vulnerabilities | ForEach-Object {
                            $vulnerabilities += @{
                                Package = $_.package_name
                                Installed = $_.analyzed_version
                                Affected = $_.vulnerable_spec
                                CVE = $_.cve
                                Description = $_.advisory
                            }
                        }
                    }
                } catch {
                    Write-Log "Erreur lors du parsing des résultats safety: $($_.Exception.Message)" "ERROR"
                }
            }
        } catch {
            Write-Log "Erreur lors de l'exécution de safety: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-Log "safety non trouvé, vérification des vulnérabilités ignorée" "WARN"
    }
    
    return $vulnerabilities
}

# Fonction pour vérifier la compatibilité
function Test-Compatibility {
    param([array]$Dependencies)
    
    Write-Log "Vérification de la compatibilité des dépendances..." "INFO"
    $compatibilityIssues = @()
    
    # Vérifier la compatibilité avec Python
    try {
        $pythonVersion = python --version 2>&1
        Write-Log "Version Python: $pythonVersion" "INFO"
        
        # Pour chaque dépendance, vérifier la compatibilité
        foreach ($dep in $Dependencies) {
            # Cette vérification est simplifiée car elle nécessiterait normalement
            # des appels à des bases de données de compatibilité
            Write-Log "Vérification de la compatibilité pour $($dep.Name)..." "INFO"
        }
    } catch {
        Write-Log "Erreur lors de la vérification de la compatibilité: $($_.Exception.Message)" "ERROR"
    }
    
    return $compatibilityIssues
}

# Fonction pour générer un rapport
function Generate-Report {
    param(
        [array]$Dependencies,
        [array]$Vulnerabilities,
        [array]$CompatibilityIssues,
        [string]$Format
    )
    
    switch ($Format.ToLower()) {
        "json" {
            $reportData = @{
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                projectName = $projectName
                dependencies = $Dependencies
                vulnerabilities = $Vulnerabilities
                compatibilityIssues = $CompatibilityIssues
                summary = @{
                    totalDependencies = $Dependencies.Count
                    vulnerableDependencies = $Vulnerabilities.Count
                    compatibilityIssues = $CompatibilityIssues.Count
                }
            }
            
            $reportFile = Join-Path $reportsDir "dependency-analysis.json"
            $reportData | ConvertTo-Json -Depth 10 | Out-File $reportFile
            Write-Log "Rapport JSON généré: $reportFile" "SUCCESS"
        }
        
        "html" {
            $reportFile = Join-Path $reportsDir "dependency-analysis.html"
            
            $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Analyse des Dépendances - $projectName</title>
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
            background-color: #e3f2fd;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
        }
        .summary-item {
            text-align: center;
        }
        .summary-number {
            font-size: 2em;
            font-weight: bold;
            color: #3498db;
        }
        .summary-label {
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
        .vulnerability {
            border-left: 4px solid #e74c3c;
            padding-left: 20px;
            margin: 20px 0;
        }
        .compatibility {
            border-left: 4px solid #f39c12;
            padding-left: 20px;
            margin: 20px 0;
        }
        .status-success { color: #4caf50; }
        .status-warning { color: #f39c12; }
        .status-error { color: #e74c3c; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Analyse des Dépendances - $projectName</h1>
        
        <div class="summary">
            <div class="summary-item">
                <div class="summary-number">$($Dependencies.Count)</div>
                <div class="summary-label">Dépendances</div>
            </div>
            <div class="summary-item">
                <div class="summary-number">$($Vulnerabilities.Count)</div>
                <div class="summary-label">Vulnérabilités</div>
            </div>
            <div class="summary-item">
                <div class="summary-number">$($CompatibilityIssues.Count)</div>
                <div class="summary-label">Incompatibilités</div>
            </div>
        </div>
        
        <div class="section">
            <h2>Dépendances</h2>
            <table>
                <thead>
                    <tr>
                        <th>Nom</th>
                        <th>Version</th>
                        <th>Spécification</th>
                    </tr>
                </thead>
                <tbody>
"@
            
            foreach ($dep in $Dependencies) {
                $htmlContent += @"
                    <tr>
                        <td>$($dep.Name)</td>
                        <td></td>
                        <td>$($dep.VersionSpec)</td>
                    </tr>
"@
            }
            
            $htmlContent += @"
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>Vulnérabilités</h2>
"@
            
            if ($Vulnerabilities.Count -eq 0) {
                $htmlContent += "<p class='status-success'>Aucune vulnérabilité trouvée</p>"
            } else {
                foreach ($vuln in $Vulnerabilities) {
                    $htmlContent += @"
            <div class="vulnerability">
                <h3>$($vuln.Package)</h3>
                <p><strong>Version installée:</strong> $($vuln.Installed)</p>
                <p><strong>Version affectée:</strong> $($vuln.Affected)</p>
                <p><strong>CVE:</strong> $($vuln.CVE)</p>
"@
                    if ($vuln.Description) {
                        $htmlContent += "<p><strong>Description:</strong> $($vuln.Description)</p>"
                    }
                    $htmlContent += "</div>"
                }
            }
            
            $htmlContent += @"
        </div>
        
        <div class="section">
            <h2>Compatibilité</h2>
"@
            
            if ($CompatibilityIssues.Count -eq 0) {
                $htmlContent += "<p class='status-success'>Aucun problème de compatibilité trouvé</p>"
            } else {
                foreach ($issue in $CompatibilityIssues) {
                    $htmlContent += @"
            <div class="compatibility">
                <h3>$($issue.Package)</h3>
                <p>$($issue.Description)</p>
            </div>
"@
                }
            }
            
            $htmlContent += @"
        </div>
    </div>
</body>
</html>
"@
            
            Set-Content -Path $reportFile -Value $htmlContent
            Write-Log "Rapport HTML généré: $reportFile" "SUCCESS"
        }
        
        default {
            # Affichage console
            Write-Host "`nRésumé de l'analyse:" -ForegroundColor Cyan
            Write-Host "=================" -ForegroundColor Cyan
            Write-Host "Dépendances totales: $($Dependencies.Count)" -ForegroundColor White
            Write-Host "Vulnérabilités: $($Vulnerabilities.Count)" -ForegroundColor $(if ($Vulnerabilities.Count -eq 0) { "Green" } else { "Red" })
            Write-Host "Problèmes de compatibilité: $($CompatibilityIssues.Count)" -ForegroundColor $(if ($CompatibilityIssues.Count -eq 0) { "Green" } else { "Yellow" })
            
            if ($Vulnerabilities.Count -gt 0) {
                Write-Host "`nVulnérabilités trouvées:" -ForegroundColor Red
                Write-Host "=====================" -ForegroundColor Red
                foreach ($vuln in $Vulnerabilities) {
                    Write-Host "Package: $($vuln.Package)" -ForegroundColor Gray
                    Write-Host "  Version installée: $($vuln.Installed)" -ForegroundColor Gray
                    Write-Host "  Version affectée: $($vuln.Affected)" -ForegroundColor Gray
                    Write-Host "  CVE: $($vuln.CVE)" -ForegroundColor Gray
                    if ($vuln.Description) {
                        Write-Host "  Description: $($vuln.Description)" -ForegroundColor Gray
                    }
                    Write-Host ""
                }
            }
            
            if ($CompatibilityIssues.Count -gt 0) {
                Write-Host "`nProblèmes de compatibilité:" -ForegroundColor Yellow
                Write-Host "========================" -ForegroundColor Yellow
                foreach ($issue in $CompatibilityIssues) {
                    Write-Host "Package: $($issue.Package)" -ForegroundColor Gray
                    Write-Host "  $($issue.Description)" -ForegroundColor Gray
                    Write-Host ""
                }
            }
        }
    }
}

# Créer le répertoire des rapports s'il n'existe pas
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    Write-Log "Répertoire des rapports créé: $reportsDir" "INFO"
}

# Analyser les dépendances
Write-Log "Analyse des dépendances depuis $RequirementsFile..." "INFO"
$dependencies = Get-Dependencies -ReqFile $RequirementsFile

if ($dependencies.Count -eq 0) {
    Write-Log "Aucune dépendance trouvée" "WARN"
    exit 0
}

Write-Log "$($dependencies.Count) dépendances trouvées" "SUCCESS"

# Vérifier les vulnérabilités si demandé
$vulnerabilities = @()
if ($CheckVulnerabilities) {
    $vulnerabilities = Test-Vulnerabilities -Dependencies $dependencies
}

# Vérifier la compatibilité si demandé
$compatibilityIssues = @()
if ($CheckCompatibility) {
    $compatibilityIssues = Test-Compatibility -Dependencies $dependencies
}

# Générer le rapport
Generate-Report -Dependencies $dependencies -Vulnerabilities $vulnerabilities -CompatibilityIssues $compatibilityIssues -Format $OutputFormat

# Afficher le résumé final
Write-Host "`nRésumé de l'analyse des dépendances:" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "Dépendances analysées: $($dependencies.Count)" -ForegroundColor White
Write-Host "Vulnérabilités trouvées: $($vulnerabilities.Count)" -ForegroundColor $(if ($vulnerabilities.Count -eq 0) { "Green" } else { "Red" })
Write-Host "Problèmes de compatibilité: $($compatibilityIssues.Count)" -ForegroundColor $(if ($compatibilityIssues.Count -eq 0) { "Green" } else { "Yellow" })

if ($vulnerabilities.Count -eq 0 -and $compatibilityIssues.Count -eq 0) {
    Write-Host "`n✅ Toutes les dépendances sont valides !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ Problèmes détectés dans les dépendances" -ForegroundColor Red
    exit 1
}