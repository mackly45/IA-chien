# Script de déploiement automatique pour Windows PowerShell

Write-Host "Début du déploiement automatique..." -ForegroundColor Green

# Mise à jour du numéro de version
Write-Host "Mise à jour du numéro de version..." -ForegroundColor Yellow
python scripts/update_version.py

# Récupération de la nouvelle version
$VERSION = Get-Content VERSION
Write-Host "Version actuelle : $VERSION" -ForegroundColor Yellow

# Ajout des fichiers modifiés
Write-Host "Ajout des fichiers modifiés..." -ForegroundColor Yellow
git add .

# Commit avec message automatique
Write-Host "Création du commit..." -ForegroundColor Yellow
$DATE = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git commit -m "Mise à jour automatique de la version : $VERSION - $DATE"

# Push vers le dépôt distant
Write-Host "Push vers le dépôt distant..." -ForegroundColor Yellow
git push origin main

Write-Host "Déploiement terminé ! La nouvelle version $VERSION est en cours de déploiement." -ForegroundColor Green