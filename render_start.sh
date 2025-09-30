#!/bin/bash

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