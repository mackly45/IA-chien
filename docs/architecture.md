# Architecture du Projet

## Structure générale

```
IA-chien/
├── dog_breed_identifier/     # Application Django principale
├── docs/                     # Documentation
├── scripts/                  # Scripts utilitaires
├── tests/                    # Tests automatisés
├── .dockerignore            # Fichiers ignorés par Docker
├── .env                     # Template d'environnement
├── .env.local               # Variables d'environnement locales (ignoré)
├── .gitignore               # Fichiers ignorés par Git
├── .github/                 # Configuration GitHub Actions
├── .gitlab-ci.yml           # Configuration GitLab CI/CD
├── Dockerfile               # Configuration Docker
├── README.md                # Documentation principale
├── requirements.txt         # Dépendances Python
└── docker-compose.yml       # Configuration Docker Compose
```

## Architecture de l'application

### Backend (Django)
- Modèles pour les races de chiens
- Vues pour l'API de prédiction
- Services pour le traitement d'images
- Intégration du modèle TensorFlow

### Frontend
- Interface utilisateur pour l'upload d'images
- Affichage des résultats de prédiction
- Design responsive

### Machine Learning
- Modèle TensorFlow pré-entraîné
- Pipeline de prétraitement d'images
- Intégration avec Django

## Déploiement

### Environnements
- Développement (Docker Compose)
- Production (Docker)
- CI/CD (GitHub Actions, GitLab CI)

### Plateformes
- Docker Hub (conteneurs)
- Render (hébergement)
- GitHub/GitLab (source code)