# Script de release du projet

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

Write-Host "Release du projet Dog Breed Identifier v$Version" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Vérifier que la version est au bon format
if ($Version -notmatch "^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$") {
    Write-Host "❌ Format de version invalide. Utilisez X.Y.Z ou X.Y.Z-prerelease" -ForegroundColor Red
    exit 1
}

# Vérifier que nous sommes sur la branche principale
$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne "main" -and $currentBranch -ne "master") {
    Write-Host "❌ Vous devez être sur la branche principale pour créer une release" -ForegroundColor Red
    exit 1
}

# Vérifier que le working directory est propre
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "❌ Le working directory n'est pas propre. Commitez ou stash vos changements." -ForegroundColor Red
    exit 1
}

# Mettre à jour le numéro de version dans les fichiers pertinents
Write-Host "Mise à jour du numéro de version..." -ForegroundColor Yellow
$versionFiles = @(
    "setup.py",
    "dog_breed_identifier/__init__.py",
    "package.json"
)

foreach ($file in $versionFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        $updatedContent = $content -replace 'version\s*=\s*["''][^"'']*["'']', "version=`"$Version`""
        if ($content -ne $updatedContent) {
            if (-not $DryRun) {
                Set-Content $file $updatedContent
                git add $file
                Write-Host "Mis à jour: $file" -ForegroundColor White
            } else {
                Write-Host "Simulé: Mise à jour de $file" -ForegroundColor White
            }
        }
    }
}

# Créer le tag git
if (-not $DryRun) {
    git commit -m "Release v$Version"
    git tag -a "v$Version" -m "Version $Version"
    Write-Host "✅ Tag créé: v$Version" -ForegroundColor Green
} else {
    Write-Host "Simulé: Création du tag v$Version" -ForegroundColor White
}

# Créer l'archive de release
$releaseDir = "./releases"
if (-not (Test-Path $releaseDir)) {
    New-Item -ItemType Directory -Path $releaseDir | Out-Null
}

$releaseArchive = "$releaseDir/dog-breed-identifier-v$Version.zip"
if (-not $DryRun) {
    Compress-Archive -Path ./* -DestinationPath $releaseArchive -CompressionLevel Optimal -Force `
        -Exclude ".git*", ".venv*", "venv*", "__pycache__*", "*.pyc", ".DS_Store", "Thumbs.db", "releases*"
    Write-Host "✅ Archive de release créée: $releaseArchive" -ForegroundColor Green
} else {
    Write-Host "Simulé: Création de l'archive $releaseArchive" -ForegroundColor White
}

# Push les changements
if (-not $DryRun) {
    $confirm = Read-Host "Pusher les changements vers le dépôt distant ? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        git push origin HEAD
        git push origin "v$Version"
        Write-Host "✅ Changements pushés vers le dépôt distant" -ForegroundColor Green
    }
} else {
    Write-Host "Simulé: Push des changements" -ForegroundColor White
}

Write-Host "Release v$Version terminée !" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "⚠️  Ceci était une simulation (dry run)" -ForegroundColor Yellow
}