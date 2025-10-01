# Dog Breed Identifier

A Django application that uses machine learning to identify dog breeds from images.

## Docker Deployment

This project includes Docker configuration for easy deployment across multiple platforms.

### Building the Docker Image

To build the Docker image:

```bash
# Using the build script (Linux/Mac)
./build-docker.sh

# Using the build script (Windows)
./build-docker.ps1

# Or manually:
docker build -t dog-breed-identifier .
```

### Running the Application Locally

```bash
# Using docker-compose (recommended for development)
docker-compose up

# Using docker run
docker run -p 8000:8000 dog-breed-identifier
```

## Automated Deployment

This project includes full automated deployment capabilities across multiple platforms.

### Prerequisites

1. Docker installed and running
2. Git installed
3. Accounts on deployment platforms (Docker Hub, Render)

### Initial Setup

Run the initialization script:

```bash
# Windows
./init-auto-deploy.ps1

# Linux/Mac
./init-auto-deploy.sh
```

### Automated Deployment Commands

```bash
# Fully automated deployment to all platforms
./deploy.ps1 -Auto

# Interactive deployment menu
./deploy.ps1

# Deploy to specific platform
./deploy.ps1 -Platform dockerhub
./deploy.ps1 -Platform render
./deploy.ps1 -Platform local
```

### CI/CD Configuration

#### GitHub Actions
- Workflow file: `.github/workflows/auto-deploy.yml`
- Automatically builds and deploys on push to main branch
- Requires secrets configuration in GitHub repository settings

#### GitLab CI/CD
- Configuration file: `.gitlab-ci.yml`
- Supports automated testing, building, and deployment

### Environment Variables

Create a `.env` file from `.env.example` and configure:

```bash
# Docker Hub credentials
DOCKER_USERNAME=your_docker_hub_username
DOCKER_PASSWORD=your_docker_hub_password

# Deployment hooks
RENDER_DEPLOY_HOOK=https://api.render.com/deploy/your-hook
```

### Deployment Platforms

#### 1. Local Deployment
```bash
./deploy.ps1 -Platform local
```

#### 2. Docker Hub
```bash
./deploy.ps1 -Platform dockerhub
```

#### 3. Render
1. Connect repository to Render
2. Add environment variables in Render dashboard
3. Deployment triggered automatically via webhook

### Deployment Configuration Files

- `.github/workflows/auto-deploy.yml`: GitHub Actions workflow
- `.gitlab-ci.yml`: GitLab CI/CD configuration
- `deploy.ps1`: PowerShell deployment script
- `init-auto-deploy.ps1`: Initialization script
- `.env.example`: Environment variables template

## Development

To run the application in development mode:

```bash
# Using docker-compose
docker-compose up

# The development version uses Django's development server
# and mounts local volumes for live code updates
```

## Production

For production deployment, the application uses Gunicorn as the WSGI server.

The production Docker image:
- Uses Gunicorn for serving the application
- Runs as a non-root user for security
- Collects static files during the build process
- Is optimized for size and performance

## Troubleshooting

If you encounter issues:

1. Make sure Docker is installed and running
2. Check that ports are not already in use
3. Verify environment variables are set correctly
4. Check Docker logs: `docker logs <container_name>`

For more information, please refer to the individual configuration files.