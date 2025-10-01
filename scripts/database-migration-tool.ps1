# Script d'outils de migration de base de données

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "migrate",
    
    [Parameter(Mandatory=$false)]
    [string]$Database = "default",
    
    [Parameter(Mandatory=$false)]
    [string]$MigrationName = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

Write-Host "Outils de migration de base de données" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$djangoProjectDir = "./dog_breed_identifier"
$managePy = Join-Path $djangoProjectDir "manage.py"
$migrationsDir = Join-Path $djangoProjectDir "classifier" "migrations"

# Fonction pour afficher les messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Level) {
        "INFO" { Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor White }
        "WARN" { Write-Host "[$timestamp] [WARN] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor Red }
        "SUCCESS" { Write-Host "[$timestamp] [SUCCESS] $Message" -ForegroundColor Green }
    }
}

# Fonction pour exécuter une commande Django
function Invoke-DjangoCommand {
    param([string]$Command, [string]$Description)
    
    Write-Log "Exécution: $Description" "INFO"
    
    if ($Verbose) {
        Write-Host "Commande: python $managePy $Command" -ForegroundColor Gray
    }
    
    try {
        if ($DryRun) {
            Write-Log "Mode dry-run - commande non exécutée" "WARN"
            return $true
        }
        
        $output = python $managePy $Command 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Succès: $Description" "SUCCESS"
            if ($Verbose -and $output) {
                Write-Host $output -ForegroundColor Gray
            }
            return $true
        } else {
            Write-Log "Échec: $Description" "ERROR"
            if ($output) {
                Write-Host $output -ForegroundColor Red
            }
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exécution: $Description - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Vérifier que le projet Django existe
if (-not (Test-Path $djangoProjectDir)) {
    Write-Log "Répertoire du projet Django non trouvé: $djangoProjectDir" "ERROR"
    exit 1
}

if (-not (Test-Path $managePy)) {
    Write-Log "Script manage.py non trouvé: $managePy" "ERROR"
    exit 1
}

# Vérifier que Python est disponible
try {
    $pythonVersion = python --version 2>&1
    Write-Log "Python disponible: $pythonVersion" "SUCCESS"
} catch {
    Write-Log "Python non trouvé. Veuillez installer Python." "ERROR"
    exit 1
}

# Exécuter l'action demandée
switch ($Action.ToLower()) {
    "migrate" {
        Write-Log "Exécution des migrations pour la base de données: $Database" "INFO"
        
        if ($MigrationName) {
            # Appliquer une migration spécifique
            $command = "migrate $Database $MigrationName"
            $description = "Migration $MigrationName sur la base de données $Database"
        } else {
            # Appliquer toutes les migrations
            $command = "migrate $Database"
            $description = "Toutes les migrations sur la base de données $Database"
        }
        
        $result = Invoke-DjangoCommand -Command $command -Description $description
        if ($result) {
            Write-Log "Migrations appliquées avec succès" "SUCCESS"
        } else {
            Write-Log "Échec de l'application des migrations" "ERROR"
            exit 1
        }
    }
    
    "makemigrations" {
        Write-Log "Création des migrations pour l'application classifier" "INFO"
        
        if ($MigrationName) {
            $command = "makemigrations classifier --name $MigrationName"
            $description = "Création de la migration '$MigrationName' pour classifier"
        } else {
            $command = "makemigrations classifier"
            $description = "Création des migrations pour classifier"
        }
        
        $result = Invoke-DjangoCommand -Command $command -Description $description
        if ($result) {
            Write-Log "Migrations créées avec succès" "SUCCESS"
        } else {
            Write-Log "Échec de la création des migrations" "ERROR"
            exit 1
        }
    }
    
    "showmigrations" {
        Write-Log "Affichage des migrations pour la base de données: $Database" "INFO"
        
        $command = "showmigrations $Database"
        $description = "Affichage des migrations pour la base de données $Database"
        
        $result = Invoke-DjangoCommand -Command $command -Description $description
        if (-not $result) {
            Write-Log "Échec de l'affichage des migrations" "ERROR"
            exit 1
        }
    }
    
    "sqlmigrate" {
        if (-not $MigrationName) {
            Write-Log "Nom de migration requis pour l'action 'sqlmigrate'" "ERROR"
            exit 1
        }
        
        Write-Log "Génération du SQL pour la migration: $MigrationName" "INFO"
        
        $command = "sqlmigrate classifier $MigrationName"
        $description = "Génération du SQL pour la migration $MigrationName"
        
        $result = Invoke-DjangoCommand -Command $command -Description $description
        if (-not $result) {
            Write-Log "Échec de la génération du SQL" "ERROR"
            exit 1
        }
    }
    
    "rollback" {
        if (-not $MigrationName) {
            Write-Log "Nom de migration requis pour l'action 'rollback'" "ERROR"
            exit 1
        }
        
        Write-Log "Retour arrière de la migration: $MigrationName" "INFO"
        
        $command = "migrate classifier zero"
        $description = "Retour arrière de toutes les migrations"
        
        # D'abord, trouver la migration précédente
        try {
            $output = python $managePy showmigrations classifier --plan 2>&1
            Write-Host $output -ForegroundColor Gray
        } catch {
            Write-Log "Impossible de déterminer les migrations précédentes" "WARN"
        }
        
        if (-not $DryRun) {
            $confirmation = Read-Host "Êtes-vous sûr de vouloir effectuer ce retour arrière ? (yes/no)"
            if ($confirmation -ne "yes") {
                Write-Log "Retour arrière annulé par l'utilisateur" "INFO"
                exit 0
            }
        }
        
        $result = Invoke-DjangoCommand -Command $command -Description $description
        if ($result) {
            Write-Log "Retour arrière effectué avec succès" "SUCCESS"
        } else {
            Write-Log "Échec du retour arrière" "ERROR"
            exit 1
        }
    }
    
    default {
        Write-Log "Action non reconnue: $Action" "ERROR"
        Write-Log "Actions disponibles: migrate, makemigrations, showmigrations, sqlmigrate, rollback" "INFO"
        exit 1
    }
}

Write-Log "Opération de migration terminée !" "SUCCESS"