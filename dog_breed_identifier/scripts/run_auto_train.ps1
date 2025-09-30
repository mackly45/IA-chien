# Script PowerShell pour exécuter l'entraînement automatique du modèle

# Définir le répertoire du projet
$ProjectDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ProjectDir = Split-Path -Parent -Path $ProjectDir

# Se déplacer dans le répertoire du projet
Set-Location -Path $ProjectDir

# Activer l'environnement virtuel si disponible
if (Test-Path -Path "venv\Scripts\Activate.ps1") {
    . "venv\Scripts\Activate.ps1"
} elseif (Test-Path -Path ".venv\Scripts\Activate.ps1") {
    . ".venv\Scripts\Activate.ps1"
}

# Exécuter l'entraînement automatique
Write-Host "Exécution de l'entraînement automatique..."
python manage.py auto_train --images-per-breed 3

Write-Host "Entraînement automatique terminé."