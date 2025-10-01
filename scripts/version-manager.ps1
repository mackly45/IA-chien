# Script de gestion de version

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "show",
    
    [Parameter(Mandatory=$false)]
    [string]$NewVersion,
    
    [Parameter(Mandatory=$false)]
    [switch]$Tag = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Push = $false
)

Write-Host "Gestion de version de Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Fonction pour lire la version actuelle
function Get-CurrentVersion {
    # Chercher la version dans différents fichiers possibles
    $versionFiles = @(
        "setup.py",
        "dog_breed_identifier/__init__.py",
        "package.json"
    )
    
    foreach ($file in $versionFiles) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            if ($content -match 'version\s*=\s*["'']([^"'']+)["'']') {
                return $matches[1]
            }
        }
    }
    
    # Si aucune version trouvée, retourner une version par défaut
    return "0.0.0"
}

# Fonction pour mettre à jour la version
function Update-Version {
    param([string]$OldVersion, [string]$NewVersion)
    
    Write-Host "Mise à jour de la version $OldVersion vers $NewVersion..." -ForegroundColor Yellow
    
    $versionFiles = @(
        "setup.py",
        "dog_breed_identifier/__init__.py",
        "package.json"
    )
    
    $updatedFiles = 0
    
    foreach ($file in $versionFiles) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            $newContent = $content -replace "version\s*=\s*[`"']$OldVersion[`"']", "version=`"$NewVersion`""
            
            if ($content -ne $newContent) {
                Set-Content $file $newContent
                Write-Host "✅ Mise à jour: $file" -ForegroundColor Green
                $updatedFiles++
            }
        }
    }
    
    if ($updatedFiles -eq 0) {
        Write-Host "⚠️  Aucun fichier de version mis à jour" -ForegroundColor Yellow
    }
    
    return $updatedFiles -gt 0
}

# Fonction pour créer un tag Git
function Create-GitTag {
    param([string]$Version)
    
    Write-Host "Création du tag Git v$Version..." -ForegroundColor Yellow
    
    try {
        git tag -a "v$Version" -m "Version $Version"
        Write-Host "✅ Tag Git créé: v$Version" -ForegroundColor Green
        
        if ($Push) {
            git push origin "v$Version"
            Write-Host "✅ Tag poussé vers le dépôt distant" -ForegroundColor Green
        }
        
        return $true
    } catch {
        Write-Host "❌ Échec de la création du tag Git: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour valider le format de version
function Validate-VersionFormat {
    param([string]$Version)
    
    # Format sémantique: X.Y.Z ou X.Y.Z-prerelease
    return $Version -match "^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$"
}

# Exécuter l'action demandée
switch ($Action.ToLower()) {
    "show" {
        $currentVersion = Get-CurrentVersion
        Write-Host "Version actuelle: $currentVersion" -ForegroundColor White
    }
    
    "update" {
        if (-not $NewVersion) {
            Write-Host "❌ Version requise pour l'action 'update'" -ForegroundColor Red
            exit 1
        }
        
        if (-not (Validate-VersionFormat -Version $NewVersion)) {
            Write-Host "❌ Format de version invalide. Utilisez X.Y.Z ou X.Y.Z-prerelease" -ForegroundColor Red
            exit 1
        }
        
        $currentVersion = Get-CurrentVersion
        Write-Host "Version actuelle: $currentVersion" -ForegroundColor White
        Write-Host "Nouvelle version: $NewVersion" -ForegroundColor White
        
        if ($currentVersion -eq $NewVersion) {
            Write-Host "⚠️  La version est déjà à jour" -ForegroundColor Yellow
            exit 0
        }
        
        # Mettre à jour la version
        if (Update-Version -OldVersion $currentVersion -NewVersion $NewVersion) {
            # Commiter les changements
            git add .
            git commit -m "Mise à jour de la version $currentVersion vers $NewVersion"
            Write-Host "✅ Changements commités" -ForegroundColor Green
            
            # Créer un tag si demandé
            if ($Tag) {
                Create-GitTag -Version $NewVersion
            }
            
            # Pousser les changements si demandé
            if ($Push) {
                git push origin HEAD
                Write-Host "✅ Changements poussés vers le dépôt distant" -ForegroundColor Green
            }
            
            Write-Host "✅ Version mise à jour avec succès !" -ForegroundColor Green
        } else {
            Write-Host "❌ Échec de la mise à jour de la version" -ForegroundColor Red
            exit 1
        }
    }
    
    "bump" {
        $currentVersion = Get-CurrentVersion
        Write-Host "Version actuelle: $currentVersion" -ForegroundColor White
        
        # Parser la version actuelle
        if ($currentVersion -match "^(\d+)\.(\d+)\.(\d+)(-.+)?$") {
            $major = [int]$matches[1]
            $minor = [int]$matches[2]
            $patch = [int]$matches[3]
            $prerelease = $matches[4]
            
            # Déterminer le type de bump
            switch ($NewVersion.ToLower()) {
                "major" {
                    $major++
                    $minor = 0
                    $patch = 0
                    $prerelease = ""
                }
                
                "minor" {
                    $minor++
                    $patch = 0
                    $prerelease = ""
                }
                
                "patch" {
                    $patch++
                    $prerelease = ""
                }
                
                default {
                    Write-Host "❌ Type de bump invalide. Utilisez 'major', 'minor', ou 'patch'" -ForegroundColor Red
                    exit 1
                }
            }
            
            $newVersion = "$major.$minor.$patch$prerelease"
            
            Write-Host "Nouvelle version: $newVersion" -ForegroundColor White
            
            # Mettre à jour la version
            if (Update-Version -OldVersion $currentVersion -NewVersion $newVersion) {
                # Commiter les changements
                git add .
                git commit -m "Bump version $currentVersion vers $newVersion"
                Write-Host "✅ Changements commités" -ForegroundColor Green
                
                # Créer un tag si demandé
                if ($Tag) {
                    Create-GitTag -Version $newVersion
                }
                
                # Pousser les changements si demandé
                if ($Push) {
                    git push origin HEAD
                    Write-Host "✅ Changements poussés vers le dépôt distant" -ForegroundColor Green
                }
                
                Write-Host "✅ Version bumpée avec succès !" -ForegroundColor Green
            } else {
                Write-Host "❌ Échec du bump de version" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "❌ Impossible de parser la version actuelle: $currentVersion" -ForegroundColor Red
            exit 1
        }
    }
    
    default {
        Write-Host "❌ Action non supportée: $Action" -ForegroundColor Red
        Write-Host "Actions supportées: show, update, bump" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Gestion de version terminée !" -ForegroundColor Cyan