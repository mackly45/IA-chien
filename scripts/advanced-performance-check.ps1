# Script de vérification de performance avancée

param(
    [Parameter(Mandatory=$false)]
    [int]$Duration = 300,  # 5 minutes par défaut
    
    [Parameter(Mandatory=$false)]
    [string]$Url = "http://localhost:8000",
    
    [Parameter(Mandatory=$false)]
    [int]$ConcurrentUsers = 10,
    
    [Parameter(Mandatory=$false)]
    [string[]]$Endpoints = @("/", "/api/identify/", "/health/"),
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeDatabase = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeML = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFormat = "console",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "./performance-report.txt"
)

Write-Host "Vérification de performance avancée de Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$report = @()
$metrics = @{
    totalRequests = 0
    successfulRequests = 0
    failedRequests = 0
    totalTime = 0
    responseTimes = @()
    throughput = 0
    errorRate = 0
}

# Fonction pour ajouter une entrée au rapport
function Add-ReportEntry {
    param([string]$Type, [string]$Message, [hashtable]$Details = @{})
    
    $entry = @{
        Type = $Type
        Message = $Message
        Details = $Details
        Timestamp = Get-Date
    }
    
    $script:report += $entry
    
    # Afficher immédiatement si le format est console
    if ($OutputFormat -eq "console") {
        Write-Host "[$Type] $Message" -ForegroundColor White
        if ($Details.Count -gt 0) {
            foreach ($key in $Details.Keys) {
                Write-Host "  $key: $($Details[$key])" -ForegroundColor Gray
            }
        }
    }
}

# Fonction pour mesurer le temps d'exécution
function Measure-ExecutionTime {
    param([scriptblock]$ScriptBlock)
    
    $startTime = Get-Date
    &$ScriptBlock
    $endTime = Get-Date
    
    return ($endTime - $startTime).TotalMilliseconds
}

# Fonction pour effectuer un test de charge HTTP
function Invoke-LoadTest {
    param(
        [string]$TargetUrl,
        [int]$Users,
        [int]$TestDuration,
        [string[]]$TestEndpoints
    )
    
    Write-Host "Exécution du test de charge..." -ForegroundColor Yellow
    Add-ReportEntry -Type "LoadTest" -Message "Démarrage du test de charge" -Details @{
        "URL" = $TargetUrl
        "Utilisateurs" = $Users
        "Durée" = "$TestDuration secondes"
        "Endpoints" = ($TestEndpoints -join ", ")
    }
    
    # Variables pour le suivi des métriques
    $requests = 0
    $successes = 0
    $failures = 0
    $totalResponseTime = 0
    $responseTimes = @()
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($TestDuration)
    
    # Créer des jobs pour simuler les utilisateurs concurrents
    $jobs = @()
    
    for ($i = 0; $i -lt $Users; $i++) {
        $job = Start-Job -ScriptBlock {
            param($TargetUrl, $TestEndpoints, $EndTime, $JobId)
            
            $jobRequests = 0
            $jobSuccesses = 0
            $jobFailures = 0
            $jobResponseTimes = @()
            
            while ((Get-Date) -lt $EndTime) {
                # Choisir un endpoint aléatoire
                $endpoint = $TestEndpoints | Get-Random
                $fullUrl = "$TargetUrl$endpoint"
                
                $requestStartTime = Get-Date
                try {
                    $response = Invoke-WebRequest -Uri $fullUrl -TimeoutSec 30 -ErrorAction Stop
                    $requestEndTime = Get-Date
                    
                    $responseTime = ($requestEndTime - $requestStartTime).TotalMilliseconds
                    $jobResponseTimes += $responseTime
                    $jobSuccesses++
                } catch {
                    $requestEndTime = Get-Date
                    $responseTime = ($requestEndTime - $requestStartTime).TotalMilliseconds
                    $jobResponseTimes += $responseTime
                    $jobFailures++
                }
                
                $jobRequests++
                
                # Petit délai pour ne pas surcharger
                Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200)
            }
            
            return @{
                Requests = $jobRequests
                Successes = $jobSuccesses
                Failures = $jobFailures
                ResponseTimes = $jobResponseTimes
            }
        } -ArgumentList $TargetUrl, $TestEndpoints, $endTime, $i
        
        $jobs += $job
    }
    
    # Attendre la fin de tous les jobs
    $jobResults = @()
    foreach ($job in $jobs) {
        $result = Receive-Job -Job $job -Wait
        $jobResults += $result
        Remove-Job -Job $job
    }
    
    # Agréger les résultats
    foreach ($result in $jobResults) {
        $requests += $result.Requests
        $successes += $result.Successes
        $failures += $result.Failures
        $responseTimes += $result.ResponseTimes
        $totalResponseTime += ($result.ResponseTimes | Measure-Object -Sum).Sum
    }
    
    # Calculer les métriques
    $totalTime = ($endTime - $startTime).TotalSeconds
    $throughput = if ($totalTime -gt 0) { $requests / $totalTime } else { 0 }
    $errorRate = if ($requests -gt 0) { ($failures / $requests) * 100 } else { 0 }
    $averageResponseTime = if ($responseTimes.Count -gt 0) { ($responseTimes | Measure-Object -Average).Average } else { 0 }
    $minResponseTime = if ($responseTimes.Count -gt 0) { ($responseTimes | Measure-Object -Minimum).Minimum } else { 0 }
    $maxResponseTime = if ($responseTimes.Count -gt 0) { ($responseTimes | Measure-Object -Maximum).Maximum } else { 0 }
    
    # Mettre à jour les métriques globales
    $script:metrics.totalRequests = $requests
    $script:metrics.successfulRequests = $successes
    $script:metrics.failedRequests = $failures
    $script:metrics.totalTime = $totalTime
    $script:metrics.responseTimes = $responseTimes
    $script:metrics.throughput = $throughput
    $script:metrics.errorRate = $errorRate
    
    # Ajouter au rapport
    Add-ReportEntry -Type "LoadTest" -Message "Test de charge terminé" -Details @{
        "Requêtes totales" = $requests
        "Requêtes réussies" = $successes
        "Requêtes échouées" = $failures
        "Débit (req/s)" = "{0:N2}" -f $throughput
        "Taux d'erreur (%)" = "{0:N2}" -f $errorRate
        "Temps de réponse moyen (ms)" = "{0:N2}" -f $averageResponseTime
        "Temps de réponse minimum (ms)" = "{0:N2}" -f $minResponseTime
        "Temps de réponse maximum (ms)" = "{0:N2}" -f $maxResponseTime
    }
}

