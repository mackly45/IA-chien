# Script PowerShell pour exécuter tous les tests du projet

Write-Host "=== Tests du Projet Dog Breed Identifier ===" -ForegroundColor Cyan

# Construire l'image de test
Write-Host "Construction de l'image de test..." -ForegroundColor Yellow
docker build -t dog-breed-identifier-test -f Dockerfile.test .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Échec de la construction de l'image de test !" -ForegroundColor Red
    exit 1
}

# Exécuter les tests
Write-Host "Exécution des tests..." -ForegroundColor Yellow
docker run --rm `
  -v "${pwd}/tests:/app/tests" `
  dog-breed-identifier-test

if ($LASTEXITCODE -ne 0) {
    Write-Host "Certains tests ont échoué !" -ForegroundColor Red
    exit 1
}

Write-Host "Tous les tests ont réussi !" -ForegroundColor Green