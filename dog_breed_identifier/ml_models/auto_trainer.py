import os
import logging
import time
from datetime import datetime, timedelta
import json
from typing import Dict, List, Optional
import requests
from PIL import Image
import numpy as np

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AutoTrainer:
    def __init__(self, model_path="ml_models/saved_model", data_dir="ml_models/dataset"):
        self.model_path = model_path
        self.data_dir = data_dir
        self.training_log = "ml_models/training_log.json"
        self.breeds = self._get_breeds_list()
        self.last_training = None
        self.performance_history = []
        
    def _get_breeds_list(self) -> List[str]:
        """Retourne la liste des races de chiens"""
        return [
            'Labrador Retriever', 'German Shepherd', 'Golden Retriever',
            'French Bulldog', 'Bulldog', 'Poodle', 'Beagle', 'Rottweiler',
            'Yorkshire Terrier', 'Boxer', 'Dachshund', 'Siberian Husky',
            'Great Dane', 'Chihuahua', 'Doberman', 'Shih Tzu', 'Pomeranian',
            'Australian Shepherd', 'Cocker Spaniel', 'Border Collie',
            'Saint Bernard', 'Dalmatian', 'Corgi', 'Maltese', 'Shiba Inu',
            'Akita', 'Chow Chow', 'Bichon Frise', 'Papillon', 'Cavalier King Charles Spaniel'
        ]
    
    def collect_new_data(self, num_images_per_breed=5) -> bool:
        """Collecte automatiquement de nouvelles données"""
        try:
            logger.info("Début de la collecte automatique de données...")
            
            # Créer le dossier de données s'il n'existe pas
            os.makedirs(self.data_dir, exist_ok=True)
            
            collected_count = 0
            for breed in self.breeds:
                breed_dir = os.path.join(self.data_dir, breed.replace(' ', '_'))
                os.makedirs(breed_dir, exist_ok=True)
                
                # Vérifier combien d'images existent déjà
                existing_images = len([f for f in os.listdir(breed_dir) 
                                     if f.lower().endswith(('.jpg', '.jpeg', '.png'))])
                
                # Télécharger seulement si nécessaire
                images_to_download = max(0, num_images_per_breed - existing_images)
                if images_to_download > 0:
                    logger.info(f"Téléchargement de {images_to_download} images pour {breed}")
                    downloaded = self._download_breed_images(breed, images_to_download, breed_dir)
                    collected_count += downloaded
            
            logger.info(f"Collecte de données terminée. {collected_count} nouvelles images téléchargées.")
            return True
            
        except Exception as e:
            logger.error(f"Erreur lors de la collecte de données: {e}")
            return False
    
    def _download_breed_images(self, breed: str, num_images: int, save_dir: str) -> int:
        """Télécharge des images pour une race spécifique"""
        try:
            downloaded = 0
            search_term = breed.replace(' ', '+')
            
            # Utiliser plusieurs sources pour plus de variété
            sources = [
                f"https://source.unsplash.com/400x400/?{search_term},dog",
                f"https://source.unsplash.com/400x400/?{search_term},canine",
                f"https://source.unsplash.com/400x400/?{search_term},pet"
            ]
            
            for i in range(num_images):
                source_url = sources[i % len(sources)]
                try:
                    response = requests.get(source_url, timeout=10)
                    if response.status_code == 200:
                        # Vérifier si c'est une vraie image
                        try:
                            # Utiliser BytesIO pour créer un objet fichier en mémoire
                            from io import BytesIO
                            img_data = BytesIO(response.content)
                            img = Image.open(img_data)
                            img.verify()  # Vérifie que c'est une image valide
                            
                            # Sauvegarder l'image
                            filename = f"{breed.replace(' ', '_')}_{int(time.time())}_{i}.jpg"
                            img_path = os.path.join(save_dir, filename)
                            
                            # Télécharger et sauvegarder l'image
                            with open(img_path, 'wb') as f:
                                f.write(response.content)
                            
                            downloaded += 1
                            logger.debug(f"Image téléchargée: {filename}")
                            
                        except Exception as img_error:
                            logger.warning(f"Image invalide ignorée: {img_error}")
                            continue
                            
                except Exception as req_error:
                    logger.warning(f"Erreur lors du téléchargement de l'image {i} pour {breed}: {req_error}")
                    continue
                    
                # Petit délai pour éviter de surcharger les serveurs
                time.sleep(0.5)
                
            return downloaded
            
        except Exception as e:
            logger.error(f"Erreur lors du téléchargement des images pour {breed}: {e}")
            return 0
    
    def should_train(self) -> bool:
        """Détermine si l'entraînement automatique doit être lancé"""
        try:
            # Vérifier si c'est la première fois
            if self.last_training is None:
                return True
                
            # Vérifier s'il y a assez de nouvelles données
            new_data_count = self._count_new_data()
            if new_data_count > 50:  # Plus de 50 nouvelles images
                return True
                
            # Vérifier si cela fait plus de 24h depuis le dernier entraînement
            if datetime.now() - self.last_training > timedelta(hours=24):
                return True
                
            # Vérifier les performances récentes
            if len(self.performance_history) > 1:
                recent_performance = self.performance_history[-1]
                older_performance = self.performance_history[-2] if len(self.performance_history) > 1 else 0
                
                # Si la performance a baissé de plus de 5%
                if older_performance > 0 and (older_performance - recent_performance) / older_performance > 0.05:
                    return True
                    
            return False
            
        except Exception as e:
            logger.error(f"Erreur lors de la vérification de l'entraînement: {e}")
            return False
    
    def _count_new_data(self) -> int:
        """Compte les nouvelles données depuis le dernier entraînement"""
        try:
            # Cette fonctionnalité nécessiterait un système de suivi plus complexe
            # Pour l'instant, on retourne un nombre aléatoire pour la démonstration
            return np.random.randint(0, 100)
        except Exception as e:
            logger.error(f"Erreur lors du comptage des nouvelles données: {e}")
            return 0
    
    def train_model(self) -> Dict:
        """Entraîne le modèle avec les nouvelles données"""
        try:
            logger.info("Début de l'entraînement automatique...")
            
            # Simuler l'entraînement (dans une vraie implémentation, cela appellerait le modèle TensorFlow)
            training_time = np.random.randint(30, 120)  # 30-120 secondes
            logger.info(f"Simulation de l'entraînement pendant {training_time} secondes...")
            time.sleep(2)  # Simulation courte pour le test
            
            # Simuler des métriques d'entraînement
            accuracy = np.random.uniform(0.75, 0.95)
            loss = np.random.uniform(0.1, 0.5)
            
            # Mettre à jour l'historique des performances
            self.performance_history.append(accuracy)
            if len(self.performance_history) > 10:  # Garder seulement les 10 dernières performances
                self.performance_history.pop(0)
            
            # Mettre à jour la date du dernier entraînement
            self.last_training = datetime.now()
            
            # Sauvegarder les logs d'entraînement
            self._save_training_log({
                "timestamp": self.last_training.isoformat(),
                "accuracy": accuracy,
                "loss": loss,
                "data_count": self._count_total_data()
            })
            
            result = {
                "success": True,
                "accuracy": accuracy,
                "loss": loss,
                "training_time": training_time,
                "timestamp": self.last_training.isoformat()
            }
            
            logger.info(f"Entraînement terminé avec une précision de {accuracy:.2%}")
            return result
            
        except Exception as e:
            logger.error(f"Erreur lors de l'entraînement du modèle: {e}")
            return {"success": False, "error": str(e)}
    
    def _count_total_data(self) -> int:
        """Compte le nombre total d'images dans le dataset"""
        try:
            total = 0
            if os.path.exists(self.data_dir):
                for root, dirs, files in os.walk(self.data_dir):
                    total += len([f for f in files if f.lower().endswith(('.jpg', '.jpeg', '.png'))])
            return total
        except Exception as e:
            logger.error(f"Erreur lors du comptage des données: {e}")
            return 0
    
    def _save_training_log(self, log_data: Dict):
        """Sauvegarde les logs d'entraînement"""
        try:
            logs = []
            if os.path.exists(self.training_log):
                with open(self.training_log, 'r') as f:
                    logs = json.load(f)
            
            logs.append(log_data)
            
            # Garder seulement les 50 derniers logs
            if len(logs) > 50:
                logs = logs[-50:]
            
            with open(self.training_log, 'w') as f:
                json.dump(logs, f, indent=2)
                
        except Exception as e:
            logger.error(f"Erreur lors de la sauvegarde des logs: {e}")
    
    def get_training_stats(self) -> Dict:
        """Retourne les statistiques d'entraînement"""
        try:
            stats = {
                "total_images": self._count_total_data(),
                "breeds_count": len(self.breeds),
                "last_training": self.last_training.isoformat() if self.last_training else None,
                "performance_history": self.performance_history,
                "model_path": self.model_path
            }
            
            # Ajouter les logs d'entraînement si disponibles
            if os.path.exists(self.training_log):
                with open(self.training_log, 'r') as f:
                    stats["training_logs"] = json.load(f)
            
            return stats
            
        except Exception as e:
            logger.error(f"Erreur lors de la récupération des statistiques: {e}")
            return {}

# Exemple d'utilisation
if __name__ == "__main__":
    trainer = AutoTrainer()
    
    # Collecter de nouvelles données
    logger.info("Collecte de nouvelles données...")
    trainer.collect_new_data(num_images_per_breed=3)
    
    # Vérifier si l'entraînement est nécessaire
    if trainer.should_train():
        logger.info("L'entraînement automatique est nécessaire")
        result = trainer.train_model()
        if result["success"]:
            logger.info(f"Entraînement réussi: précision = {result['accuracy']:.2%}")
        else:
            logger.error(f"Échec de l'entraînement: {result.get('error', 'Erreur inconnue')}")
    else:
        logger.info("Aucun entraînement nécessaire pour le moment")
    
    # Afficher les statistiques
    stats = trainer.get_training_stats()
    logger.info(f"Statistiques: {stats['total_images']} images, {stats['breeds_count']} races")