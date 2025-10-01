# Build script for dog breed identifier Docker image

Write-Host "Building Docker image for dog breed identifier..."

# Build the Docker image
docker build -t dog-breed-identifier .

if ($LASTEXITCODE -eq 0) {
    Write-Host "Docker image built successfully!" -ForegroundColor Green
    Write-Host "To run the container locally:"
    Write-Host "  docker run -p 8000:8000 dog-breed-identifier"
    Write-Host ""
    Write-Host "To run with docker-compose:"
    Write-Host "  docker-compose up"
    Write-Host ""
    Write-Host "To tag and push to a registry (replace with your registry):"
    Write-Host "  docker tag dog-breed-identifier your-registry/dog-breed-identifier:latest"
    Write-Host "  docker push your-registry/dog-breed-identifier:latest"
} else {
    Write-Host "Docker build failed!" -ForegroundColor Red
    exit 1
}