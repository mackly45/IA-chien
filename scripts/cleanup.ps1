# Script de nettoyage pour le projet

Write-Host "Nettoyage du projet Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Arrêter et supprimer les conteneurs
Write-Host "Arrêt des conteneurs..." -ForegroundColor Yellow
docker-compose down 2>$null

# Supprimer les images Docker
Write-Host "Suppression des images Docker..." -ForegroundColor Yellow
docker rmi dog-breed-identifier 2>$null
docker rmi dog-breed-identifier-test 2>$null

# Nettoyer les volumes Docker
Write-Host "Nettoyage des volumes Docker..." -ForegroundColor Yellow
docker volume prune -f 2>$null

# Supprimer les fichiers de cache Python
Write-Host "Suppression des fichiers de cache Python..." -ForegroundColor Yellow
Get-ChildItem -Path . -Include __pycache__ -Recurse | Remove-Item -Recurse -Force
Get-ChildItem -Path . -Include *.pyc -Recurse | Remove-Item -Force

# Supprimer les fichiers de test media
Write-Host "Suppression des fichiers de test media..." -ForegroundColor Yellow
if (Test-Path "tests/test_media") {
    Remove-Item -Path "tests/test_media" -Recurse -Force
}

Write-Host "Nettoyage terminé !" -ForegroundColor Green