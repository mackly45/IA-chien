#!/bin/bash
# Simple test script to verify container functionality

echo "Testing container functionality..."

# Test 1: Check if Python is available
echo "Test 1: Checking Python..."
python --version

# Test 2: Check if Django is installed
echo "Test 2: Checking Django..."
python -c "import django; print('Django version:', django.get_version())"

# Test 3: Check if requirements are met
echo "Test 3: Checking requirements..."
pip list | grep -E "(Django|gunicorn|tensorflow)"

# Test 4: Check if manage.py exists
echo "Test 4: Checking manage.py..."
ls -la /app/dog_breed_identifier/manage.py

# Test 5: Run Django check
echo "Test 5: Running Django check..."
cd /app/dog_breed_identifier && python manage.py check

echo "Container test completed."