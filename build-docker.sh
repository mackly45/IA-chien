#!/bin/bash

# Build script for dog breed identifier Docker image

echo "Building Docker image for dog breed identifier..."

# Build the Docker image
docker build -t dog-breed-identifier .

if [ $? -eq 0 ]; then
    echo "Docker image built successfully!"
    echo "To run the container locally:"
    echo "  docker run -p 8000:8000 dog-breed-identifier"
    echo ""
    echo "To run with docker-compose:"
    echo "  docker-compose up"
    echo ""
    echo "To tag and push to a registry (replace with your registry):"
    echo "  docker tag dog-breed-identifier your-registry/dog-breed-identifier:latest"
    echo "  docker push your-registry/dog-breed-identifier:latest"
else
    echo "Docker build failed!"
    exit 1
fi