# Script de vérification de sécurité avancée

param(
    [Parameter(Mandatory=$false)]
    [switch]$IncludeDependencies = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeCodeAnalysis = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeContainerScan = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeSecrets = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFormat = "console",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "./security-report.txt"
)

Write-Host "Vérification de sécurité avancée de Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$report = @()

# Fonction pour ajouter une entrée au rapport
function Add-ReportEntry {
    param([string]$Type, [string]$Severity, [string]$Message, [string]$Details = "")
    
    $entry = @{
        Type = $Type
        Severity = $Severity
        Message = $Message
        Details = $Details
        Timestamp = Get-Date
    }
    
    $script:report += $entry
    
    # Afficher immédiatement si le format est console
    if ($OutputFormat -eq "console") {
        $color = switch ($Severity) {
            "Critical" { "Red" }
            "High" { "DarkRed" }
            "Medium" { "Yellow" }
            "Low" { "DarkYellow" }
            "Info" { "White" }
            default { "Gray" }
        }
        
        Write-Host "[$Severity] $Message" -ForegroundColor $color
        if ($Details) {
            Write-Host "  Détails: $Details" -ForegroundColor Gray
        }
    }
}

# Fonction pour vérifier les dépendances vulnérables
function Check-VulnerableDependencies {
    Write-Host "Vérification des dépendances vulnérables..." -ForegroundColor Yellow
    
    # Vérifier si pip-audit est installé
    if (-not (Get-Command pip-audit -ErrorAction SilentlyContinue)) {
        Add-ReportEntry -Type "Dependency" -Severity "Info" -Message "pip-audit non installé" -Details "Installation recommandée: pip install pip-audit"
        return
    }
    
    try {
        # Exécuter pip-audit
        $auditResult = pip-audit 2>&1
        $vulnerabilitiesFound = $false
        
        foreach ($line in $auditResult) {
            if ($line -match "is vulnerable") {
                $vulnerabilitiesFound = $true
                $packageName = ""
                $cve = ""
                
                # Extraire les informations de la ligne
                if ($line -match "([^ ]+) is vulnerable") {
                    $packageName = $matches[1]
                }
                
                if ($line -match "CVE-\d+-\d+") {
                    $cve = ($line | Select-String -Pattern "CVE-\d+-\d+" -AllMatches).Matches.Value
                }
                
                Add-ReportEntry -Type "Dependency" -Severity "High" -Message "Dépendance vulnérable trouvée" -Details "$packageName - $cve"
            }
        }
        
        if (-not $vulnerabilitiesFound) {
            Add-ReportEntry -Type "Dependency" -Severity "Info" -Message "Aucune dépendance vulnérable trouvée"
        }
    } catch {
        Add-ReportEntry -Type "Dependency" -Severity "Medium" -Message "Échec de l'audit des dépendances" -Details $_.Exception.Message
    }
}

