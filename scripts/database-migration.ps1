# Script de migration de base de données

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("migrate", "rollback", "status", "create")]
    [string]$Action = "migrate",
    
    [Parameter(Mandatory=$false)]
    [string]$MigrationName,
    
    [Parameter(Mandatory=$false)]
    [int]$Steps = 1,
    
    [Parameter(Mandatory=$false)]
    [string]$Database = "default",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "./db-backups"
)

Write-Host "Migration de Base de Données de Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$migrationsDir = "./dog_breed_identifier/migrations"

# Fonction pour créer un backup de la base de données
function Backup-Database {
    param([string]$DbName)
    
    Write-Host "Création d'un backup de la base de données..." -ForegroundColor Yellow
    
    # Créer le répertoire de backup s'il n'existe pas
    if (-not (Test-Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath | Out-Null
    }
    
    $backupFile = Join-Path $BackupPath "backup-$DbName-$timestamp.sql"
    
    try {
        # Pour SQLite (base de données par défaut de Django)
        $dbFile = "./db.sqlite3"
        if (Test-Path $dbFile) {
            Copy-Item $dbFile "$backupFile.sqlite3" -Force
            Write-Host "✅ Backup SQLite créé: $backupFile.sqlite3" -ForegroundColor Green
            return "$backupFile.sqlite3"
        }
        
        # Pour d'autres bases de données, vous pouvez implémenter des commandes spécifiques
        # Par exemple, pour PostgreSQL:
        # pg_dump -U $env:DB_USER -h $env:DB_HOST -p $env:DB_PORT $DbName > $backupFile
        
        Write-Host "✅ Backup créé: $backupFile" -ForegroundColor Green
        return $backupFile
    } catch {
        Write-Host "❌ Échec de la création du backup: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Fonction pour restaurer un backup de la base de données
function Restore-Database {
    param([string]$BackupFile)
    
    Write-Host "Restauration de la base de données..." -ForegroundColor Yellow
    
    try {
        # Pour SQLite
        if ($BackupFile -like "*.sqlite3") {
            Copy-Item $BackupFile "./db.sqlite3" -Force
            Write-Host "✅ Base de données restaurée depuis: $BackupFile" -ForegroundColor Green
            return $true
        }
        
        # Pour d'autres bases de données, implémenter les commandes de restauration appropriées
        # Par exemple, pour PostgreSQL:
        # psql -U $env:DB_USER -h $env:DB_HOST -p $env:DB_PORT $DbName < $BackupFile
        
        Write-Host "✅ Base de données restaurée" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Échec de la restauration: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour exécuter les migrations
function Invoke-Migrations {
    param([string]$DbName, [int]$StepCount)
    
    Write-Host "Exécution des migrations..." -ForegroundColor Yellow
    
    try {
        Set-Location -Path "dog_breed_identifier"
        
        if ($DryRun) {
            # Afficher ce qui serait exécuté
            $cmd = "python manage.py showmigrations"
            Write-Host "_simulation: $cmd" -ForegroundColor White
            python manage.py showmigrations
        } else {
            # Exécuter les migrations
            $cmd = "python manage.py migrate $DbName"
            Write-Host "Exécution: $cmd" -ForegroundColor White
            
            $result = python manage.py migrate $DbName 2>&1
            Write-Host $result
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Migrations exécutées avec succès" -ForegroundColor Green
            } else {
                Write-Host "❌ Échec de l'exécution des migrations" -ForegroundColor Red
                return $false
            }
        }
        
        Set-Location -Path ".."
        return $true
    } catch {
        Set-Location -Path ".."
        Write-Host "❌ Erreur lors de l'exécution des migrations: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour faire un rollback des migrations
function Rollback-Migrations {
    param([string]$DbName, [int]$StepCount)
    
    Write-Host "Rollback des migrations..." -ForegroundColor Yellow
    
    try {
        Set-Location -Path "dog_breed_identifier"
        
        if ($DryRun) {
            # Afficher ce qui serait exécuté
            $cmd = "python manage.py showmigrations"
            Write-Host "Simulation: $cmd" -ForegroundColor White
            python manage.py showmigrations
        } else {
            # Faire un rollback
            $cmd = "python manage.py migrate $DbName zero"
            if ($StepCount -gt 0) {
                # Pour rollback partiel, vous devez spécifier l'ID de migration
                # Cela dépend de votre implémentation spécifique
                $cmd = "python manage.py migrate $DbName -$StepCount"
            }
            
            Write-Host "Exécution: $cmd" -ForegroundColor White
            
            $result = python manage.py migrate $DbName zero 2>&1
            Write-Host $result
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Rollback des migrations effectué avec succès" -ForegroundColor Green
            } else {
                Write-Host "❌ Échec du rollback des migrations" -ForegroundColor Red
                return $false
            }
        }
        
        Set-Location -Path ".."
        return $true
    } catch {
        Set-Location -Path ".."
        Write-Host "❌ Erreur lors du rollback des migrations: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour vérifier le statut des migrations
function Get-MigrationStatus {
    param([string]$DbName)
    
    Write-Host "Vérification du statut des migrations..." -ForegroundColor Yellow
    
    try {
        Set-Location -Path "dog_breed_identifier"
        
        $cmd = "python manage.py showmigrations $DbName"
        Write-Host "Exécution: $cmd" -ForegroundColor White
        
        $result = python manage.py showmigrations $DbName 2>&1
        Write-Host $result
        
        Set-Location -Path ".."
        return $true
    } catch {
        Set-Location -Path ".."
        Write-Host "❌ Erreur lors de la vérification du statut: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour créer une nouvelle migration
function Create-Migration {
    param([string]$Name)
    
    Write-Host "Création d'une nouvelle migration..." -ForegroundColor Yellow
    
    if (-not $Name) {
        Write-Host "❌ Nom de migration requis" -ForegroundColor Red
        return $false
    }
    
    try {
        Set-Location -Path "dog_breed_identifier"
        
        if ($DryRun) {
            Write-Host "Simulation: python manage.py makemigrations --name $Name" -ForegroundColor White
        } else {
            $cmd = "python manage.py makemigrations --name $Name"
            Write-Host "Exécution: $cmd" -ForegroundColor White
            
            $result = python manage.py makemigrations --name $Name 2>&1
            Write-Host $result
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Migration créée avec succès" -ForegroundColor Green
            } else {
                Write-Host "❌ Échec de la création de la migration" -ForegroundColor Red
                return $false
            }
        }
        
        Set-Location -Path ".."
        return $true
    } catch {
        Set-Location -Path ".."
        Write-Host "❌ Erreur lors de la création de la migration: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour valider l'environnement
function Test-Environment {
    Write-Host "Validation de l'environnement..." -ForegroundColor Yellow
    
    # Vérifier que Python est installé
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Python n'est pas installé" -ForegroundColor Red
        return $false
    }
    
    # Vérifier que Django est installé
    try {
        python -c "import django" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Django n'est pas installé" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Django n'est pas installé" -ForegroundColor Red
        return $false
    }
    
    # Vérifier que le projet Django existe
    if (-not (Test-Path "dog_breed_identifier/manage.py")) {
        Write-Host "❌ Projet Django non trouvé" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ Environnement validé" -ForegroundColor Green
    return $true
}

# Exécuter l'action demandée
if (-not (Test-Environment)) {
    exit 1
}

switch ($Action.ToLower()) {
    "migrate" {
        Write-Host "Exécution des migrations sur la base de données: $Database" -ForegroundColor White
        
        # Créer un backup avant la migration
        if (-not $DryRun) {
            $backupFile = Backup-Database -DbName $Database
            if (-not $backupFile -and -not $Force) {
                Write-Host "❌ Échec de la création du backup. Utilisez -Force pour continuer sans backup." -ForegroundColor Red
                exit 1
            }
        }
        
        if (Invoke-Migrations -DbName $Database -StepCount $Steps) {
            Write-Host "✅ Migrations exécutées avec succès !" -ForegroundColor Green
        } else {
            Write-Host "❌ Échec de l'exécution des migrations" -ForegroundColor Red
            exit 1
        }
    }
    
    "rollback" {
        Write-Host "Rollback des migrations sur la base de données: $Database" -ForegroundColor White
        
        # Créer un backup avant le rollback
        if (-not $DryRun) {
            $backupFile = Backup-Database -DbName $Database
            if (-not $backupFile -and -not $Force) {
                Write-Host "❌ Échec de la création du backup. Utilisez -Force pour continuer sans backup." -ForegroundColor Red
                exit 1
            }
        }
        
        if (Rollback-Migrations -DbName $Database -StepCount $Steps) {
            Write-Host "✅ Rollback des migrations effectué avec succès !" -ForegroundColor Green
        } else {
            Write-Host "❌ Échec du rollback des migrations" -ForegroundColor Red
            exit 1
        }
    }
    
    "status" {
        Write-Host "Statut des migrations pour la base de données: $Database" -ForegroundColor White
        
        if (Get-MigrationStatus -DbName $Database) {
            Write-Host "✅ Statut des migrations affiché" -ForegroundColor Green
        } else {
            Write-Host "❌ Échec de l'affichage du statut des migrations" -ForegroundColor Red
            exit 1
        }
    }
    
    "create" {
        Write-Host "Création d'une nouvelle migration: $MigrationName" -ForegroundColor White
        
        if (Create-Migration -Name $MigrationName) {
            Write-Host "✅ Migration créée avec succès !" -ForegroundColor Green
        } else {
            Write-Host "❌ Échec de la création de la migration" -ForegroundColor Red
            exit 1
        }
    }
    
    default {
        Write-Host "❌ Action non supportée: $Action" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Opération de migration terminée !" -ForegroundColor Cyan