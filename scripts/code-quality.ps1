# Script de vérification de la qualité du code

Write-Host "Vérification de la qualité du code" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Vérifier le formatage avec black
Write-Host "Vérification du formatage avec black..." -ForegroundColor Yellow
black --check .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Le code n'est pas correctement formaté. Exécutez 'black .' pour le formater." -ForegroundColor Red
    exit 1
}

# Vérifier le linting avec flake8
Write-Host "Vérification du linting avec flake8..." -ForegroundColor Yellow
flake8 .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Des problèmes de linting ont été détectés." -ForegroundColor Red
    exit 1
}

# Vérifier l'ordonnancement des imports avec isort
Write-Host "Vérification de l'ordonnancement des imports avec isort..." -ForegroundColor Yellow
isort --check-only .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Les imports ne sont pas correctement ordonnés. Exécutez 'isort .' pour les ordonner." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Toutes les vérifications de qualité du code ont réussi !" -ForegroundColor Green