# Fonction pour analyser le code à la recherche de problèmes de sécurité
function Analyze-CodeSecurity {
    Write-Host "Analyse du code pour les problèmes de sécurité..." -ForegroundColor Yellow
    
    # Vérifier si bandit est installé (pour Python)
    if (Get-Command bandit -ErrorAction SilentlyContinue) {
        try {
            $banditResult = bandit -r . -f json 2>$null
            if ($banditResult) {
                $results = $banditResult | ConvertFrom-Json
                if ($results.results.Count -gt 0) {
                    foreach ($result in $results.results) {
                        $severity = switch ($result.issue_severity) {
                            "HIGH" { "High" }
                            "MEDIUM" { "Medium" }
                            "LOW" { "Low" }
                            default { "Info" }
                        }
                        
                        Add-ReportEntry -Type "Code" -Severity $severity -Message "Problème de sécurité dans le code" -Details "$($result.filename):$($result.line_number) - $($result.issue_text)"
                    }
                } else {
                    Add-ReportEntry -Type "Code" -Severity "Info" -Message "Aucun problème de sécurité dans le code trouvé"
                }
            }
        } catch {
            Add-ReportEntry -Type "Code" -Severity "Medium" -Message "Échec de l'analyse du code avec bandit" -Details $_.Exception.Message
        }
    } else {
        Add-ReportEntry -Type "Code" -Severity "Info" -Message "bandit non installé" -Details "Installation recommandée: pip install bandit"
    }
    
    # Vérifier les patterns dangereux dans le code
    $dangerousPatterns = @{
        "eval\(" = "Utilisation de eval() - risque d'exécution de code arbitraire"
        "exec\(" = "Utilisation de exec() - risque d'exécution de code arbitraire"
        "os\.system\(" = "Utilisation de os.system() - risque d'exécution de commande"
        "subprocess\." = "Utilisation de subprocess - vérifier les paramètres"
        "input\(" = "Utilisation de input() - risque XSS si non validé"
        "pickle\." = "Utilisation de pickle - risque de désérialisation dangereuse"
    }
    
    $files = Get-ChildItem -Recurse -Include "*.py", "*.js", "*.sh" -Exclude "node_modules", "venv", ".venv"
    
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw
        
        foreach ($pattern in $dangerousPatterns.Keys) {
            if ($content -match $pattern) {
                $lineNumber = 0
                $content -split "`n" | ForEach-Object {
                    $lineNumber++
                    if ($_ -match $pattern) {
                        Add-ReportEntry -Type "Code" -Severity "Medium" -Message "Pattern dangereux trouvé" -Details "$($file.FullName):$lineNumber - $($dangerousPatterns[$pattern])"
                    }
                }
            }
        }
    }
}

# Fonction pour scanner les conteneurs Docker
function Scan-DockerContainers {
    Write-Host "Scan des conteneurs Docker..." -ForegroundColor Yellow
    
    # Vérifier si Docker est installé
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Add-ReportEntry -Type "Container" -Severity "Info" -Message "Docker non installé" -Details "Scan des conteneurs impossible"
        return
    }
    
    # Vérifier si trivy est installé
    if (Get-Command trivy -ErrorAction SilentlyContinue) {
        try {
            # Scanner l'image du projet
            $trivyResult = trivy image --format json dog-breed-identifier 2>$null
            if ($trivyResult) {
                $results = $trivyResult | ConvertFrom-Json
                if ($results.Results.Vulnerabilities.Count -gt 0) {
                    foreach ($vuln in $results.Results.Vulnerabilities) {
                        $severity = switch ($vuln.Severity) {
                            "CRITICAL" { "Critical" }
                            "HIGH" { "High" }
                            "MEDIUM" { "Medium" }
                            "LOW" { "Low" }
                            default { "Info" }
                        }
                        
                        Add-ReportEntry -Type "Container" -Severity $severity -Message "Vulnérabilité dans le conteneur" -Details "$($vuln.PkgName):$($vuln.InstalledVersion) - $($vuln.Title)"
                    }
                } else {
                    Add-ReportEntry -Type "Container" -Severity "Info" -Message "Aucune vulnérabilité dans le conteneur trouvée"
                }
            }
        } catch {
            Add-ReportEntry -Type "Container" -Severity "Medium" -Message "Échec du scan du conteneur avec trivy" -Details $_.Exception.Message
        }
    } else {
        Add-ReportEntry -Type "Container" -Severity "Info" -Message "trivy non installé" -Details "Installation recommandée: https://aquasecurity.github.io/trivy/"
    }
    
    # Vérifier les bonnes pratiques Docker
    if (Test-Path "Dockerfile") {
        $dockerfileContent = Get-Content "Dockerfile" -Raw
        
        # Vérifier l'utilisation de USER root
        if ($dockerfileContent -match "USER\s+root") {
            Add-ReportEntry -Type "Container" -Severity "Medium" -Message "Utilisation de USER root dans Dockerfile" -Details "Recommandé: utiliser un utilisateur non-root"
        }
        
        # Vérifier l'exposition de ports privilégiés
        if ($dockerfileContent -match "EXPOSE\s+(1|2|3|4|5|6|7|8|9)\d{0,3}") {
            Add-ReportEntry -Type "Container" -Severity "Low" -Message "Exposition de port privilégié" -Details "Les ports < 1024 sont privilégiés"
        }
        
        # Vérifier ADD vs COPY
        if ($dockerfileContent -match "ADD\s+") {
            Add-ReportEntry -Type "Container" -Severity "Low" -Message "Utilisation de ADD dans Dockerfile" -Details "Recommandé: utiliser COPY au lieu de ADD"
        }
    }
}

