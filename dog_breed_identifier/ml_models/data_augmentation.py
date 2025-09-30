import os
import requests
from PIL import Image
from io import BytesIO
import numpy as np
import logging

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DataAugmenter:
    def __init__(self, data_dir='ml_models/dataset'):
        self.data_dir = data_dir
        # Vérifier si TensorFlow est disponible
        self.tf_available = self._check_tensorflow()
        self.datagen = None
        
    def _check_tensorflow(self):
        """Vérifie si TensorFlow est disponible"""
        try:
            import tensorflow as tf
            logger.info("TensorFlow trouvé")
            return True
        except ImportError:
            logger.warning("TensorFlow non trouvé - certaines fonctionnalités seront désactivées")
            return False
    
    def augment_images(self, image_path, save_dir, num_augmented=5):
        """Augmente les images existantes"""
        if not self.tf_available or self.datagen is None:
            logger.warning("TensorFlow non disponible - augmentation d'images désactivée")
            return
            
        try:
            # Pour l'instant, nous n'implémentons pas l'augmentation d'images sans TensorFlow
            logger.warning("L'augmentation d'images nécessite TensorFlow")
        except Exception as e:
            logger.error(f"Erreur lors de l'augmentation des images: {e}")
            
    def download_breed_images(self, breed_name, num_images=10):
        """Télécharge des images pour une race spécifique"""
        try:
            # Créer le dossier pour la race
            breed_dir = os.path.join(self.data_dir, breed_name)
            os.makedirs(breed_dir, exist_ok=True)
            
            # Utiliser l'API Unsplash pour télécharger des images
            # Note: Vous devrez obtenir une clé API Unsplash pour une utilisation intensive
            search_url = f"https://source.unsplash.com/400x400/?{breed_name},dog"
            
            for i in range(num_images):
                response = requests.get(search_url)
                if response.status_code == 200:
                    img = Image.open(BytesIO(response.content))
                    img.save(os.path.join(breed_dir, f"{breed_name}_{i}.jpg"))
                    
            logger.info(f"Téléchargé {num_images} images pour {breed_name}")
        except Exception as e:
            logger.error(f"Erreur lors du téléchargement des images: {e}")

# Liste étendue de races de chiens
BREEDS = [
    'Labrador Retriever', 'German Shepherd', 'Golden Retriever',
    'French Bulldog', 'Bulldog', 'Poodle', 'Beagle', 'Rottweiler',
    'Yorkshire Terrier', 'Boxer', 'Dachshund', 'Siberian Husky',
    'Great Dane', 'Chihuahua', 'Doberman', 'Shih Tzu', 'Pomeranian',
    'Australian Shepherd', 'Cocker Spaniel', 'Border Collie',
    'Saint Bernard', 'Dalmatian', 'Corgi', 'Maltese', 'Shiba Inu',
    'Akita', 'Chow Chow', 'Bichon Frise', 'Papillon', 'Cavalier King Charles Spaniel'
]

if __name__ == "__main__":
    augmenter = DataAugmenter()
    
    # Télécharger des images pour chaque race
    for breed in BREEDS:
        logger.info(f"Téléchargement des images pour {breed}")
        augmenter.download_breed_images(breed.replace(' ', '-'), 5)