# Fonction pour tester les performances de la base de données
function Test-DatabasePerformance {
    Write-Host "Test des performances de la base de données..." -ForegroundColor Yellow
    
    # Vérifier si l'application est accessible
    try {
        $healthResponse = Invoke-WebRequest -Uri "$Url/health/" -TimeoutSec 10 -ErrorAction Stop
        if ($healthResponse.StatusCode -eq 200) {
            Add-ReportEntry -Type "Database" -Message "Endpoint de santé accessible"
        } else {
            Add-ReportEntry -Type "Database" -Message "Endpoint de santé non accessible" -Details @{
                "Code" = $healthResponse.StatusCode
            }
            return
        }
    } catch {
        Add-ReportEntry -Type "Database" -Message "Impossible d'accéder à l'endpoint de santé" -Details @{
            "Erreur" = $_.Exception.Message
        }
        return
    }
    
    # Test de latence de la base de données
    $dbLatency = Measure-ExecutionTime {
        try {
            # Cette partie dépend de l'implémentation de votre application
            # Vous pouvez implémenter un endpoint spécial pour tester la base de données
            $dbTestResponse = Invoke-WebRequest -Uri "$Url/api/db-test/" -TimeoutSec 10 -ErrorAction Stop
            return $dbTestResponse.StatusCode -eq 200
        } catch {
            return $false
        }
    }
    
    Add-ReportEntry -Type "Database" -Message "Test de latence de la base de données" -Details @{
        "Latence (ms)" = "{0:N2}" -f $dbLatency
    }
}