# Fonction pour détecter les secrets dans le code
function Detect-Secrets {
    Write-Host "Détection des secrets dans le code..." -ForegroundColor Yellow
    
    # Patterns de secrets courants
    $secretPatterns = @{
        "AWS Access Key" = "AKIA[0-9A-Z]{16}"
        "AWS Secret Key" = "(?i)aws(.{0,20})?['\`"][0-9a-zA-Z/+]{40}['\`"]"
        "Google API Key" = "AIza[0-9A-Za-z\\-_]{35}"
        "Generic API Key" = "(?i)api(.{0,20})?['\`"][0-9a-zA-Z]{32,45}['\`"]"
        "Generic Secret" = "(?i)secret(.{0,20})?['\`"][0-9a-zA-Z]{32,45}['\`"]"
        "Password" = "(?i)(password|pwd)(.{0,20})?['\`"][^'\`"]{8,}['\`"]"
        "Token" = "(?i)token(.{0,20})?['\`"][0-9a-zA-Z\-_]{20,}['\`"]"
        "Private Key" = "-----BEGIN(.*)PRIVATE KEY-----"
    }
    
    # Fichiers à exclure
    $excludePatterns = @(
        "\.git",
        "node_modules",
        "venv",
        "\.venv",
        "__pycache__",
        "\.tox",
        "\.eggs"
    )
    
    # Obtenir tous les fichiers
    $files = Get-ChildItem -Recurse -File | Where-Object {
        $exclude = $false
        foreach ($pattern in $excludePatterns) {
            if ($_.FullName -match $pattern) {
                $exclude = $true
                break
            }
        }
        -not $exclude
    }
    
    foreach ($file in $files) {
        try {
            # Limiter la taille des fichiers à analyser
            if ($file.Length -gt 10MB) {
                continue
            }
            
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            
            if ($content) {
                foreach ($patternName in $secretPatterns.Keys) {
                    $pattern = $secretPatterns[$patternName]
                    
                    if ($content -match $pattern) {
                        # Vérifier si c'est un faux positif
                        $isFalsePositive = $false
                        $matchValue = $matches[0]
                        
                        # Vérifier les faux positifs courants
                        if ($patternName -eq "Password" -and $matchValue -match "(?i)(correct|wrong|invalid|placeholder|example)") {
                            $isFalsePositive = $true
                        }
                        
                        if (-not $isFalsePositive) {
                            Add-ReportEntry -Type "Secret" -Severity "High" -Message "Potentiel secret trouvé" -Details "$patternName dans $($file.FullName)"
                        }
                    }
                }
            }
        } catch {
            # Ignorer les erreurs de lecture de fichiers
        }
    }
    
    # Vérifier les fichiers d'environnement
    $envFiles = Get-ChildItem -Path . -Include ".env", ".env.*" -Exclude ".env.example"
    foreach ($file in $envFiles) {
        Add-ReportEntry -Type "Secret" -Severity "High" -Message "Fichier d'environnement trouvé" -Details "$($file.FullName) - Ne doit pas être commité"
    }
}

# Fonction pour générer le rapport
function Generate-Report {
    Write-Host "Génération du rapport de sécurité..." -ForegroundColor Yellow
    
    switch ($OutputFormat.ToLower()) {
        "json" {
            $report | ConvertTo-Json -Depth 10 | Out-File $OutputFile
            Write-Host "✅ Rapport JSON généré: $OutputFile" -ForegroundColor Green
        }
        
        "html" {
            $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de Sécurité - $projectName</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .critical { background-color: #ffebee; border-left: 5px solid #f44336; padding: 10px; margin: 10px 0; }
        .high { background-color: #fff3e0; border-left: 5px solid #ff9800; padding: 10px; margin: 10px 0; }
        .medium { background-color: #fff8e1; border-left: 5px solid #ffc107; padding: 10px; margin: 10px 0; }
        .low { background-color: #f1f8e9; border-left: 5px solid #8bc34a; padding: 10px; margin: 10px 0; }
        .info { background-color: #e3f2fd; border-left: 5px solid #2196f3; padding: 10px; margin: 10px 0; }
        .severity { font-weight: bold; }
    </style>
</head>
<body>
    <h1>Rapport de Sécurité - $projectName</h1>
    <p>Généré le: $(Get-Date)</p>
"@
            
            foreach ($entry in $report) {
                $className = $entry.Severity.ToLower()
                $htmlContent += @"
    <div class="$className">
        <span class="severity">[$($entry.Severity)]</span> $($entry.Message)
        <br><small>$($entry.Details)</small>
        <br><small>$(($entry.Timestamp).ToString("yyyy-MM-dd HH:mm:ss"))</small>
    </div>
"@
            }
            
            $htmlContent += @"
</body>
</html>
"@
            
            Set-Content -Path $OutputFile -Value $htmlContent
            Write-Host "✅ Rapport HTML généré: $OutputFile" -ForegroundColor Green
        }
        
        default {
            # Le rapport a déjà été affiché en console
            if ($OutputFile -ne "./security-report.txt") {
                $reportContent = "Rapport de Sécurité - $projectName`n"
                $reportContent += "Généré le: $(Get-Date)`n`n"
                
                foreach ($entry in $report) {
                    $reportContent += "[$($entry.Severity)] $($entry.Message)`n"
                    if ($entry.Details) {
                        $reportContent += "  Détails: $($entry.Details)`n"
                    }
                    $reportContent += "  $(($entry.Timestamp).ToString("yyyy-MM-dd HH:mm:ss"))`n`n"
                }
                
                Set-Content -Path $OutputFile -Value $reportContent
                Write-Host "✅ Rapport texte généré: $OutputFile" -ForegroundColor Green
            }
        }
    }
}

