# For more information, please refer to https://aka.ms/vscode-docker-python
FROM python:3.11-slim

EXPOSE 8000

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install system dependencies
# Updated 2025-09-30: Replaced libmysqlclient-dev with libmariadb-dev for Debian Trixie compatibility
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libmariadb-dev \
        libmariadb-dev-compat \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy project
COPY . /app/

# Change to the project directory
WORKDIR /app/dog_breed_identifier

# Install pip requirements
RUN python -m pip install --upgrade pip
RUN python -m pip install -r requirements.txt

# Collect static files
RUN python manage.py collectstatic --noinput

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-python-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# During debugging, this entry point will be overridden. For more information, please refer to https://aka.ms/vscode-docker-python-debug
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--chdir", "/app/dog_breed_identifier", "dog_identifier.wsgi:application"]