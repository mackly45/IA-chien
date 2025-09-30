# Identificateur de Race de Chien

## Version 1.0.0

Une application web Django qui utilise l'apprentissage automatique pour identifier les races de chiens et leurs pays d'origine à partir d'images téléchargées.

## Fonctionnalités

- Télécharger des photos de chiens pour l'identification des races
- Détection de race et d'origine alimentée par l'IA
- Base de données d'informations détaillées sur les races
- Interface web réactive
- Entraînement automatique du modèle avec de nouvelles données
- Collecte automatique d'images pour améliorer le modèle
- Prédictions alternatives pour une identification plus précise

## Technologies Utilisées

- **Django** : Framework web pour Python
- **TensorFlow/Keras** : Framework d'apprentissage automatique
- **HTML/CSS/Bootstrap** : Conception frontend
- **SQLite** : Base de données pour le développement
- **MySQL** : Base de données pour les données de l'application (via WAMP)

## Installation

1. Cloner le dépôt :
   ```
   git clone <url-du-dépôt>
   ```

2. Naviguer vers le répertoire du projet :
   ```
   cd dog_breed_identifier
   ```

3. Créer un environnement virtuel :
   ```
   python -m venv venv
   source venv/bin/activate  # Sur Windows : venv\Scripts\activate
   ```

4. Installer les dépendances :
   ```
   pip install -r requirements.txt
   ```

5. Exécuter les migrations de base de données :
   ```
   python manage.py migrate
   ```

6. Créer un superutilisateur (optionnel) :
   ```
   python manage.py createsuperuser
   ```

7. Initialiser les races de chiens dans la base de données :
   ```
   python manage.py init_breeds
   ```

8. Exécuter le serveur de développement :
   ```
   python manage.py runserver
   ```

9. Visiter `http://127.0.0.1:8000` dans votre navigateur

## Structure du Projet

```
dog_breed_identifier/
├── classifier/              # Application Django principale
│   ├── models.py           # Modèles de base de données
│   ├── views.py            # Fonctions de vue
│   ├── urls.py             # Routage d'URL
│   └── templates/          # Modèles HTML
├── dog_identifier/         # Paramètres du projet Django
├── ml_models/              # Modèles d'apprentissage automatique
├── static/                 # Fichiers statiques (CSS, JS, images)
├── templates/              # Modèles de base
├── manage.py              # Script de gestion Django
└── requirements.txt       # Dépendances Python
```

## Modèle d'Apprentissage Automatique

L'application utilise un réseau neuronal convolutionnel (CNN) entraîné sur le Stanford Dogs Dataset pour identifier les races de chiens. Le modèle peut identifier plus de 120 races de chiens différentes et leurs pays d'origine.

## Modèles de Base de Données

1. **DogBreed** : Stocke les informations sur les races de chiens
   - Nom
   - Pays d'origine
   - Description
   - Taille
   - Groupe
   - Espérance de vie
   - Tempérament

2. **UploadedImage** : Stocke les images téléchargées et les résultats de prédiction
   - Fichier image
   - Horodatage du téléchargement
   - Race prédite (clé étrangère)
   - Score de confiance
   - Prédictions alternatives

## Configuration de Base de Données Double

Cette application utilise une configuration de base de données double :
- **SQLite** : Utilisé comme base de données par défaut pour les applications intégrées de Django (admin, auth, sessions, etc.)
- **MySQL** : Utilisé pour les données spécifiques à l'application (races de chiens, images téléchargées) via WAMP Server

## Déploiement

### Déploiement sur Render

1. Créez un compte sur [Render](https://dashboard.render.com/)
2. Créez un nouveau service web et connectez-le à votre dépôt GitHub/GitLab
3. Configurez les variables d'environnement :
   - `SECRET_KEY` : Votre clé secrète Django
   - `DATABASE_URL` : URL de votre base de données (fournie par Render)
4. Render déploiera automatiquement votre application après chaque push

### Déploiement sur Dokploy

1. Créez un compte sur [Dokploy](https://app.dokploy.com/dashboard/projects)
2. Créez un nouveau projet et connectez-le à votre dépôt
3. Configurez les variables d'environnement dans l'interface Dokploy
4. Dokploy déploiera automatiquement votre application après chaque push

### Configuration CI/CD

Le projet inclut des configurations pour :
- GitHub Actions (dans `.github/workflows/`)
- GitLab CI/CD (dans `.gitlab-ci.yml`)

Ces workflows exécutent automatiquement les tests et déploient l'application sur Render et Dokploy.

## Entraînement Automatique

L'application comprend un système d'entraînement automatique qui :

1. **Collecte automatiquement de nouvelles données** : Télécharge des images de races de chiens à partir d'API en ligne
2. **Équilibre le dataset** : S'assure qu'il y a un nombre suffisant d'images pour chaque race
3. **Entraîne périodiquement le modèle** : Met à jour le modèle d'apprentissage automatique avec de nouvelles données
4. **Surveille les performances** : Suit l'exactitude du modèle et déclenche un nouvel entraînement si nécessaire

### Exécution de l'entraînement manuel

Pour entraîner manuellement le modèle :
```
python manage.py auto_train
```

### Configuration des tâches planifiées

Vous pouvez configurer des tâches planifiées pour exécuter l'entraînement automatique périodiquement :

**Sur Linux/macOS (cron)** :
```
# Exécuter l'entraînement tous les jours à 2h du matin
0 2 * * * /path/to/project/scripts/run_auto_train.sh
```

**Sur Windows (Planificateur de tâches)** :
1. Ouvrez le Planificateur de tâches
2. Créez une nouvelle tâche
3. Configurez-la pour exécuter `scripts/run_auto_train.ps1` périodiquement

## Améliorations Futures

- Mettre en œuvre un modèle CNN plus sophistiqué
- Ajouter davantage de races de chiens à la base de données
- Améliorer l'interface utilisateur avec des fonctionnalités supplémentaires
- Ajouter des comptes d'utilisateurs et l'historique des images
- Mettre en œuvre le traitement par lots pour plusieurs images
- Améliorer la collecte de données avec des sources plus variées
- Implémenter des techniques d'augmentation d'images pour améliorer la robustesse du modèle

## Licence

Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.

## Remerciements

- Stanford Dogs Dataset pour avoir fourni les données d'entraînement
- Communautés Django et TensorFlow pour une documentation excellente

## Mise à jour du Déploiement

Cette mise à jour corrige les problèmes de déploiement précédents en utilisant correctement le fichier Dockerfile avec Render.

## Notes de Déploiement

**Dernière mise à jour :** Le déploiement fonctionne maintenant correctement avec Docker sur Render. Tous les fichiers nécessaires sont présents dans le dépôt.