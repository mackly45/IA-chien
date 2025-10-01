# Script de vérification de sécurité

Write-Host "Vérification de la sécurité du projet" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Vérifier les dépendances vulnérables avec pip-audit
Write-Host "Vérification des dépendances vulnérables..." -ForegroundColor Yellow
if (Get-Command pip-audit -ErrorAction SilentlyContinue) {
    pip-audit
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Des vulnérabilités ont été détectées dans les dépendances !" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "pip-audit n'est pas installé. Installez-le avec 'pip install pip-audit'." -ForegroundColor Yellow
}

# Vérifier les secrets dans le code
Write-Host "Vérification des secrets dans le code..." -ForegroundColor Yellow
$secretPatterns = @(
    "password\s*=\s*['""]",
    "secret\s*=\s*['""]",
    "token\s*=\s*['""]",
    "key\s*=\s*['""]"
)

$files = Get-ChildItem -Recurse -Include "*.py", "*.js", "*.json", "*.yml", "*.yaml", "*.env" | Where-Object {
    $_.Name -notlike ".*" -and 
    $_.Name -ne "package-lock.json" -and
    $_.Name -ne "yarn.lock"
}

$secretsFound = $false
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    foreach ($pattern in $secretPatterns) {
        if ($content -match $pattern) {
            Write-Host "Potentiel secret trouvé dans $($file.FullName)" -ForegroundColor Red
            $secretsFound = $true
        }
    }
}

if ($secretsFound) {
    Write-Host "⚠️  Des secrets potentiels ont été trouvés dans le code !" -ForegroundColor Yellow
    Write-Host "Veuillez vérifier ces fichiers et utiliser des variables d'environnement à la place." -ForegroundColor Yellow
}

Write-Host "✅ Vérification de sécurité terminée !" -ForegroundColor Green