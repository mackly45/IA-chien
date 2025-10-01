# Script de génération de rapport

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "./reports",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeTests = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeCoverage = $false
)

Write-Host "Génération du rapport de projet" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "Création du répertoire de sortie: $OutputDir" -ForegroundColor Yellow
}

# Générer le rapport principal
$reportFile = Join-Path $OutputDir "project-report.md"
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
$projectStructure = Get-ChildItem -Recurse | Where-Object { $_.PSIsContainer -eq $false } | Group-Object { $_.DirectoryName.Split('\')[-1] }

# Dépendances
$dependencies = @()
if (Test-Path "requirements.txt") {
    $dependencies = Get-Content "requirements.txt" | Where-Object { $_ -notmatch "^#" -and $_ -notmatch "^\s*$" }
}

# Scripts
$scripts = Get-ChildItem -Path "scripts" -Filter "*.ps1" -Recurse

# Générer le contenu du rapport
$reportContent = @"
# Rapport du Projet Dog Breed Identifier

## Informations Générales

- **Nom du projet**: $($projectInfo.Name)
- **Version**: $($projectInfo.Version)
- **Auteur**: $($projectInfo.Author)
- **Date de génération**: $($projectInfo.Date)
- **Plateforme**: $($projectInfo.Platform)

## Structure du Projet

"@

# Ajouter la structure du projet
foreach ($group in $projectStructure) {
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

foreach ($script in $scripts) {
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

# Écrire le rapport
Set-Content -Path $reportFile -Value $reportContent

Write-Host "✅ Rapport généré: $reportFile" -ForegroundColor Green

# Générer un rapport HTML si demandé
$htmlReportFile = Join-Path $OutputDir "project-report.html"
Write-Host "Génération du rapport HTML..." -ForegroundColor Yellow

$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport du Projet Dog Breed Identifier</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1, h2, h3 { color: #333; }
        .section { margin-bottom: 30px; }
        .info { background-color: #f5f5f5; padding: 15px; border-radius: 5px; }
        .file-list { columns: 3; }
    </style>
</head>
<body>
    <h1>Rapport du Projet Dog Breed Identifier</h1>
    
    <div class="section">
        <h2>Informations Générales</h2>
        <div class="info">
            <p><strong>Nom du projet:</strong> $($projectInfo.Name)</p>
            <p><strong>Version:</strong> $($projectInfo.Version)</p>
            <p><strong>Auteur:</strong> $($projectInfo.Author)</p>
            <p><strong>Date de génération:</strong> $($projectInfo.Date)</p>
            <p><strong>Plateforme:</strong> $($projectInfo.Platform)</p>
        </div>
    </div>
    
    <div class="section">
        <h2>Structure du Projet</h2>
        <div class="file-list">
"@

foreach ($group in $projectStructure) {
    $htmlContent += "<p><strong>$($group.Name):</strong> $($group.Count) fichiers</p>`n"
}

$htmlContent += @"
        </div>
    </div>
    
    <div class="section">
        <h2>Dépendances</h2>
        <ul>
"@

foreach ($dep in $dependencies) {
    $htmlContent += "<li>$dep</li>`n"
}

$htmlContent += @"
        </ul>
    </div>
    
    <div class="section">
        <h2>Scripts Disponibles</h2>
        <ul>
"@

foreach ($script in $scripts) {
    $htmlContent += "<li>$($script.Name)</li>`n"
}

$htmlContent += @"
        </ul>
    </div>
</body>
</html>
"@

Set-Content -Path $htmlReportFile -Value $htmlContent

Write-Host "✅ Rapport HTML généré: $htmlReportFile" -ForegroundColor Green

Write-Host "Génération des rapports terminée !" -ForegroundColor Cyan