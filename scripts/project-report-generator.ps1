# Script de génération de rapport de projet complet

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "./reports",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeTests = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeCoverage = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeSecurity = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludePerformance = $false
)

Write-Host "Génération du rapport de projet complet" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "Création du répertoire de sortie: $OutputDir" -ForegroundColor Yellow
}

# Générer le rapport principal
$reportFile = Join-Path $OutputDir "complete-project-report.md"
Write-Host "Génération du rapport principal..." -ForegroundColor Yellow

# Informations de base du projet
$projectInfo = @{
    Name = "Dog Breed Identifier"
    Version = "1.0.0"
    Author = "Mackly Loick Tchicaya"
    Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Platform = $env:OS
}

# Structure du projet
$projectStructure = Get-ChildItem -Recurse | Where-Object { $_.PSIsContainer -eq $false } | Group-Object { 
    if ($_.DirectoryName) {
        try {
            $_.DirectoryName.Split([IO.Path]::DirectorySeparatorChar)[-1]
        } catch {
            "Root"
        }
    } else {
        "Root"
    }
}

# Dépendances
$dependencies = @()
if (Test-Path "requirements.txt") {
    $dependencies = Get-Content "requirements.txt" | Where-Object { $_ -notmatch "^#" -and $_ -notmatch "^\s*$" }
}

# Scripts
$scripts = Get-ChildItem -Path "scripts" -Filter "*.ps1" -Recurse

# Générer le contenu du rapport
$reportContent = @"
# Rapport Complet du Projet Dog Breed Identifier

## Informations Générales

- **Nom du projet**: $($projectInfo.Name)
- **Version**: $($projectInfo.Version)
- **Auteur**: $($projectInfo.Author)
- **Date de génération**: $($projectInfo.Date)
- **Plateforme**: $($projectInfo.Platform)

## Structure du Projet

"@

# Ajouter la structure du projet
foreach ($group in $projectStructure | Sort-Object Name) {
    $reportContent += "### $($group.Name)`n"
    $reportContent += "Fichiers: $($group.Count)`n`n"
}

$reportContent += @"
## Dépendances

"@

foreach ($dep in $dependencies) {
    $reportContent += "- $dep`n"
}

$reportContent += @"
`n## Scripts Disponibles

"@

foreach ($script in $scripts | Sort-Object Name) {
    $reportContent += "- $($script.Name)`n"
}

# Ajouter les résultats des tests si demandé
if ($IncludeTests) {
    $reportContent += @"
`n## Résultats des Tests

*Les résultats des tests seront ajoutés ici.*
"@
}

# Ajouter la couverture de code si demandé
if ($IncludeCoverage) {
    $reportContent += @"
`n## Couverture de Code

*Les informations de couverture de code seront ajoutées ici.*
"@
}

# Ajouter les résultats de sécurité si demandé
if ($IncludeSecurity) {
    $reportContent += @"
`n## Analyse de Sécurité

*Les résultats de l'analyse de sécurité seront ajoutés ici.*
"@
}

# Ajouter les résultats de performance si demandé
if ($IncludePerformance) {
    $reportContent += @"
`n## Performances

*Les résultats des tests de performance seront ajoutés ici.*
"@
}

# Écrire le rapport
Set-Content -Path $reportFile -Value $reportContent

Write-Host "✅ Rapport Markdown généré: $reportFile" -ForegroundColor Green

# Générer un rapport HTML complet
$htmlReportFile = Join-Path $OutputDir "complete-project-report.html"
Write-Host "Génération du rapport HTML..." -ForegroundColor Yellow

