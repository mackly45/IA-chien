# Guide de Développement

## Prérequis

- Python 3.8+
- Docker et Docker Compose
- Git
- Compte Docker Hub
- Compte Render (pour déploiement)

## Installation locale

### 1. Cloner le dépôt

```bash
git clone <url_du_depot>
cd IA-chien
```

### 2. Créer l'environnement virtuel

```bash
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# ou
.venv\Scripts\activate     # Windows
```

### 3. Installer les dépendances

```bash
pip install -r requirements.txt
```

### 4. Configurer les variables d'environnement

```bash
cp .env .env.local
# Éditer .env.local avec vos identifiants
```

### 5. Lancer l'application en développement

```bash
docker-compose up
```

## Structure du code

### Application Django principale

- `dog_breed_identifier/` - Projet Django principal
- `dog_breed_identifier/settings.py` - Configuration
- `dog_breed_identifier/urls.py` - Routes principales

### Applications Django

- `core/` - Fonctionnalités centrales
- `ml/` - Intégration Machine Learning
- `api/` - API REST

## Développement avec Docker

### Construire l'image

```bash
docker build -t dog-breed-identifier .
```

### Lancer le conteneur

```bash
docker run -p 8000:8000 dog-breed-identifier
```

## Tests

### Exécuter les tests unitaires

```bash
python manage.py test
```

### Exécuter les tests avec Docker

```bash
docker run dog-breed-identifier python manage.py test
```

## Débogage

### Logs de l'application

```bash
docker logs <nom_du_conteneur>
```

### Accéder au shell du conteneur

```bash
docker exec -it <nom_du_conteneur> /bin/bash
```