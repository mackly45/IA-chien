# Dog Breed Identifier

A Django application that uses machine learning to identify dog breeds from images.

## Features

- 🐶 **Dog Breed Recognition**: Identify over 120 dog breeds using deep learning
- 🐕 **Web Interface**: User-friendly web application for image upload
- 🐳 **Docker Support**: Containerized application for easy deployment
- ☁️ **Multi-platform Deployment**: Deploy to Docker Hub, Render, and more
- 🔄 **CI/CD Integration**: Automated testing and deployment with GitHub Actions and GitLab CI

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

### Environment Variables

Create a `.env.local` file from `.env` and configure your personal credentials:

```bash
cp .env .env.local
```

Then edit `.env.local` with your actual credentials:

```bash
# Docker Hub credentials
DOCKER_USERNAME=your_docker_hub_username
DOCKER_PASSWORD=your_docker_hub_password

# Deployment hooks
RENDER_DEPLOY_HOOK=https://api.render.com/deploy/your-hook
```

**Important**: The `.env.local` file is ignored by Git and will not be committed to the repository, keeping your credentials secure.

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

##### Configuring GitHub Secrets
1. Go to your GitHub repository
2. Click on "Settings"
3. In the left menu, click "Secrets and variables" then "Actions"
4. Click "New repository secret"
5. Add the following secrets:

```
Name: DOCKER_USERNAME
Value: your_docker_hub_username

Name: DOCKER_PASSWORD
Value: your_docker_hub_personal_access_token

Name: RENDER_DEPLOY_HOOK
Value: https://api.render.com/deploy/your-hook-url
```

#### GitLab CI/CD
- Configuration file: `.gitlab-ci.yml`
- Supports automated testing, building, and deployment

##### Configuring GitLab Variables
1. Go to your GitLab project
2. Click on "Settings" then "CI /CD"
3. Expand the "Variables" section
4. Click "Add variable"
5. Add the following variables:

```
Name: DOCKER_USERNAME
Value: your_docker_hub_username

Name: DOCKER_PASSWORD
Value: your_docker_hub_personal_access_token

Name: RENDER_DEPLOY_HOOK
Value: https://api.render.com/deploy/your-hook-url
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
- `.env`: Environment variables template
- `.env.local`: Your personal environment variables (ignored by Git)

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

## Project Structure

```
IA-chien/
├── dog_breed_identifier/     # Django application
├── docs/                     # Documentation
├── scripts/                  # Utility scripts
├── tests/                    # Automated tests
├── .dockerignore            # Docker ignore rules
├── .env                     # Environment template
├── .env.local               # Local environment (ignored)
├── .gitignore               # Git ignore rules
├── .github/                 # GitHub Actions workflows
├── .gitlab-ci.yml           # GitLab CI/CD configuration
├── Dockerfile               # Docker configuration
├── README.md                # This file
├── requirements.txt         # Python dependencies
└── docker-compose.yml       # Docker Compose configuration
```

## Troubleshooting

If you encounter issues:

1. Make sure Docker is installed and running
2. Check that ports are not already in use
3. Verify environment variables are set correctly
4. Check Docker logs: `docker logs <container_name>`

For more information, please refer to the individual configuration files.