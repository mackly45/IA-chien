import os
import logging
import time
import json
from typing import Dict, List, Optional, Tuple
import requests
from PIL import Image
import numpy as np
from concurrent.futures import ThreadPoolExecutor, as_completed
import random

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ComprehensiveDataCollector:
    def __init__(self, data_dir="ml_models/dataset"):
        self.data_dir = data_dir
        self.breeds = self._get_comprehensive_breeds_list()
        self.collected_stats = {}
        
    def _get_comprehensive_breeds_list(self) -> List[str]:
        """Retourne une liste complète des races de chiens"""
        return [
            # Races populaires
            'Labrador Retriever', 'German Shepherd', 'Golden Retriever',
            'French Bulldog', 'Bulldog', 'Poodle', 'Beagle', 'Rottweiler',
            'Yorkshire Terrier', 'Boxer', 'Dachshund', 'Siberian Husky',
            'Great Dane', 'Chihuahua', 'Doberman', 'Shih Tzu', 'Pomeranian',
            'Australian Shepherd', 'Cocker Spaniel', 'Border Collie',
            'Saint Bernard', 'Dalmatian', 'Corgi', 'Maltese', 'Shiba Inu',
            'Akita', 'Chow Chow', 'Bichon Frise', 'Papillon', 'Cavalier King Charles Spaniel',
            
            # Races supplémentaires
            'Basset Hound', 'Bloodhound', 'Boston Terrier', 'Bull Terrier',
            'Cane Corso', 'Collie', 'English Setter', 'English Springer Spaniel',
            'German Shorthaired Pointer', 'Giant Schnauzer', 'Irish Setter',
            'Italian Greyhound', 'Keeshond', 'Komondor', 'Leonberger',
            'Lhasa Apso', 'Mastiff', 'Newfoundland', 'Norwegian Elkhound',
            'Nova Scotia Duck Tolling Retriever', 'Old English Sheepdog',
            'Pembroke Welsh Corgi', 'Pharaoh Hound', 'Plott', 'Pointer',
            'Portuguese Water Dog', 'Pug', 'Rhodesian Ridgeback', 'Saluki',
            'Samoyed', 'Scottish Terrier', 'Sealyham Terrier', 'Shetland Sheepdog',
            'Smooth Fox Terrier', 'Tibetan Mastiff', 'Tibetan Spaniel', 'Tibetan Terrier',
            'Toy Fox Terrier', 'Vizsla', 'Weimaraner', 'Welsh Springer Spaniel',
            'West Highland White Terrier', 'Whippet', 'Wire Fox Terrier', 'Wirehaired Pointing Griffon',
            
            # Races supplémentaires 2
            'Afghan Hound', 'Airedale Terrier', 'Alaskan Malamute', 'American Bulldog',
            'American Cocker Spaniel', 'American Eskimo Dog', 'American Foxhound',
            'American Pit Bull Terrier', 'American Staffordshire Terrier',
            'American Water Spaniel', 'Anatolian Shepherd Dog', 'Australian Cattle Dog',
            'Australian Kelpie', 'Australian Terrier', 'Basenji', 'Basset Griffon Vendeen',
            'Belgian Malinois', 'Belgian Sheepdog', 'Belgian Tervuren', 'Bergamasco',
            'Berger Picard', 'Bernese Mountain Dog', 'Bichon Frise', 'Black and Tan Coonhound',
            'Black Russian Terrier', 'Bluetick Coonhound', 'Boerboel', 'Bolognese',
            'Border Terrier', 'Borzoi', 'Boston Terrier', 'Bouvier des Flandres',
            'Boykin Spaniel', 'Bracco Italiano', 'Briard', 'Brittany', 'Brussels Griffon',
            'Bull Terrier', 'Bullmastiff', 'Cairn Terrier', 'Canaan Dog', 'Cane Corso',
            'Cardigan Welsh Corgi', 'Cesky Terrier', 'Chesapeake Bay Retriever',
            'Chinese Crested', 'Chinese Shar-Pei', 'Chinook', 'Chow Chow',
            'Cirneco dell\'Etna', 'Clumber Spaniel', 'Cockapoo', 'Coton de Tulear',
            'Curly Coated Retriever', 'Dachshund', 'Dalmatian', 'Dandie Dinmont Terrier',
            'Doberman Pinscher', 'Dogo Argentino', 'Dogue de Bordeaux', 'English Bulldog',
            'English Cocker Spaniel', 'English Foxhound', 'English Mastiff',
            'English Setter', 'English Springer Spaniel', 'English Toy Spaniel',
            'Entlebucher Mountain Dog', 'Field Spaniel', 'Finnish Lapphund',
            'Finnish Spitz', 'Flat-Coated Retriever', 'Fox Terrier', 'French Bulldog',
            'German Pinscher', 'German Shepherd Dog', 'German Shorthaired Pointer',
            'German Wirehaired Pointer', 'Giant Schnauzer', 'Glen of Imaal Terrier',
            'Golden Retriever', 'Gordon Setter', 'Great Dane', 'Great Pyrenees',
            'Greater Swiss Mountain Dog', 'Greyhound', 'Harrier', 'Havanese',
            'Icelandic Sheepdog', 'Irish Red and White Setter', 'Irish Setter',
            'Irish Terrier', 'Irish Water Spaniel', 'Irish Wolfhound', 'Italian Greyhound',
            'Japanese Chin', 'Japanese Spitz', 'Keeshond', 'Kerry Blue Terrier',
            'Komondor', 'Kuvasz', 'Labrador Retriever', 'Lagotto Romagnolo',
            'Lakeland Terrier', 'Leonberger', 'Lhasa Apso', 'Lowchen', 'Maltese',
            'Manchester Terrier', 'Maremma Sheepdog', 'Mastiff', 'Miniature American Shepherd',
            'Miniature Bull Terrier', 'Miniature Pinscher', 'Miniature Schnauzer',
            'Neapolitan Mastiff', 'Newfoundland', 'Norfolk Terrier', 'Norwegian Buhund',
            'Norwegian Elkhound', 'Norwegian Lundehund', 'Norwich Terrier',
            'Nova Scotia Duck Tolling Retriever', 'Old English Sheepdog',
            'Otterhound', 'Papillon', 'Parson Russell Terrier', 'Pekingese',
            'Pembroke Welsh Corgi', 'Petit Basset Griffon Vendeen', 'Pharaoh Hound',
            'Plott', 'Pointer', 'Polish Lowland Sheepdog', 'Pomeranian',
            'Poodle', 'Portuguese Podengo', 'Portuguese Water Dog', 'Pug',
            'Puli', 'Pyrenean Shepherd', 'Rat Terrier', 'Redbone Coonhound',
            'Rhodesian Ridgeback', 'Rottweiler', 'Russell Terrier', 'Saluki',
            'Samoyed', 'Schipperke', 'Scottish Deerhound', 'Scottish Terrier',
            'Sealyham Terrier', 'Shetland Sheepdog', 'Shiba Inu', 'Shih Tzu',
            'Siberian Husky', 'Silky Terrier', 'Skye Terrier', 'Sloughi',
            'Smooth Fox Terrier', 'Soft Coated Wheaten Terrier', 'Spanish Water Dog',
            'Spinone Italiano', 'St. Bernard', 'Sussex Spaniel', 'Swedish Vallhund',
            'Tibetan Mastiff', 'Tibetan Spaniel', 'Tibetan Terrier', 'Toy Fox Terrier',
            'Treeing Walker Coonhound', 'Vizsla', 'Weimaraner', 'Welsh Springer Spaniel',
            'Welsh Terrier', 'West Highland White Terrier', 'Whippet', 'Wire Fox Terrier',
            'Wirehaired Pointing Griffon', 'Xoloitzcuintli', 'Yorkshire Terrier'
        ]
    
    def collect_all_breeds_data(self, images_per_breed=15, quality_threshold=0.8) -> Dict:
        """Collecte des données pour toutes les races avec un bon pourcentage de qualité"""
        try:
            logger.info("Début de la collecte complète des données pour toutes les races...")
            
            # Créer le dossier de données s'il n'existe pas
            os.makedirs(self.data_dir, exist_ok=True)
            
            # Statistiques de collecte
            stats = {
                "total_breeds": len(self.breeds),
                "successful_breeds": 0,
                "total_images_collected": 0,
                "failed_breeds": [],
                "quality_achievements": {},
                "start_time": time.time()
            }
            
            # Utiliser le multitraitement pour accélérer la collecte
            with ThreadPoolExecutor(max_workers=5) as executor:
                # Soumettre toutes les tâches
                future_to_breed = {
                    executor.submit(self._collect_breed_data, breed, images_per_breed, quality_threshold): breed 
                    for breed in self.breeds
                }
                
                # Collecter les résultats
                for future in as_completed(future_to_breed):
                    breed = future_to_breed[future]
                    try:
                        result = future.result()
                        if result["success"]:
                            stats["successful_breeds"] += 1
                            stats["total_images_collected"] += result["images_collected"]
                            stats["quality_achievements"][breed] = result["quality_score"]
                            logger.info(f"Collecte réussie pour {breed}: {result['images_collected']} images, qualité: {result['quality_score']:.2%}")
                        else:
                            stats["failed_breeds"].append(breed)
                            logger.warning(f"Échec de la collecte pour {breed}: {result.get('error', 'Erreur inconnue')}")
                    except Exception as e:
                        stats["failed_breeds"].append(breed)
                        logger.error(f"Erreur lors de la collecte pour {breed}: {e}")
            
            # Calculer le temps total
            stats["end_time"] = time.time()
            stats["duration"] = stats["end_time"] - stats["start_time"]
            
            # Afficher les statistiques finales
            logger.info(f"Collecte terminée en {stats['duration']:.2f} secondes")
            logger.info(f"Races réussies: {stats['successful_breeds']}/{stats['total_breeds']}")
            logger.info(f"Images collectées: {stats['total_images_collected']}")
            
            if stats["failed_breeds"]:
                logger.warning(f"Races échouées: {len(stats['failed_breeds'])}")
                for breed in stats["failed_breeds"][:5]:  # Afficher les 5 premières
                    logger.warning(f"  - {breed}")
                if len(stats["failed_breeds"]) > 5:
                    logger.warning(f"  ... et {len(stats['failed_breeds']) - 5} autres")
            
            return stats
            
        except Exception as e:
            logger.error(f"Erreur lors de la collecte complète des données: {e}")
            return {"success": False, "error": str(e)}
    
    def _collect_breed_data(self, breed: str, target_images: int, quality_threshold: float) -> Dict:
        """Collecte des données pour une race spécifique"""
        try:
            breed_dir = os.path.join(self.data_dir, breed.replace(' ', '_'))
            os.makedirs(breed_dir, exist_ok=True)
            
            # Compter les images existantes
            existing_images = len([f for f in os.listdir(breed_dir) 
                                 if f.lower().endswith(('.jpg', '.jpeg', '.png'))])
            
            # Calculer combien d'images supplémentaires sont nécessaires
            images_to_collect = max(0, target_images - existing_images)
            
            if images_to_collect > 0:
                logger.info(f"Collecte de {images_to_collect} images pour {breed}...")
                
                # Collecter les images
                collected = self._download_high_quality_images(breed, images_to_collect)
                
                # Vérifier la qualité
                quality_score = self._assess_image_quality(breed_dir, collected)
                
                result = {
                    "success": True,
                    "images_collected": len(collected),
                    "quality_score": quality_score,
                    "meets_threshold": quality_score >= quality_threshold
                }
                
                # Si la qualité n'est pas suffisante, collecter plus d'images
                if quality_score < quality_threshold and len(collected) > 0:
                    logger.info(f"Qualité insuffisante pour {breed} ({quality_score:.2%} < {quality_threshold:.2%}), collecte supplémentaire...")
                    additional_collected = self._download_high_quality_images(breed, images_to_collect)
                    collected.extend(additional_collected)
                    quality_score = self._assess_image_quality(breed_dir, collected)
                    result["images_collected"] = len(collected)
                    result["quality_score"] = quality_score
                    result["meets_threshold"] = quality_score >= quality_threshold
                
                return result
            else:
                # Évaluer la qualité des images existantes
                quality_score = self._assess_image_quality(breed_dir, [])
                return {
                    "success": True,
                    "images_collected": existing_images,
                    "quality_score": quality_score,
                    "meets_threshold": quality_score >= quality_threshold
                }
                
        except Exception as e:
            logger.error(f"Erreur lors de la collecte pour {breed}: {e}")
            return {"success": False, "error": str(e)}
    
    def _download_high_quality_images(self, breed: str, num_images: int) -> List[str]:
        """Télécharge des images de haute qualité pour une race"""
        try:
            collected_files = []
            breed_dir = os.path.join(self.data_dir, breed.replace(' ', '_'))
            
            # Sources variées pour une meilleure qualité
            sources = [
                f"https://source.unsplash.com/600x600/?{breed.replace(' ', '+')},dog",
                f"https://source.unsplash.com/600x600/?{breed.replace(' ', '+')},canine",
                f"https://source.unsplash.com/600x600/?{breed.replace(' ', '+')},pet",
                f"https://source.unsplash.com/600x600/?dog,{breed.replace(' ', '+')}",
                f"https://source.unsplash.com/600x600/?{breed.replace(' ', '+')},animal"
            ]
            
            # Termes de recherche supplémentaires
            search_terms = [
                breed.replace(' ', '+'),
                f"{breed.replace(' ', '+')}+dog",
                f"{breed.replace(' ', '+')}+canine",
                f"{breed.replace(' ', '+')}+pet",
                f"dog+{breed.replace(' ', '+')}",
                f"{breed.replace(' ', '+')}+breed"
            ]
            
            for i in range(num_images * 2):  # Essayer plus d'images pour en sélectionner de meilleures
                # Choisir une source aléatoire
                source_url = sources[i % len(sources)]
                
                # Choisir un terme de recherche aléatoire
                search_term = search_terms[i % len(search_terms)]
                source_url = f"https://source.unsplash.com/600x600/?{search_term}"
                
                try:
                    response = requests.get(source_url, timeout=20)
                    if response.status_code == 200:
                        # Vérifier si c'est une vraie image
                        try:
                            from io import BytesIO
                            img_data = BytesIO(response.content)
                            img = Image.open(img_data)
                            
                            # Vérifier la taille et la qualité
                            if img.size[0] >= 400 and img.size[1] >= 400:  # Images suffisamment grandes
                                # Sauvegarder l'image
                                timestamp = int(time.time() * 1000)
                                filename = f"{breed.replace(' ', '_')}_{timestamp}_{i}.jpg"
                                img_path = os.path.join(breed_dir, filename)
                                
                                # Sauvegarder avec une qualité optimale
                                img.save(img_path, 'JPEG', quality=95, optimize=True)
                                collected_files.append(filename)
                                
                                logger.debug(f"Image de haute qualité téléchargée: {filename}")
                                
                                # Si nous avons assez d'images, arrêter
                                if len(collected_files) >= num_images:
                                    break
                                    
                        except Exception as img_error:
                            logger.debug(f"Image ignorée (format invalide): {img_error}")
                            continue
                            
                except Exception as req_error:
                    logger.debug(f"Erreur lors du téléchargement de l'image {i} pour {breed}: {req_error}")
                    continue
                    
                # Petit délai pour éviter de surcharger les serveurs
                time.sleep(0.2)
                
            return collected_files[:num_images]  # Retourner seulement le nombre requis
            
        except Exception as e:
            logger.error(f"Erreur lors du téléchargement d'images de haute qualité pour {breed}: {e}")
            return []
    
    def _assess_image_quality(self, breed_dir: str, new_files: List[str]) -> float:
        """Évalue la qualité des images dans un dossier"""
        try:
            # Compter toutes les images dans le dossier
            all_images = [f for f in os.listdir(breed_dir) 
                         if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
            
            if not all_images:
                return 0.0
            
            # Pour simplifier, nous utilisons un score basé sur:
            # 1. Le nombre d'images (plus il y en a, meilleure est la qualité potentielle)
            # 2. La diversité des images (simulée)
            
            image_count_score = min(1.0, len(all_images) / 20.0)  # 20 images = score maximal
            diversity_score = min(1.0, len(new_files) / 10.0) if new_files else 0.5  # Encourager les nouvelles images
            
            # Score combiné
            quality_score = (image_count_score * 0.7) + (diversity_score * 0.3)
            
            return quality_score
            
        except Exception as e:
            logger.error(f"Erreur lors de l'évaluation de la qualité pour {breed_dir}: {e}")
            return 0.0
    
    def get_collection_report(self) -> Dict:
        """Génère un rapport détaillé sur la collecte de données"""
        try:
            report = {
                "total_breeds": len(self.breeds),
                "breeds_with_data": 0,
                "total_images": 0,
                "breed_details": {},
                "quality_distribution": {
                    "excellent": 0,  # > 90%
                    "good": 0,       # 80-90%
                    "fair": 0,       # 70-80%
                    "poor": 0        # < 70%
                }
            }
            
            for breed in self.breeds:
                breed_dir = os.path.join(self.data_dir, breed.replace(' ', '_'))
                
                if os.path.exists(breed_dir):
                    images = [f for f in os.listdir(breed_dir) 
                             if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
                    
                    if images:
                        report["breeds_with_data"] += 1
                        report["total_images"] += len(images)
                        
                        # Évaluer la qualité pour cette race
                        quality_score = self._assess_image_quality(breed_dir, [])
                        report["breed_details"][breed] = {
                            "image_count": len(images),
                            "quality_score": quality_score
                        }
                        
                        # Classer par qualité
                        if quality_score > 0.9:
                            report["quality_distribution"]["excellent"] += 1
                        elif quality_score > 0.8:
                            report["quality_distribution"]["good"] += 1
                        elif quality_score > 0.7:
                            report["quality_distribution"]["fair"] += 1
                        else:
                            report["quality_distribution"]["poor"] += 1
                else:
                    report["breed_details"][breed] = {
                        "image_count": 0,
                        "quality_score": 0.0
                    }
            
            return report
            
        except Exception as e:
            logger.error(f"Erreur lors de la génération du rapport: {e}")
            return {"error": str(e)}

# Exemple d'utilisation
if __name__ == "__main__":
    collector = ComprehensiveDataCollector()
    
    # Collecter des données pour toutes les races
    stats = collector.collect_all_breeds_data(images_per_breed=10, quality_threshold=0.8)
    
    # Afficher le rapport
    report = collector.get_collection_report()
    logger.info(f"Rapport de collecte: {report['breeds_with_data']}/{report['total_breeds']} races avec des données")
    logger.info(f"Images totales: {report['total_images']}")
    logger.info(f"Distribution de qualité: {report['quality_distribution']}")
