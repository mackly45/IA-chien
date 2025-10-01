# Script de validation de la configuration

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigDir = "./config",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvFile = ".env",
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckDjango = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckDatabase = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$CheckSecrets = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

Write-Host "Validation de la configuration" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$requiredConfigFiles = @(
    "./dog_breed_identifier/dog_identifier/settings.py",
    "./requirements.txt",
    "./Dockerfile",
    "./docker-compose.yml"
)

$requiredEnvVars = @(
    "SECRET_KEY",
    "DEBUG"
)

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

# Fonction pour vérifier l'existence des fichiers
function Test-ConfigFiles {
    param([array]$Files)
    
    Write-Log "Vérification des fichiers de configuration..." "INFO"
    $missingFiles = @()
    $foundFiles = @()
    
    foreach ($file in $Files) {
        if (Test-Path $file) {
            $foundFiles += $file
            Write-Log "Fichier trouvé: $file" "SUCCESS"
        } else {
            $missingFiles += $file
            Write-Log "Fichier manquant: $file" "ERROR"
        }
    }
    
    return @{
        Missing = $missingFiles
        Found = $foundFiles
    }
}

# Fonction pour vérifier les variables d'environnement
function Test-EnvironmentVariables {
    param([array]$Variables, [string]$EnvFilePath)
    
    Write-Log "Vérification des variables d'environnement..." "INFO"
    $missingVars = @()
    $foundVars = @()
    
    # Charger les variables depuis le fichier .env si il existe
    $envVars = @{}
    if (Test-Path $EnvFilePath) {
        $envContent = Get-Content $EnvFilePath
        foreach ($line in $envContent) {
            if ($line -match "^([A-Za-z_][A-Za-z0-9_]*)=(.*)$") {
                $key = $matches[1]
                $value = $matches[2]
                $envVars[$key] = $value
            }
        }
    }
    
    # Vérifier chaque variable requise
    foreach ($var in $Variables) {
        # Vérifier d'abord dans les variables d'environnement système
        if (Test-Path "env:$var") {
            $foundVars += $var
            Write-Log "Variable système trouvée: $var" "SUCCESS"
        }
        # Ensuite vérifier dans le fichier .env
        elseif ($envVars.ContainsKey($var)) {
            $foundVars += $var
            Write-Log "Variable .env trouvée: $var" "SUCCESS"
        }
        # Sinon, variable manquante
        else {
            $missingVars += $var
            Write-Log "Variable manquante: $var" "ERROR"
        }
    }
    
    return @{
        Missing = $missingVars
        Found = $foundVars
    }
}

