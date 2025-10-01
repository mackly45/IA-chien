# Script de vérification de performance

param(
    [Parameter(Mandatory=$false)]
    [int]$Duration = 60,
    
    [Parameter(Mandatory=$false)]
    [string]$Url = "http://localhost:8000",
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed = $false
)

Write-Host "Vérification de performance" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

# Vérifier que l'application est accessible
Write-Host "Vérification de l'accessibilité de l'application..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Application accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ Application non accessible (Code: $($response.StatusCode))" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Application non accessible: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Effectuer un test de charge simple
Write-Host "Exécution du test de charge pendant $Duration secondes..." -ForegroundColor Yellow

$startTime = Get-Date
$endTime = $startTime.AddSeconds($Duration)
$requestCount = 0
$successCount = 0
$errorCount = 0
$responseTimes = @()

while ((Get-Date) -lt $endTime) {
    $requestStartTime = Get-Date
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -ErrorAction Stop
        $requestEndTime = Get-Date
        $responseTime = ($requestEndTime - $requestStartTime).TotalMilliseconds
        
        $requestCount++
        $successCount++
        $responseTimes += $responseTime
        
        if ($Detailed) {
            Write-Host "Requête $requestCount: Succès (Temps: $([Math]::Round($responseTime, 2)) ms)" -ForegroundColor Green
        }
    } catch {
        $requestEndTime = Get-Date
        $responseTime = ($requestEndTime - $requestStartTime).TotalMilliseconds
        
        $requestCount++
        $errorCount++
        $responseTimes += $responseTime
        
        if ($Detailed) {
            Write-Host "Requête $requestCount: Erreur (Temps: $([Math]::Round($responseTime, 2)) ms)" -ForegroundColor Red
        }
    }
    
    # Petit délai pour ne pas surcharger le serveur
    Start-Sleep -Milliseconds 100
}

# Calculer les statistiques
$totalTime = ($endTime - $startTime).TotalSeconds
$requestsPerSecond = $requestCount / $totalTime

$averageResponseTime = 0
$minResponseTime = 0
$maxResponseTime = 0

if ($responseTimes.Count -gt 0) {
    $averageResponseTime = ($responseTimes | Measure-Object -Average).Average
    $minResponseTime = ($responseTimes | Measure-Object -Minimum).Minimum
    $maxResponseTime = ($responseTimes | Measure-Object -Maximum).Maximum
}

$successRate = 0
if ($requestCount -gt 0) {
    $successRate = ($successCount / $requestCount) * 100
}

# Afficher les résultats
Write-Host "`nRésultats de performance:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host "Durée du test: $([Math]::Round($totalTime, 2)) secondes" -ForegroundColor White
Write-Host "Nombre total de requêtes: $requestCount" -ForegroundColor White
Write-Host "Requêtes par seconde: $([Math]::Round($requestsPerSecond, 2))" -ForegroundColor White
Write-Host "Taux de succès: $([Math]::Round($successRate, 2))%" -ForegroundColor White
Write-Host "Temps de réponse moyen: $([Math]::Round($averageResponseTime, 2)) ms" -ForegroundColor White
Write-Host "Temps de réponse minimum: $([Math]::Round($minResponseTime, 2)) ms" -ForegroundColor White
Write-Host "Temps de réponse maximum: $([Math]::Round($maxResponseTime, 2)) ms" -ForegroundColor White

# Afficher les erreurs détaillées si présentes
if ($errorCount -gt 0) {
    Write-Host "`nErreurs détectées: $errorCount" -ForegroundColor Red
    Write-Host "Consultez les logs de l'application pour plus de détails" -ForegroundColor Yellow
}

# Évaluation de la performance
Write-Host "`nÉvaluation:" -ForegroundColor Cyan
Write-Host "=========" -ForegroundColor Cyan

if ($successRate -ge 95) {
    Write-Host "✅ Performance excellente (Taux de succès ≥ 95%)" -ForegroundColor Green
} elseif ($successRate -ge 90) {
    Write-Host "⚠️  Performance bonne (Taux de succès ≥ 90%)" -ForegroundColor Yellow
} else {
    Write-Host "❌ Performance insuffisante (Taux de succès < 90%)" -ForegroundColor Red
}

if ($averageResponseTime -le 200) {
    Write-Host "✅ Temps de réponse excellent (Moyenne ≤ 200ms)" -ForegroundColor Green
} elseif ($averageResponseTime -le 500) {
    Write-Host "⚠️  Temps de réponse acceptable (Moyenne ≤ 500ms)" -ForegroundColor Yellow
} else {
    Write-Host "❌ Temps de réponse lent (Moyenne > 500ms)" -ForegroundColor Red
}

Write-Host "Vérification de performance terminée !" -ForegroundColor Cyan