# Script de génération de CHANGELOG

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "./CHANGELOG.md",
    
    [Parameter(Mandatory=$false)]
    [string]$SinceTag,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeUnreleased = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$FromGitLog = $false
)

Write-Host "Génération du CHANGELOG" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

# Fonction pour obtenir les commits Git
function Get-GitCommits {
    param([string]$Since)
    
    $gitCommand = "git log --pretty=format:`"%H|%an|%ad|%s`" --date=short"
    
    if ($Since) {
        $gitCommand += " $Since..HEAD"
    }
    
    try {
        $commits = Invoke-Expression $gitCommand | ForEach-Object {
            if ($_ -match "^([^|]+)\|([^|]+)\|([^|]+)\|(.+)$") {
                @{
                    Hash = $matches[1]
                    Author = $matches[2]
                    Date = $matches[3]
                    Message = $matches[4]
                }
            }
        }
        
        return $commits
    } catch {
        Write-Host "❌ Échec de la récupération des commits Git: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Fonction pour catégoriser les commits
function Categorize-Commits {
    param([array]$Commits)
    
    $categorized = @{
        Features = @()
        Fixes = @()
        Changes = @()
        Documentation = @()
        Tests = @()
        Other = @()
    }
    
    foreach ($commit in $Commits) {
        $message = $commit.Message.ToLower()
        
        if ($message -match "^(add|feat|feature)" -or $message -match "ajout") {
            $categorized.Features += $commit
        } elseif ($message -match "^(fix|bug)" -or $message -match "corrige") {
            $categorized.Fixes += $commit
        } elseif ($message -match "^(docs|doc|documentation)" -or $message -match "documentation") {
            $categorized.Documentation += $commit
        } elseif ($message -match "^(test|tests)" -or $message -match "test") {
            $categorized.Tests += $commit
        } elseif ($message -match "^(change|update|modify)" -or $message -match "modifie") {
            $categorized.Changes += $commit
        } else {
            $categorized.Other += $commit
        }
    }
    
    return $categorized
}

# Fonction pour générer le contenu du CHANGELOG
function Generate-ChangelogContent {
    param(
        [hashtable]$CategorizedCommits,
        [string]$Version,
        [string]$Date
    )
    
    $content = ""
    
    if ($Version -and $Date) {
        $content += "## [$Version] - $Date`n`n"
    } elseif ($IncludeUnreleased) {
        $content += "## [Unreleased]`n`n"
    }
    
    # Fonction pour ajouter une section
    function Add-Section {
        param([string]$Title, [array]$Commits)
        
        if ($Commits.Count -gt 0) {
            $content += "### $Title`n`n"
            foreach ($commit in $Commits) {
                # Formater le message en enlevant le type de commit s'il est présent
                $message = $commit.Message
                $message = $message -replace "^(add|feat|feature|fix|bug|docs|doc|documentation|test|tests|change|update|modify):\s*", ""
                $message = $message -replace "^(ajout|corrige|documentation|test|modifie):\s*", ""
                
                $content += "- $message ($($commit.Author))`n"
            }
            $content += "`n"
        }
    }
    
    # Ajouter les sections
    Add-Section -Title "Added" -Commits $CategorizedCommits.Features
    Add-Section -Title "Fixed" -Commits $CategorizedCommits.Fixes
    Add-Section -Title "Changed" -Commits $CategorizedCommits.Changes
    Add-Section -Title "Documentation" -Commits $CategorizedCommits.Documentation
    Add-Section -Title "Tests" -Commits $CategorizedCommits.Tests
    Add-Section -Title "Other" -Commits $CategorizedCommits.Other
    
    return $content
}

# Fonction pour obtenir les tags Git
function Get-GitTags {
    try {
        $tags = git tag --sort=-v:refname
        return $tags
    } catch {
        Write-Host "❌ Échec de la récupération des tags Git: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Générer le CHANGELOG
if ($FromGitLog) {
    # Obtenir les commits
    $commits = Get-GitCommits -Since $SinceTag
    
    if ($commits.Count -eq 0) {
        Write-Host "❌ Aucun commit trouvé" -ForegroundColor Red
        exit 1
    }
    
    # Catégoriser les commits
    $categorized = Categorize-Commits -Commits $commits
    
    # Obtenir la version actuelle
    $version = "Unreleased"
    try {
        $version = git describe --tags --abbrev=0 2>$null
        if (-not $version) {
            $version = "Unreleased"
        }
    } catch {
        $version = "Unreleased"
    }
    
    # Générer le contenu
    $date = Get-Date -Format "yyyy-MM-dd"
    $changelogContent = Generate-ChangelogContent -CategorizedCommits $categorized -Version $version -Date $date
    
    # Lire le CHANGELOG existant s'il existe
    $existingContent = ""
    if (Test-Path $OutputFile) {
        $existingContent = Get-Content $OutputFile -Raw
    }
    
    # Combiner le contenu
    $finalContent = "# Changelog`n`n"
    $finalContent += "Toutes les modifications notables apportées à ce projet seront documentées dans ce fichier.`n`n"
    $finalContent += "Le format est basé sur [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),`n"
    $finalContent += "et ce projet adhère au [Versioning sémantique](https://semver.org/spec/v2.0.0.html).`n`n"
    
    if ($existingContent) {
        # Insérer le nouveau contenu après l'en-tête
        $lines = $existingContent -split "`n"
        $finalContent = $lines[0..2] -join "`n"  # En-tête
        $finalContent += "`n" + $changelogContent
        
        # Ajouter le reste du contenu existant
        if ($lines.Count -gt 3) {
            $finalContent += $lines[3..($lines.Count - 1)] -join "`n"
        }
    } else {
        $finalContent += $changelogContent
    }
    
    # Écrire le fichier
    Set-Content -Path $OutputFile -Value $finalContent
    
    Write-Host "✅ CHANGELOG généré: $OutputFile" -ForegroundColor Green
} else {
    # Générer un template de CHANGELOG
    $templateContent = @"
# Changelog

Toutes les modifications notables apportées à ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
et ce projet adhère au [Versioning sémantique](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- 

### Changed
- 

### Fixed
- 

### Removed
- 

## [1.0.0] - $(Get-Date -Format "yyyy-MM-dd")

### Added
- Projet initial

"@
    
    Set-Content -Path $OutputFile -Value $templateContent
    
    Write-Host "✅ Template de CHANGELOG généré: $OutputFile" -ForegroundColor Green
}

Write-Host "Génération du CHANGELOG terminée !" -ForegroundColor Cyan