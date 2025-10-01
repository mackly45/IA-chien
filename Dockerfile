FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=8000

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libjpeg-dev \
        zlib1g-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and setuptools to secure versions
RUN pip install --upgrade pip setuptools>=78.1.1

# Copy requirements first to leverage Docker cache
COPY requirements.txt /app/

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app/

# Change to the project directory
WORKDIR /app/dog_breed_identifier

# Create static directory if it doesn't exist
RUN mkdir -p static

# Collect static files (ignore errors)
RUN python manage.py collectstatic --noinput --verbosity=0 || echo "Warning: Could not collect static files"

# Create a non-root user
RUN adduser --disabled-password --gecos '' appuser
RUN chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Run the application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--chdir", "/app/dog_breed_identifier", "dog_identifier.wsgi:application"]