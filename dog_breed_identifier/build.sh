#!/usr/bin/env bash
# exit on error
set -o errexit

# Change to the app directory
cd /app

# Install system dependencies
apt-get update
apt-get install -y build-essential libmysqlclient-dev default-libmysqlclient-dev pkg-config

# Install Python dependencies
pip install -r requirements.txt

# Collect static files
python manage.py collectstatic --no-input

# Run migrations
python manage.py migrate