# Fonction pour tester les performances du modèle ML
function Test-MLPerformance {
    Write-Host "Test des performances du modèle ML..." -ForegroundColor Yellow
    
    # Créer une image de test temporaire
    $testImagePath = [System.IO.Path]::GetTempFileName() + ".jpg"
    
    try {
        # Générer une image de test (vous pouvez utiliser une image existante)
        # Pour cet exemple, nous allons créer un fichier vide
        Set-Content -Path $testImagePath -Value "Test image content"
        
        # Mesurer le temps de traitement de l'image
        $mlLatency = Measure-ExecutionTime {
            try {
                $response = Invoke-WebRequest -Uri "$Url/api/identify/" -Method POST -InFile $testImagePath -ContentType "image/jpeg" -TimeoutSec 60 -ErrorAction Stop
                return $response.StatusCode -eq 200
            } catch {
                return $false
            }
        }
        
        Add-ReportEntry -Type "ML" -Message "Test de latence du modèle ML" -Details @{
            "Latence (ms)" = "{0:N2}" -f $mlLatency
        }
    } finally {
        # Nettoyer le fichier de test
        if (Test-Path $testImagePath) {
            Remove-Item $testImagePath -Force
        }
    }
}

# Fonction pour générer le rapport
function Generate-Report {
    Write-Host "Génération du rapport de performance..." -ForegroundColor Yellow
    
    switch ($OutputFormat.ToLower()) {
        "json" {
            $reportData = @{
                project = $projectName
                generated = Get-Date
                metrics = $metrics
                findings = $report
            }
            
            $reportData | ConvertTo-Json -Depth 10 | Out-File $OutputFile
            Write-Host "✅ Rapport JSON généré: $OutputFile" -ForegroundColor Green
        }
        
        "html" {
            $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de Performance - $projectName</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .metrics { background-color: #f5f5f5; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .finding { border-left: 5px solid #2196f3; padding: 10px; margin: 10px 0; }
        .finding.loadtest { border-left-color: #4caf50; }
        .finding.database { border-left-color: #ff9800; }
        .finding.ml { border-left-color: #9c27b0; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Rapport de Performance - $projectName</h1>
    <p>Généré le: $(Get-Date)</p>
    
    <div class="metrics">
        <h2>Métriques Globales</h2>
        <table>
            <tr><th>Métrique</th><th>Valeur</th></tr>
            <tr><td>Requêtes totales</td><td>$($metrics.totalRequests)</td></tr>
            <tr><td>Requêtes réussies</td><td>$($metrics.successfulRequests)</td></tr>
            <tr><td>Requêtes échouées</td><td>$($metrics.failedRequests)</td></tr>
            <tr><td>Durée totale (s)</td><td>$("{0:N2}" -f $metrics.totalTime)</td></tr>
            <tr><td>Débit (req/s)</td><td>$("{0:N2}" -f $metrics.throughput)</td></tr>
            <tr><td>Taux d'erreur (%)</td><td>$("{0:N2}" -f $metrics.errorRate)</td></tr>
"@
            
            if ($metrics.responseTimes.Count -gt 0) {
                $avgResponseTime = ($metrics.responseTimes | Measure-Object -Average).Average
                $minResponseTime = ($metrics.responseTimes | Measure-Object -Minimum).Minimum
                $maxResponseTime = ($metrics.responseTimes | Measure-Object -Maximum).Maximum
                
                $htmlContent += @"
            <tr><td>Temps de réponse moyen (ms)</td><td>$("{0:N2}" -f $avgResponseTime)</td></tr>
            <tr><td>Temps de réponse minimum (ms)</td><td>$("{0:N2}" -f $minResponseTime)</td></tr>
            <tr><td>Temps de réponse maximum (ms)</td><td>$("{0:N2}" -f $maxResponseTime)</td></tr>
"@
            }
            
            $htmlContent += @"
        </table>
    </div>
    
    <h2>Résultats des Tests</h2>
"@
            
            foreach ($entry in $report) {
                $className = $entry.Type.ToLower()
                $htmlContent += @"
    <div class="finding $className">
        <h3>[$($entry.Type)] $($entry.Message)</h3>
"@
                
                if ($entry.Details.Count -gt 0) {
                    $htmlContent += "        <ul>"
                    foreach ($key in $entry.Details.Keys) {
                        $htmlContent += "            <li><strong>$key:</strong> $($entry.Details[$key])</li>"
                    }
                    $htmlContent += "        </ul>"
                }
                
                $htmlContent += "        <small>$(($entry.Timestamp).ToString("yyyy-MM-dd HH:mm:ss"))</small>"
                $htmlContent += "    </div>"
            }
            
            $htmlContent += @"
</body>
</html>
"@
            
            Set-Content -Path $OutputFile -Value $htmlContent
            Write-Host "✅ Rapport HTML généré: $OutputFile" -ForegroundColor Green
        }
        
        default {
            # Le rapport a déjà été affiché en console
            if ($OutputFile -ne "./performance-report.txt") {
                $reportContent = "Rapport de Performance - $projectName`n"
                $reportContent += "Généré le: $(Get-Date)`n`n"
                
                $reportContent += "Métriques Globales:`n"
                $reportContent += "==================`n"
                $reportContent += "Requêtes totales: $($metrics.totalRequests)`n"
                $reportContent += "Requêtes réussies: $($metrics.successfulRequests)`n"
                $reportContent += "Requêtes échouées: $($metrics.failedRequests)`n"
                $reportContent += "Durée totale (s): $("{0:N2}" -f $metrics.totalTime)`n"
                $reportContent += "Débit (req/s): $("{0:N2}" -f $metrics.throughput)`n"
                $reportContent += "Taux d'erreur (%): $("{0:N2}" -f $metrics.errorRate)`n"
                
                if ($metrics.responseTimes.Count -gt 0) {
                    $avgResponseTime = ($metrics.responseTimes | Measure-Object -Average).Average
                    $minResponseTime = ($metrics.responseTimes | Measure-Object -Minimum).Minimum
                    $maxResponseTime = ($metrics.responseTimes | Measure-Object -Maximum).Maximum
                    
                    $reportContent += "Temps de réponse moyen (ms): $("{0:N2}" -f $avgResponseTime)`n"
                    $reportContent += "Temps de réponse minimum (ms): $("{0:N2}" -f $minResponseTime)`n"
                    $reportContent += "Temps de réponse maximum (ms): $("{0:N2}" -f $maxResponseTime)`n"
                }
                
                $reportContent += "`nRésultats des Tests:`n"
                $reportContent += "===================`n"
                
                foreach ($entry in $report) {
                    $reportContent += "[$($entry.Type)] $($entry.Message)`n"
                    if ($entry.Details.Count -gt 0) {
                        foreach ($key in $entry.Details.Keys) {
                            $reportContent += "  $key: $($entry.Details[$key])`n"
                        }
                    }
                    $reportContent += "  $(($entry.Timestamp).ToString("yyyy-MM-dd HH:mm:ss"))`n`n"
                }
                
                Set-Content -Path $OutputFile -Value $reportContent
                Write-Host "✅ Rapport texte généré: $OutputFile" -ForegroundColor Green
            }
        }
    }
}

# Exécuter les tests selon les paramètres
Write-Host "Exécution des tests de performance..." -ForegroundColor Yellow

# Test de charge principal
Invoke-LoadTest -TargetUrl $Url -Users $ConcurrentUsers -TestDuration $Duration -TestEndpoints $Endpoints

# Tests supplémentaires si demandés
if ($IncludeDatabase) {
    Test-DatabasePerformance
}

if ($IncludeML) {
    Test-MLPerformance
}

# Générer le rapport
Generate-Report

# Afficher le résumé
Write-Host "`nRésumé des performances:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

Write-Host "Métriques Globales:" -ForegroundColor White
Write-Host "  Requêtes totales: $($metrics.totalRequests)" -ForegroundColor Gray
Write-Host "  Requêtes réussies: $($metrics.successfulRequests)" -ForegroundColor Gray
Write-Host "  Requêtes échouées: $($metrics.failedRequests)" -ForegroundColor Gray
Write-Host "  Débit (req/s): $("{0:N2}" -f $metrics.throughput)" -ForegroundColor Gray
Write-Host "  Taux d'erreur (%): $("{0:N2}" -f $metrics.errorRate)" -ForegroundColor Gray

if ($metrics.responseTimes.Count -gt 0) {
    $avgResponseTime = ($metrics.responseTimes | Measure-Object -Average).Average
    $minResponseTime = ($metrics.responseTimes | Measure-Object -Minimum).Minimum
    $maxResponseTime = ($metrics.responseTimes | Measure-Object -Maximum).Maximum
    
    Write-Host "  Temps de réponse moyen (ms): $("{0:N2}" -f $avgResponseTime)" -ForegroundColor Gray
    Write-Host "  Temps de réponse minimum (ms): $("{0:N2}" -f $minResponseTime)" -ForegroundColor Gray
    Write-Host "  Temps de réponse maximum (ms): $("{0:N2}" -f $maxResponseTime)" -ForegroundColor Gray
}

Write-Host "Vérification de performance avancée terminée !" -ForegroundColor Cyan