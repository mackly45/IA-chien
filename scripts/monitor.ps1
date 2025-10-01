# Script de monitoring de l'application

param(
    [Parameter(Mandatory=$false)]
    [int]$Port = 8000
)

Write-Host "Monitoring de l'application Dog Breed Identifier" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Vérifier si le port est utilisé
Write-Host "Vérification du port $Port..." -ForegroundColor Yellow
$portInUse = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue

if ($portInUse) {
    Write-Host "✅ Port $Port en cours d'utilisation" -ForegroundColor Green
    $process = Get-Process -Id $portInUse.OwningProcess -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "Processus: $($process.ProcessName) (PID: $($process.Id))" -ForegroundColor White
    }
} else {
    Write-Host "❌ Port $Port non utilisé" -ForegroundColor Red
}

# Vérifier les conteneurs Docker
Write-Host "Vérification des conteneurs Docker..." -ForegroundColor Yellow
$containers = docker ps --filter "ancestor=dog-breed-identifier" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

if ($containers) {
    Write-Host "✅ Conteneurs Docker trouvés:" -ForegroundColor Green
    Write-Host $containers -ForegroundColor White
} else {
    Write-Host "❌ Aucun conteneur Docker trouvé pour dog-breed-identifier" -ForegroundColor Red
}

# Vérifier l'utilisation des ressources
Write-Host "Vérification de l'utilisation des ressources..." -ForegroundColor Yellow
$cpuUsage = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object Average
$memory = Get-WmiObject -Class Win32_OperatingSystem
$memoryUsage = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 2)

Write-Host "CPU Usage: $($cpuUsage.Average)%" -ForegroundColor White
Write-Host "Memory Usage: $memoryUsage%" -ForegroundColor White

# Vérifier la connectivité réseau
Write-Host "Vérification de la connectivité réseau..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:$Port/health/" -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Application accessible sur http://localhost:$Port/" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Application répond avec le code $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Impossible de joindre l'application sur http://localhost:$Port/" -ForegroundColor Red
}

Write-Host "Monitoring terminé !" -ForegroundColor Cyan