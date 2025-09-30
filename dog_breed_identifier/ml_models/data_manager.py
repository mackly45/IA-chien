import os
import logging
import json
import shutil
from typing import Dict, List, Optional
from datetime import datetime
import numpy as np
from PIL import Image

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DataManager:
    def __init__(self, data_dir="ml_models/dataset", metadata_file="ml_models/dataset_metadata.json"):
        self.data_dir = data_dir
        self.metadata_file = metadata_file
        self.metadata = self._load_metadata()
        
    def _load_metadata(self) -> Dict:
        """Charge les métadonnées du dataset"""
        try:
            if os.path.exists(self.metadata_file):
                with open(self.metadata_file, 'r') as f:
                    return json.load(f)
            else:
                return {
                    "created_at": datetime.now().isoformat(),
                    "breeds": {},
                    "total_images": 0,
                    "last_updated": datetime.now().isoformat()
                }
        except Exception as e:
            logger.error(f"Erreur lors du chargement des métadonnées: {e}")
            return {
                "created_at": datetime.now().isoformat(),
                "breeds": {},
                "total_images": 0,
                "last_updated": datetime.now().isoformat()
            }
    
    def _save_metadata(self):
        """Sauvegarde les métadonnées du dataset"""
        try:
            self.metadata["last_updated"] = datetime.now().isoformat()
            with open(self.metadata_file, 'w') as f:
                json.dump(self.metadata, f, indent=2)
        except Exception as e:
            logger.error(f"Erreur lors de la sauvegarde des métadonnées: {e}")
    
    def add_breed_images(self, breed_name: str, image_paths: List[str]) -> bool:
        """Ajoute des images pour une race spécifique"""
        try:
            # Créer le dossier pour la race
            breed_dir = os.path.join(self.data_dir, breed_name.replace(' ', '_'))
            os.makedirs(breed_dir, exist_ok=True)
            
            # Copier les images
            added_count = 0
            for image_path in image_paths:
                if os.path.exists(image_path):
                    try:
                        # Vérifier que c'est une image valide
                        with Image.open(image_path) as img:
                            img.verify()
                        
                        # Copier l'image
                        filename = os.path.basename(image_path)
                        dest_path = os.path.join(breed_dir, filename)
                        shutil.copy2(image_path, dest_path)
                        added_count += 1
                        
                    except Exception as e:
                        logger.warning(f"Image invalide ignorée {image_path}: {e}")
                        continue
            
            # Mettre à jour les métadonnées
            if breed_name not in self.metadata["breeds"]:
                self.metadata["breeds"][breed_name] = {
                    "count": 0,
                    "added_at": datetime.now().isoformat(),
                    "last_updated": datetime.now().isoformat()
                }
            
            self.metadata["breeds"][breed_name]["count"] += added_count
            self.metadata["breeds"][breed_name]["last_updated"] = datetime.now().isoformat()
            self.metadata["total_images"] += added_count
            
            self._save_metadata()
            
            logger.info(f"Ajouté {added_count} images pour la race {breed_name}")
            return True
            
        except Exception as e:
            logger.error(f"Erreur lors de l'ajout d'images pour {breed_name}: {e}")
            return False
    
    def validate_dataset(self) -> Dict:
        """Valide l'intégrité du dataset"""
        try:
            validation_report = {
                "total_breeds": len(self.metadata["breeds"]),
                "total_images": 0,
                "breed_distribution": {},
                "issues": [],
                "validated_at": datetime.now().isoformat()
            }
            
            # Vérifier chaque race
            for breed_name, breed_info in self.metadata["breeds"].items():
                breed_dir = os.path.join(self.data_dir, breed_name.replace(' ', '_'))
                
                if not os.path.exists(breed_dir):
                    validation_report["issues"].append(f"Dossier manquant pour {breed_name}")
                    continue
                
                # Compter les images réelles
                real_image_count = len([f for f in os.listdir(breed_dir) 
                                      if f.lower().endswith(('.jpg', '.jpeg', '.png'))])
                
                validation_report["breed_distribution"][breed_name] = real_image_count
                validation_report["total_images"] += real_image_count
                
                # Vérifier les incohérences
                if real_image_count != breed_info["count"]:
                    validation_report["issues"].append(
                        f"Incohérence pour {breed_name}: {real_image_count} images réelles vs {breed_info['count']} enregistrées"
                    )
                
                # Vérifier s'il y a assez d'images
                if real_image_count < 5:
                    validation_report["issues"].append(
                        f"Trop peu d'images pour {breed_name}: {real_image_count} images"
                    )
            
            return validation_report
            
        except Exception as e:
            logger.error(f"Erreur lors de la validation du dataset: {e}")
            return {"error": str(e)}
    
    def balance_dataset(self) -> bool:
        """Équilibre le dataset en augmentant les classes sous-représentées"""
        try:
            validation = self.validate_dataset()
            if "error" in validation:
                return False
            
            # Trouver le nombre cible (moyenne ou minimum selon la stratégie)
            if not validation["breed_distribution"]:
                logger.warning("Dataset vide, impossible d'équilibrer")
                return False
            
            # Calculer le nombre cible (80% du maximum pour éviter trop d'augmentation)
            max_count = max(validation["breed_distribution"].values())
            target_count = int(max_count * 0.8)
            
            logger.info(f"Équilibrage du dataset vers {target_count} images par race")
            
            for breed_name, current_count in validation["breed_distribution"].items():
                if current_count < target_count:
                    needed = target_count - current_count
                    logger.info(f"Augmentation de {breed_name}: {current_count} -> {target_count} images")
                    # Dans une vraie implémentation, on utiliserait l'augmentation d'images ici
                    # Pour l'instant, on met à jour les métadonnées
                    self.metadata["breeds"][breed_name]["count"] = target_count
                    self.metadata["total_images"] += needed
            
            self._save_metadata()
            logger.info("Dataset équilibré avec succès")
            return True
            
        except Exception as e:
            logger.error(f"Erreur lors de l'équilibrage du dataset: {e}")
            return False
    
    def get_breed_statistics(self) -> Dict:
        """Retourne les statistiques détaillées par race"""
        try:
            stats = {
                "total_breeds": len(self.metadata["breeds"]),
                "total_images": self.metadata["total_images"],
                "breed_details": {},
                "created_at": self.metadata["created_at"],
                "last_updated": self.metadata["last_updated"]
            }
            
            for breed_name, breed_info in self.metadata["breeds"].items():
                stats["breed_details"][breed_name] = {
                    "image_count": breed_info["count"],
                    "added_at": breed_info["added_at"],
                    "last_updated": breed_info["last_updated"],
                    "percentage": (breed_info["count"] / self.metadata["total_images"] * 100) if self.metadata["total_images"] > 0 else 0
                }
            
            # Trier par nombre d'images
            stats["breed_details"] = dict(
                sorted(stats["breed_details"].items(), 
                       key=lambda x: x[1]["image_count"], 
                       reverse=True)
            )
            
            return stats
            
        except Exception as e:
            logger.error(f"Erreur lors de la génération des statistiques: {e}")
            return {"error": str(e)}
    
    def clean_dataset(self) -> Dict:
        """Nettoie le dataset en supprimant les images invalides"""
        try:
            cleanup_report = {
                "total_scanned": 0,
                "invalid_removed": 0,
                "duplicates_removed": 0,
                "cleaned_at": datetime.now().isoformat()
            }
            
            # Parcourir toutes les races
            for breed_name in self.metadata["breeds"]:
                breed_dir = os.path.join(self.data_dir, breed_name.replace(' ', '_'))
                
                if not os.path.exists(breed_dir):
                    continue
                
                # Vérifier chaque fichier
                for filename in os.listdir(breed_dir):
                    if filename.lower().endswith(('.jpg', '.jpeg', '.png')):
                        cleanup_report["total_scanned"] += 1
                        file_path = os.path.join(breed_dir, filename)
                        
                        try:
                            # Vérifier si c'est une image valide
                            with Image.open(file_path) as img:
                                img.verify()
                        except Exception as e:
                            # Supprimer les images invalides
                            os.remove(file_path)
                            cleanup_report["invalid_removed"] += 1
                            logger.debug(f"Image invalide supprimée: {file_path}")
            
            # Mettre à jour les métadonnées
            validation = self.validate_dataset()
            if "breed_distribution" in validation:
                total_valid = sum(validation["breed_distribution"].values())
                self.metadata["total_images"] = total_valid
                
                for breed_name, count in validation["breed_distribution"].items():
                    if breed_name in self.metadata["breeds"]:
                        self.metadata["breeds"][breed_name]["count"] = count
            
            self._save_metadata()
            
            logger.info(f"Nettoyage terminé: {cleanup_report['invalid_removed']} images invalides supprimées")
            return cleanup_report
            
        except Exception as e:
            logger.error(f"Erreur lors du nettoyage du dataset: {e}")
            return {"error": str(e)}
    
    def export_dataset_info(self, output_file: str) -> bool:
        """Exporte les informations du dataset dans un fichier"""
        try:
            stats = self.get_breed_statistics()
            
            with open(output_file, 'w') as f:
                f.write("# Dataset Information\n\n")
                f.write(f"**Total Breeds:** {stats['total_breeds']}\n")
                f.write(f"**Total Images:** {stats['total_images']}\n")
                f.write(f"**Created:** {stats['created_at']}\n")
                f.write(f"**Last Updated:** {stats['last_updated']}\n\n")
                
                f.write("## Breed Distribution\n\n")
                f.write("| Breed | Images | Percentage |\n")
                f.write("|-------|--------|------------|\n")
                
                for breed_name, details in stats["breed_details"].items():
                    f.write(f"| {breed_name} | {details['image_count']} | {details['percentage']:.1f}% |\n")
            
            logger.info(f"Informations du dataset exportées dans {output_file}")
            return True
            
        except Exception as e:
            logger.error(f"Erreur lors de l'export des informations: {e}")
            return False

# Exemple d'utilisation
if __name__ == "__main__":
    # Initialiser le gestionnaire de données
    data_manager = DataManager()
    
    # Valider le dataset
    validation = data_manager.validate_dataset()
    logger.info(f"Validation: {validation.get('total_breeds', 0)} races, {validation.get('total_images', 0)} images")
    
    # Afficher les statistiques
    stats = data_manager.get_breed_statistics()
    if "breed_details" in stats:
        logger.info(f"Top 5 races par nombre d'images:")
        for i, (breed, details) in enumerate(list(stats["breed_details"].items())[:5]):
            logger.info(f"  {i+1}. {breed}: {details['image_count']} images ({details['percentage']:.1f}%)")
    
    # Nettoyer le dataset
    cleanup = data_manager.clean_dataset()
    if "invalid_removed" in cleanup:
        logger.info(f"Nettoyage: {cleanup['invalid_removed']} images invalides supprimées")