# Exécuter les vérifications selon les paramètres
Write-Host "Exécution des vérifications de sécurité..." -ForegroundColor Yellow

if ($IncludeDependencies) {
    Check-VulnerableDependencies
}

if ($IncludeCodeAnalysis) {
    Analyze-CodeSecurity
}

if ($IncludeContainerScan) {
    Scan-DockerContainers
}

if ($IncludeSecrets) {
    Detect-Secrets
}

# Générer le rapport
Generate-Report

# Afficher le résumé
Write-Host "`nRésumé de la sécurité:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

$criticalCount = ($report | Where-Object { $_.Severity -eq "Critical" }).Count
$highCount = ($report | Where-Object { $_.Severity -eq "High" }).Count
$mediumCount = ($report | Where-Object { $_.Severity -eq "Medium" }).Count
$lowCount = ($report | Where-Object { $_.Severity -eq "Low" }).Count

if ($criticalCount -gt 0) {
    Write-Host "❌ Critique: $criticalCount" -ForegroundColor Red
}
if ($highCount -gt 0) {
    Write-Host "⚠️  Haut: $highCount" -ForegroundColor DarkRed
}
if ($mediumCount -gt 0) {
    Write-Host "⚠️  Moyen: $mediumCount" -ForegroundColor Yellow
}
if ($lowCount -gt 0) {
    Write-Host "ℹ️  Bas: $lowCount" -ForegroundColor DarkYellow
}

$totalIssues = $criticalCount + $highCount + $mediumCount + $lowCount
if ($totalIssues -eq 0) {
    Write-Host "✅ Aucun problème de sécurité trouvé" -ForegroundColor Green
} else {
    Write-Host "🔧 $totalIssues problèmes de sécurité trouvés" -ForegroundColor White
}

Write-Host "Vérification de sécurité avancée terminée !" -ForegroundColor Cyan