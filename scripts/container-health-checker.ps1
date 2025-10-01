# Script de vérification de la santé des conteneurs

param(
    [Parameter(Mandatory=$false)]
    [string[]]$ContainerNames = @(),
    
    [Parameter(Mandatory=$false)]
    [int]$Timeout = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFormat = "console"
)

Write-Host "Vérification de la santé des conteneurs" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$reportsDir = "./reports"

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

# Fonction pour vérifier si Docker est installé
function Test-Docker {
    try {
        $result = Get-Command docker -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Fonction pour obtenir la liste des conteneurs
function Get-Containers {
    param([array]$Names)
    
    Write-Log "Récupération de la liste des conteneurs..." "INFO"
    
    try {
        if ($Names.Count -gt 0) {
            # Filtrer par noms spécifiés
            $containers = @()
            foreach ($name in $Names) {
                $container = docker ps --filter "name=$name" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>$null
                if ($container) {
                    $containers += $container
                }
            }
            return $containers
        } else {
            # Obtenir tous les conteneurs
            $containers = docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>$null
            return $containers
        }
    } catch {
        Write-Log "Erreur lors de la récupération des conteneurs: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

# Fonction pour vérifier la santé d'un conteneur
function Test-ContainerHealth {
    param([string]$ContainerId)
    
    Write-Log "Vérification de la santé du conteneur: $ContainerId" "INFO"
    
    try {
        # Obtenir l'état du conteneur
        $inspect = docker inspect $ContainerId 2>$null | ConvertFrom-Json
        if ($inspect) {
            $state = $inspect[0].State
            $health = $inspect[0].State.Health
            
            return @{
                Id = $ContainerId
                Status = $state.Status
                Running = $state.Running
                Health = if ($health) { $health.Status } else { "unknown" }
                StartedAt = $state.StartedAt
                Error = $state.Error
            }
        }
    } catch {
        Write-Log "Erreur lors de l'inspection du conteneur $ContainerId: $($_.Exception.Message)" "ERROR"
    }
    
    return $null
}

# Fonction pour vérifier les logs d'un conteneur
function Get-ContainerLogs {
    param([string]$ContainerId, [int]$Lines = 20)
    
    Write-Log "Récupération des logs du conteneur: $ContainerId" "INFO"
    
    try {
        $logs = docker logs --tail $Lines $ContainerId 2>$null
        return $logs
    } catch {
        Write-Log "Erreur lors de la récupération des logs du conteneur $ContainerId: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Fonction pour générer un rapport
function Generate-Report {
    param(
        [array]$ContainerHealth,
        [string]$Format
    )
    
    switch ($Format.ToLower()) {
        "json" {
            $reportData = @{
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                projectName = $projectName
                containers = $ContainerHealth
                summary = @{
                    total = $ContainerHealth.Count
                    healthy = ($ContainerHealth | Where-Object { $_.Health -eq "healthy" }).Count
                    unhealthy = ($ContainerHealth | Where-Object { $_.Health -eq "unhealthy" }).Count
                    running = ($ContainerHealth | Where-Object { $_.Running -eq $true }).Count
                }
            }
            
            $reportFile = Join-Path $reportsDir "container-health.json"
            $reportData | ConvertTo-Json -Depth 10 | Out-File $reportFile
            Write-Log "Rapport JSON généré: $reportFile" "SUCCESS"
        }
        
        "html" {
            $reportFile = Join-Path $reportsDir "container-health.html"
            
            $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Santé des Conteneurs - $projectName</title>
    <meta charset="UTF-8">
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 20px; 
            background-color: #f8f9fa;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        h1 { 
            color: #2c3e50; 
            text-align: center;
            padding-bottom: 20px;
            border-bottom: 2px solid #3498db;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-item {
            background-color: #e3f2fd;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        .summary-number {
            font-size: 2em;
            font-weight: bold;
            color: #3498db;
        }
        .summary-label {
            color: #7f8c8d;
        }
        .section {
            margin-bottom: 30px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        th {
            background-color: #3498db;
            color: white;
        }
        tr:hover {
            background-color: #f5f9ff;
        }
        .health-healthy { color: #4caf50; }
        .health-unhealthy { color: #e74c3c; }
        .health-starting { color: #f39c12; }
        .health-unknown { color: #95a5a6; }
        .status-running { color: #4caf50; }
        .status-stopped { color: #e74c3c; }
        .logs {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            white-space: pre-wrap;
            max-height: 300px;
            overflow-y: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Santé des Conteneurs - $projectName</h1>
        
        <div class="summary">
            <div class="summary-item">
                <div class="summary-number">$($ContainerHealth.Count)</div>
                <div class="summary-label">Conteneurs</div>
            </div>
            <div class="summary-item">
                <div class="summary-number">$(($ContainerHealth | Where-Object { $_.Health -eq "healthy" }).Count)</div>
                <div class="summary-label">Sains</div>
            </div>
            <div class="summary-item">
                <div class="summary-number">$(($ContainerHealth | Where-Object { $_.Health -eq "unhealthy" }).Count)</div>
                <div class="summary-label">Malades</div>
            </div>
            <div class="summary-item">
                <div class="summary-number">$(($ContainerHealth | Where-Object { $_.Running -eq $true }).Count)</div>
                <div class="summary-label">En cours</div>
            </div>
        </div>
        
        <div class="section">
            <h2>État des Conteneurs</h2>
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nom</th>
                        <th>Statut</th>
                        <th>Santé</th>
                        <th>Démarré</th>
                    </tr>
                </thead>
                <tbody>
"@
            
            foreach ($container in $ContainerHealth) {
                $statusClass = if ($container.Running) { "status-running" } else { "status-stopped" }
                $healthClass = "health-$($container.Health)"
                
                $htmlContent += @"
                    <tr>
                        <td>$($container.Id.Substring(0, 12))</td>
                        <td>$($container.Names)</td>
                        <td class="$statusClass">$(if ($container.Running) { "En cours" } else { "Arrêté" })</td>
                        <td class="$healthClass">$($container.Health)</td>
                        <td>$($container.StartedAt)</td>
                    </tr>
"@
            }
            
            $htmlContent += @"
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
"@
            
            Set-Content -Path $reportFile -Value $htmlContent
            Write-Log "Rapport HTML généré: $reportFile" "SUCCESS"
        }
        
        default {
            # Affichage console
            Write-Host "`nRésumé de la santé des conteneurs:" -ForegroundColor Cyan
            Write-Host "=============================" -ForegroundColor Cyan
            Write-Host "Conteneurs totaux: $($ContainerHealth.Count)" -ForegroundColor White
            Write-Host "Conteneurs sains: $(($ContainerHealth | Where-Object { $_.Health -eq "healthy" }).Count)" -ForegroundColor $(if ((($ContainerHealth | Where-Object { $_.Health -eq "healthy" }).Count) -eq $ContainerHealth.Count) { "Green" } else { "Yellow" })
            Write-Host "Conteneurs malades: $(($ContainerHealth | Where-Object { $_.Health -eq "unhealthy" }).Count)" -ForegroundColor $(if ((($ContainerHealth | Where-Object { $_.Health -eq "unhealthy" }).Count) -eq 0) { "Green" } else { "Red" })
            Write-Host "Conteneurs en cours: $(($ContainerHealth | Where-Object { $_.Running -eq $true }).Count)" -ForegroundColor White
            
            if ($Detailed) {
                Write-Host "`nDétails par conteneur:" -ForegroundColor Cyan
                Write-Host "===================" -ForegroundColor Cyan
                
                foreach ($container in $ContainerHealth) {
                    Write-Host "`nConteneur: $($container.Id.Substring(0, 12)) ($($container.Names))" -ForegroundColor White
                    Write-Host "  Statut: $(if ($container.Running) { "✅ En cours" } else { "❌ Arrêté" })" -ForegroundColor $(if ($container.Running) { "Green" } else { "Red" })
                    Write-Host "  Santé: $($container.Health)" -ForegroundColor $(if ($container.Health -eq "healthy") { "Green" } elseif ($container.Health -eq "unhealthy") { "Red" } else { "Yellow" })
                    Write-Host "  Démarré: $($container.StartedAt)" -ForegroundColor Gray
                    
                    if ($container.Error) {
                        Write-Host "  Erreur: $($container.Error)" -ForegroundColor Red
                    }
                }
            }
        }
    }
}

# Vérifier que Docker est installé
if (-not (Test-Docker)) {
    Write-Log "Docker n'est pas installé ou n'est pas accessible" "ERROR"
    exit 1
}

# Créer le répertoire des rapports s'il n'existe pas
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    Write-Log "Répertoire des rapports créé: $reportsDir" "INFO"
}

# Obtenir la liste des conteneurs
$containers = Get-Containers -Names $ContainerNames

if ($containers.Count -eq 0) {
    Write-Log "Aucun conteneur trouvé" "WARN"
    exit 0
}

Write-Log "$($containers.Count) conteneurs trouvés" "SUCCESS"

# Vérifier la santé de chaque conteneur
$containerHealth = @()
foreach ($container in $containers) {
    # Extraire l'ID du conteneur (première colonne)
    $containerId = ($container -split '\s+')[0]
    
    # Ignorer l'en-tête
    if ($containerId -eq "CONTAINER" -or $containerId -eq "ID") {
        continue
    }
    
    $health = Test-ContainerHealth -ContainerId $containerId
    if ($health) {
        # Extraire le nom (deuxième colonne)
        $containerName = ($container -split '\s+')[1]
        $health.Names = $containerName
        $containerHealth += $health
    }
}

# Afficher les logs si en mode détaillé
if ($Detailed) {
    foreach ($container in $containerHealth) {
        $logs = Get-ContainerLogs -ContainerId $container.Id
        if ($logs) {
            Write-Host "`nLogs du conteneur $($container.Id.Substring(0, 12)):" -ForegroundColor Cyan
            Write-Host "================================" -ForegroundColor Cyan
            Write-Host $logs -ForegroundColor Gray
        }
    }
}

# Générer le rapport
Generate-Report -ContainerHealth $containerHealth -Format $OutputFormat

# Afficher le résumé final
Write-Host "`nRésumé de la santé des conteneurs:" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "Conteneurs vérifiés: $($containerHealth.Count)" -ForegroundColor White
Write-Host "Conteneurs sains: $(($containerHealth | Where-Object { $_.Health -eq "healthy" }).Count)" -ForegroundColor $(if ((($containerHealth | Where-Object { $_.Health -eq "healthy" }).Count) -eq $containerHealth.Count) { "Green" } else { "Yellow" })
Write-Host "Conteneurs malades: $(($containerHealth | Where-Object { $_.Health -eq "unhealthy" }).Count)" -ForegroundColor $(if ((($containerHealth | Where-Object { $_.Health -eq "unhealthy" }).Count) -eq 0) { "Green" } else { "Red" })

# Déterminer le statut global
$allHealthy = ($containerHealth | Where-Object { $_.Health -eq "healthy" }).Count -eq $containerHealth.Count
$anyUnhealthy = ($containerHealth | Where-Object { $_.Health -eq "unhealthy" }).Count -gt 0

if ($allHealthy) {
    Write-Host "`n✅ Tous les conteneurs sont en bonne santé !" -ForegroundColor Green
    exit 0
} elseif ($anyUnhealthy) {
    Write-Host "`n❌ Certains conteneurs sont en mauvaise santé" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n⚠️  Certains conteneurs ont un état de santé inconnu" -ForegroundColor Yellow
    exit 0
}