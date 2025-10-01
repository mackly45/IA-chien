"""
Settings de test pour l'application Django.
"""

import os
from dog_identifier.settings import *

# Utiliser une base de données en mémoire pour les tests
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
    }
}

# Désactiver le système d'email pour les tests
EMAIL_BACKEND = 'django.core.mail.backends.locmem.EmailBackend'

# Désactiver le debug pour les tests
DEBUG = False

# Clé secrète pour les tests
SECRET_KEY = 'test-secret-key-for-testing-purposes-only'

# Désactiver les migrations pour accélérer les tests
class DisableMigrations:
    def __contains__(self, item):
        return True
    
    def __getitem__(self, item):
        return None

MIGRATION_MODULES = DisableMigrations()

# Configuration du stockage pour les tests
DEFAULT_FILE_STORAGE = 'django.core.files.storage.FileSystemStorage'
MEDIA_ROOT = os.path.join(os.path.dirname(__file__), 'test_media')
MEDIA_URL = '/media/'

# Désactiver les collectstatic pendant les tests
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.StaticFilesStorage'