# Guide de Contribution

## Bienvenue !

Merci de votre intérêt pour contribuer au projet Dog Breed Identifier ! Ce guide vous aidera à comprendre comment contribuer efficacement.

## Code de Conduite

En contribuant à ce projet, vous acceptez de respecter notre Code de Conduite qui promeut un environnement ouvert et accueillant pour tous.

## Comment Contribuer

### Signaler des Bugs

1. Vérifiez que le bug n'a pas déjà été signalé
2. Créez une nouvelle issue avec une description détaillée
3. Incluez des étapes pour reproduire le bug
4. Ajoutez des captures d'écran si possible

### Proposer des Améliorations

1. Créez une issue décrivant l'amélioration
2. Expliquez pourquoi cette amélioration serait bénéfique
3. Discutez de l'implémentation potentielle

### Soumettre du Code

1. Forkez le dépôt
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/ma-fonctionnalite`)
3. Commitez vos changements (`git commit -am 'Ajout d'une nouvelle fonctionnalité'`)
4. Poussez vers la branche (`git push origin feature/ma-fonctionnalite`)
5. Créez une Pull Request

## Standards de Codage

### Python

- Suivez le PEP 8
- Utilisez des docstrings pour documenter les fonctions et classes
- Écrivez des tests pour le nouveau code
- Gardez les fonctions courtes et focalisées

### JavaScript/CSS

- Utilisez un style cohérent
- Commentez le code complexe
- Suivez les meilleures pratiques web

### Documentation

- Mettez à jour la documentation quand vous modifiez le code
- Utilisez un français clair et correct
- Structurez la documentation de manière logique

## Processus de Revue

1. Toute Pull Request doit être revue par au moins un mainteneur
2. Les tests doivent passer
3. Le code doit respecter les standards de qualité
4. La documentation doit être mise à jour si nécessaire

## Environnement de Développement

### Prérequis

- Python 3.8+
- Docker
- Node.js (pour le frontend)
- Git

### Configuration

```bash
# Clonez le dépôt
git clone https://github.com/votre-nom/IA-chien.git
cd IA-chien

# Créez un environnement virtuel
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# ou
.venv\Scripts\activate     # Windows

# Installez les dépendances
pip install -r requirements.txt
pip install -r dev-requirements.txt

# Configurez les variables d'environnement
cp .env .env.local
# Éditez .env.local avec vos identifiants

# Lancez l'application
docker-compose up
```

## Tests

### Exécuter les Tests

```bash
# Tests unitaires
python manage.py test

# Tests avec coverage
coverage run --source='.' manage.py test

# Tests Docker
./scripts/run_tests.sh
```

### Écrire des Tests

- Utilisez pytest pour les nouveaux tests
- Couvrez les cas normaux et les cas d'erreur
- Utilisez des fixtures pour les données de test
- Gardez les tests indépendants

## Documentation

### Mettre à Jour la Documentation

- Mettez à jour les fichiers dans `/docs`
- Ajoutez des exemples de code
- Expliquez les concepts complexes
- Maintenez la structure cohérente

## Questions ?

Si vous avez des questions, n'hésitez pas à créer une issue ou à contacter l'équipe de maintenance.