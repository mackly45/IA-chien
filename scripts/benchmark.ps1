# Script de benchmark de performance

param(
    [Parameter(Mandatory=$false)]
    [int]$Iterations = 100,
    
    [Parameter(Mandatory=$false)]
    [string]$ImageUrl = "https://example.com/test-dog-image.jpg"
)

Write-Host "Benchmark de performance Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Vérifier que l'application est en cours d'exécution
Write-Host "Vérification de l'application..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health/" -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Application en cours d'exécution" -ForegroundColor Green
    } else {
        Write-Host "❌ Application non accessible" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Application non accessible: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Télécharger une image de test si nécessaire
$testImage = "./test-image.jpg"
if (-not (Test-Path $testImage)) {
    Write-Host "Téléchargement de l'image de test..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $ImageUrl -OutFile $testImage
        Write-Host "✅ Image de test téléchargée" -ForegroundColor Green
    } catch {
        Write-Host "❌ Échec du téléchargement de l'image de test" -ForegroundColor Red
        exit 1
    }
}

# Effectuer le benchmark
Write-Host "Exécution du benchmark avec $Iterations itérations..." -ForegroundColor Yellow

$timings = @()
$totalTime = 0

for ($i = 1; $i -le $Iterations; $i++) {
    $startTime = Get-Date
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/api/identify/" -Method POST -InFile $testImage -ContentType "image/jpeg"
        $endTime = Get-Date
        
        $duration = ($endTime - $startTime).TotalMilliseconds
        $timings += $duration
        $totalTime += $duration
        
        Write-Progress -Activity "Benchmark en cours" -Status "Itération $i/$Iterations" -PercentComplete (($i / $Iterations) * 100)
        
        if ($response.StatusCode -ne 200) {
            Write-Host "⚠️  Itération $i: Code de réponse $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        $timings += $duration
        $totalTime += $duration
        
        Write-Host "❌ Itération $i échouée: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Calculer les statistiques
$averageTime = $totalTime / $Iterations
$minTime = ($timings | Measure-Object -Minimum).Minimum
$maxTime = ($timings | Measure-Object -Maximum).Maximum

# Calculer le 95e percentile
$sortedTimings = $timings | Sort-Object
$percentile95Index = [Math]::Floor($sortedTimings.Count * 0.95)
$percentile95 = $sortedTimings[$percentile95Index]

Write-Host "`nRésultats du benchmark:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host "Itérations: $Iterations" -ForegroundColor White
Write-Host "Temps moyen: $([Math]::Round($averageTime, 2)) ms" -ForegroundColor White
Write-Host "Temps minimum: $([Math]::Round($minTime, 2)) ms" -ForegroundColor White
Write-Host "Temps maximum: $([Math]::Round($maxTime, 2)) ms" -ForegroundColor White
Write-Host "95e percentile: $([Math]::Round($percentile95, 2)) ms" -ForegroundColor White

# Nettoyer l'image de test
if (Test-Path $testImage) {
    Remove-Item $testImage -Force
}

Write-Host "Benchmark terminé !" -ForegroundColor Cyan