$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport Complet du Projet Dog Breed Identifier</title>
    <meta charset="UTF-8">
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background-color: #f8f9fa;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        h1, h2, h3 { 
            color: #2c3e50; 
        }
        h1 {
            text-align: center;
            padding-bottom: 20px;
            border-bottom: 2px solid #3498db;
        }
        .section { 
            margin-bottom: 30px; 
            padding: 20px;
            border-radius: 8px;
            background-color: #ffffff;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .info-card {
            background-color: #e3f2fd;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }
        .info-card h3 {
            margin-top: 0;
            color: #3498db;
        }
        .file-list { 
            columns: 2; 
            column-gap: 30px;
        }
        .file-list div {
            break-inside: avoid;
            margin-bottom: 10px;
        }
        ul {
            line-height: 1.6;
        }
        .stats {
            display: flex;
            justify-content: space-around;
            text-align: center;
            margin: 30px 0;
        }
        .stat-item {
            padding: 20px;
            background-color: #f1f8ff;
            border-radius: 8px;
            flex: 1;
            margin: 0 10px;
        }
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            color: #3498db;
        }
        .stat-label {
            color: #7f8c8d;
        }
        pre {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
        code {
            font-family: 'Courier New', monospace;
            background-color: #f1f8ff;
            padding: 2px 5px;
            border-radius: 3px;
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
        <h1>Rapport Complet du Projet Dog Breed Identifier</h1>
        
        <div class="stats">
            <div class="stat-item">
                <div class="stat-number">$($scripts.Count)</div>
                <div class="stat-label">Scripts</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">$($dependencies.Count)</div>
                <div class="stat-label">Dépendances</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">$((Get-ChildItem -Recurse | Where-Object { $_.PSIsContainer -eq $false }).Count)</div>
                <div class="stat-label">Fichiers</div>
            </div>
        </div>
        
        <div class="section">
            <h2>Informations Générales</h2>
            <div class="info-grid">
                <div class="info-card">
                    <h3>Nom du projet</h3>
                    <p>$($projectInfo.Name)</p>
                </div>
                <div class="info-card">
                    <h3>Version</h3>
                    <p>$($projectInfo.Version)</p>
                </div>
                <div class="info-card">
                    <h3>Auteur</h3>
                    <p>$($projectInfo.Author)</p>
                </div>
                <div class="info-card">
                    <h3>Date de génération</h3>
                    <p>$($projectInfo.Date)</p>
                </div>
                <div class="info-card">
                    <h3>Plateforme</h3>
                    <p>$($projectInfo.Platform)</p>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>Structure du Projet</h2>
"@

# Ajouter la structure du projet en HTML
$structureHtml = ""
foreach ($group in $projectStructure | Sort-Object Name) {
    $structureHtml += "<div><strong>$($group.Name):</strong> $($group.Count) fichiers</div>`n"
}

$htmlContent += @"
            <div class="file-list">
                $structureHtml
            </div>
        </div>
        
        <div class="section">
            <h2>Dépendances</h2>
            <table>
                <thead>
                    <tr>
                        <th>Dépendance</th>
                    </tr>
                </thead>
                <tbody>
"@

foreach ($dep in $dependencies) {
    $htmlContent += "<tr><td><code>$dep</code></td></tr>`n"
}

$htmlContent += @"
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>Scripts Disponibles</h2>
            <table>
                <thead>
                    <tr>
                        <th>Nom du Script</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
"@

foreach ($script in $scripts | Sort-Object Name) {
    # Extraire une description basique du script
    $description = "Script PowerShell pour $([System.IO.Path]::GetFileNameWithoutExtension($script.Name))"
    $htmlContent += "<tr><td><code>$($script.Name)</code></td><td>$description</td></tr>`n"
}

$htmlContent += @"
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>Fonctionnalités Clés</h2>
            <ul>
                <li>Identification automatique des races de chiens via IA</li>
                <li>Interface web responsive</li>
                <li>Système de déploiement automatisé</li>
                <li>Tests unitaires et d'intégration</li>
                <li>Analyse de sécurité complète</li>
                <li>Monitoring des performances</li>
                <li>Génération de documentation</li>
                <li>Gestion des versions</li>
            </ul>
        </div>
    </div>
</body>
</html>
"@

Set-Content -Path $htmlReportFile -Value $htmlContent

Write-Host "✅ Rapport HTML généré: $htmlReportFile" -ForegroundColor Green

Write-Host "Génération des rapports terminée !" -ForegroundColor Cyan