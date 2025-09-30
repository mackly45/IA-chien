#!/bin/bash
set -e

# Aller dans le répertoire du projet Django
cd /app/dog_breed_identifier

# Exécuter les migrations
echo "Running migrations..."
python manage.py migrate --noinput

# Collecter les fichiers statiques
echo "Collecting static files..."
python manage.py collectstatic --noinput --verbosity=0

# Démarrer l'application avec Gunicorn
echo "Starting application on port $PORT..."
exec gunicorn --bind 0.0.0.0:$PORT --chdir /app/dog_breed_identifier dog_identifier.wsgi:application

# Exit on any error
set -e

# Install system dependencies for Render
echo "Installing system dependencies..."
apt-get update
apt-get install -y --no-install-recommends \
    build-essential \
    libmariadb-dev \
    libmariadb-dev-compat \
    pkg-config

# Clean up
rm -rf /var/lib/apt/lists/*

# Install Python dependencies
echo "Installing Python dependencies..."
pip install --no-cache-dir -r requirements.txt

# Collect static files
echo "Collecting static files..."
python dog_breed_identifier/manage.py collectstatic --noinput

# Run migrations
echo "Running migrations..."
python dog_breed_identifier/manage.py migrate

# Start the application
echo "Starting application..."
exec gunicorn --bind 0.0.0.0:$PORT --chdir /app/dog_breed_identifier dog_identifier.wsgi:application