# Fonction pour valider la configuration Django
function Test-DjangoConfig {
    Write-Log "Vérification de la configuration Django..." "INFO"
    
    try {
        # Vérifier que Django est installé
        python -c "import django" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Django est installé" "SUCCESS"
        } else {
            Write-Log "Django n'est pas installé" "ERROR"
            return $false
        }
        
        # Vérifier la configuration Django
        python -c "
import sys
import os
sys.path.append('./dog_breed_identifier')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
try:
    import django
    django.setup()
    from django.conf import settings
    print('SECRET_KEY defined:', hasattr(settings, 'SECRET_KEY') and bool(settings.SECRET_KEY))
    print('DEBUG defined:', hasattr(settings, 'DEBUG'))
    print('DATABASES defined:', hasattr(settings, 'DATABASES') and bool(settings.DATABASES))
except Exception as e:
    print('Error:', str(e))
" 2>&1 | ForEach-Object {
            if ($_ -match "SECRET_KEY defined: True") {
                Write-Log "SECRET_KEY configurée correctement" "SUCCESS"
            }
            elseif ($_ -match "SECRET_KEY defined: False") {
                Write-Log "SECRET_KEY non configurée" "ERROR"
            }
            elseif ($_ -match "DEBUG defined: True") {
                Write-Log "DEBUG configuré" "SUCCESS"
            }
            elseif ($_ -match "DATABASES defined: True") {
                Write-Log "DATABASES configuré" "SUCCESS"
            }
            elseif ($_ -match "Error:") {
                Write-Log "Erreur de configuration Django: $_" "ERROR"
            }
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors de la vérification de Django: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Fonction pour valider la configuration de la base de données
function Test-DatabaseConfig {
    Write-Log "Vérification de la configuration de la base de données..." "INFO"
    
    try {
        # Vérifier la configuration de la base de données
        python -c "
import sys
import os
sys.path.append('./dog_breed_identifier')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
try:
    import django
    django.setup()
    from django.conf import settings
    db_config = settings.DATABASES.get('default', {})
    print('Engine:', db_config.get('ENGINE', 'Not set'))
    print('Name:', db_config.get('NAME', 'Not set'))
    print('User:', db_config.get('USER', 'Not set'))
    print('Host:', db_config.get('HOST', 'Not set'))
    print('Port:', db_config.get('PORT', 'Not set'))
except Exception as e:
    print('Error:', str(e))
" 2>&1 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        
        Write-Log "Configuration de la base de données vérifiée" "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de la vérification de la base de données: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Fonction pour vérifier les secrets
function Test-Secrets {
    Write-Log "Vérification des secrets..." "INFO"
    
    # Vérifier le fichier .env
    if (Test-Path ".env") {
        $envContent = Get-Content ".env"
        $hasSecretKey = $false
        $hasSecretValue = $false
        
        foreach ($line in $envContent) {
            if ($line -match "^SECRET_KEY=") {
                $hasSecretKey = $true
                $secretValue = $line -replace "^SECRET_KEY=", ""
                if ($secretValue -and $secretValue -ne "your-secret-key-here") {
                    $hasSecretValue = $true
                }
            }
        }
        
        if ($hasSecretKey) {
            Write-Log "SECRET_KEY trouvée dans .env" "SUCCESS"
            if ($hasSecretValue) {
                Write-Log "SECRET_KEY a une valeur définie" "SUCCESS"
            } else {
                Write-Log "SECRET_KEY n'a pas de valeur définie" "WARN"
            }
        } else {
            Write-Log "SECRET_KEY non trouvée dans .env" "WARN"
        }
    } else {
        Write-Log "Fichier .env non trouvé" "WARN"
    }
    
    # Vérifier .env.local (devrait contenir les vrais secrets)
    if (Test-Path ".env.local") {
        Write-Log "Fichier .env.local trouvé (bonne pratique)" "SUCCESS"
    } else {
        Write-Log "Fichier .env.local non trouvé (recommandé pour les secrets)" "INFO"
    }
    
    return $true
}

# Exécuter les validations
Write-Log "Démarrage de la validation de la configuration..." "INFO"

# Vérifier les fichiers de configuration
$fileCheck = Test-ConfigFiles -Files $requiredConfigFiles
$fileIssues = $fileCheck.Missing.Count

# Vérifier les variables d'environnement
$envCheck = Test-EnvironmentVariables -Variables $requiredEnvVars -EnvFilePath $EnvFile
$envIssues = $envCheck.Missing.Count

# Vérifier la configuration Django si demandé
$djangoValid = $true
if ($CheckDjango) {
    $djangoValid = Test-DjangoConfig
}

# Vérifier la configuration de la base de données si demandé
$dbValid = $true
if ($CheckDatabase) {
    $dbValid = Test-DatabaseConfig
}

# Vérifier les secrets si demandé
$secretsValid = $true
if ($CheckSecrets) {
    $secretsValid = Test-Secrets
}

# Afficher le résumé
Write-Host "`nRésumé de la validation:" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host "Fichiers de configuration manquants: $fileIssues" -ForegroundColor $(if ($fileIssues -eq 0) { "Green" } else { "Red" })
Write-Host "Variables d'environnement manquantes: $envIssues" -ForegroundColor $(if ($envIssues -eq 0) { "Green" } else { "Red" })
Write-Host "Configuration Django valide: $(if ($djangoValid) { "Oui" } else { "Non" })" -ForegroundColor $(if ($djangoValid) { "Green" } else { "Red" })
Write-Host "Configuration base de données valide: $(if ($dbValid) { "Oui" } else { "Non" })" -ForegroundColor $(if ($dbValid) { "Green" } else { "Red" })
Write-Host "Vérification des secrets: $(if ($secretsValid) { "Effectuée" } else { "Non effectuée" })" -ForegroundColor $(if ($secretsValid) { "Green" } else { "Red" })

# Déterminer le statut global
$globalValid = ($fileIssues -eq 0) -and ($envIssues -eq 0) -and $djangoValid -and $dbValid -and $secretsValid

if ($globalValid) {
    Write-Host "`n✅ Configuration validée avec succès !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ Problèmes de configuration détectés" -ForegroundColor Red
    exit 1
}