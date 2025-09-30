from django.shortcuts import render, redirect
from django.core.files.storage import default_storage
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings
from django.contrib import messages
import os
import json

from .models import UploadedImage, DogBreed
# Importer le nouveau classifieur amélioré
from ml_models.enhanced_model import EnhancedDogBreedClassifier
from ml_models.auto_trainer import AutoTrainer
from ml_models.advanced_trainer import AdvancedTrainer  # Nouvel import
from ml_models.data_manager import DataManager

# Initialiser le classifieur amélioré
classifier = EnhancedDogBreedClassifier(num_classes=70)  # Augmenter le nombre de classes
classifier.build_model()

def home(request):
    return render(request, 'classifier/home.html')

def upload_image(request):
    if request.method == 'POST' and request.FILES.get('image'):
        image = request.FILES['image']
        
        # Save the uploaded image
        file_name = default_storage.save(f'dog_images/{image.name}', image)
        file_url = default_storage.url(file_name)
        
        # Create a new UploadedImage instance
        # Only set the required image field during creation
        uploaded_image = UploadedImage.objects.create(  # type: ignore[attr-defined]
            image=file_name
        )
        
        # Set the optional fields after creation
        uploaded_image.predicted_breed = None
        uploaded_image.confidence_score = None
        uploaded_image.second_breed = None
        uploaded_image.second_confidence = None
        uploaded_image.third_breed = None
        uploaded_image.third_confidence = None
        uploaded_image.save()
        
        # Use our ML model to predict the breed
        prediction_result = predict_dog_breed(file_name)
        
        # Update the uploaded image with prediction results
        if prediction_result:
            uploaded_image.predicted_breed = prediction_result['breed']
            uploaded_image.confidence_score = prediction_result['confidence']
            
            # Ajouter les prédictions alternatives si disponibles
            if 'alternatives' in prediction_result and len(prediction_result['alternatives']) >= 2:
                uploaded_image.second_breed = prediction_result['alternatives'][0]['breed']
                uploaded_image.second_confidence = prediction_result['alternatives'][0]['confidence']
                uploaded_image.third_breed = prediction_result['alternatives'][1]['breed']
                uploaded_image.third_confidence = prediction_result['alternatives'][1]['confidence']
            
            uploaded_image.save()
        
        context = {
            'uploaded_image': uploaded_image,
            'file_url': file_url,
            'prediction': prediction_result
        }
        
        return render(request, 'classifier/result.html', context)
    
    return redirect('home')

def predict_dog_breed(image_path):
    """
    Function to predict dog breed using our enhanced machine learning model.
    """
    # Utiliser le classifieur amélioré
    predictions = classifier.predict_breed(image_path)
    
    if predictions:
        # Trier les prédictions par probabilité
        sorted_predictions = sorted(predictions, key=lambda x: x[1], reverse=True)
        top_prediction = sorted_predictions[0]
        
        # Get or create the breed in our database
        breed, created = DogBreed.objects.get_or_create(  # type: ignore[attr-defined]
            name=top_prediction[0],
            defaults={
                'origin_country': 'Unknown',  # À améliorer avec des données réelles
                'description': f'A {top_prediction[0]} dog breed.',
                'size': '',
                'group': '',
                'lifespan': '',
                'temperament': ''
            }
        )
        
        # Préparer les prédictions alternatives
        alternatives = []
        for i, (breed_name, confidence) in enumerate(sorted_predictions[1:4]):  # Prendre les 3 suivantes au lieu de 2
            alt_breed, _ = DogBreed.objects.get_or_create(  # type: ignore[attr-defined]
                name=breed_name,
                defaults={
                    'origin_country': 'Unknown',
                    'description': f'A {breed_name} dog breed.',
                    'size': '',
                    'group': '',
                    'lifespan': '',
                    'temperament': ''
                }
            )
            alternatives.append({
                'breed': alt_breed,
                'confidence': confidence
            })
        
        return {
            'breed': breed,
            'confidence': top_prediction[1],
            'origin': breed.origin_country,
            'alternatives': alternatives
        }
    
    return None

def about(request):
    # Get breed information from database
    breeds = DogBreed.objects.all()  # type: ignore[attr-defined]
    return render(request, 'classifier/about.html', {'breeds': breeds})

# Nouvelles vues pour l'entraînement automatique
def train_model(request):
    """Vue pour déclencher manuellement l'entraînement du modèle"""
    if request.method == 'POST':
        try:
            # Initialiser l'entraîneur automatique
            trainer = AutoTrainer()
            
            # Collecter de nouvelles données
            trainer.collect_new_data(num_images_per_breed=5)
            
            # Entraîner le modèle
            result = trainer.train_model()
            
            if result["success"]:
                messages.success(request, f"Entraînement réussi! Précision: {result['accuracy']:.2%}")
            else:
                messages.error(request, f"Échec de l'entraînement: {result.get('error', 'Erreur inconnue')}")
                
        except Exception as e:
            messages.error(request, f"Erreur lors de l'entraînement: {str(e)}")
    
    return redirect('home')

# Nouvelles vues pour l'entraînement avancé
def advanced_train_model(request):
    """Vue pour déclencher l'entraînement avancé du modèle"""
    if request.method == 'POST':
        try:
            # Initialiser l'entraîneur avancé
            advanced_trainer = AdvancedTrainer()
            
            # Démarrer une session d'entraînement intensive
            result = advanced_trainer.intensive_training_session(epochs=30)
            
            if result["success"]:
                messages.success(request, f"Entraînement avancé réussi! Précision: {result['final_accuracy']:.2%} (+{result['improvement']:.2%})")
            else:
                messages.error(request, f"Échec de l'entraînement avancé: {result.get('error', 'Erreur inconnue')}")
                
        except Exception as e:
            messages.error(request, f"Erreur lors de l'entraînement avancé: {str(e)}")
    
    return redirect('home')

def comprehensive_train_model(request):
    """Vue pour déclencher l'entraînement complet avec collecte automatique de toutes les races"""
    if request.method == 'POST':
        try:
            # Initialiser l'entraîneur avancé
            advanced_trainer = AdvancedTrainer()
            
            # Démarrer une session d'entraînement intensive avec collecte automatique
            result = advanced_trainer.intensive_training_session(
                epochs=50,
                auto_collect=True,
                quality_threshold=0.85
            )
            
            if result["success"]:
                messages.success(request, f"Entraînement complet réussi! Précision: {result['final_accuracy']:.2%} (+{result['improvement']:.2%})")
                messages.info(request, "Toutes les races ont été collectées automatiquement avec un bon pourcentage de qualité.")
            else:
                messages.error(request, f"Échec de l'entraînement complet: {result.get('error', 'Erreur inconnue')}")
                
        except Exception as e:
            messages.error(request, f"Erreur lors de l'entraînement complet: {str(e)}")
    
    return redirect('home')

def continuous_learning(request):
    """Vue pour déclencher l'apprentissage continu"""
    if request.method == 'POST':
        try:
            # Initialiser l'entraîneur avancé
            advanced_trainer = AdvancedTrainer()
            
            # Démarrer une boucle d'apprentissage continu
            result = advanced_trainer.continuous_learning_loop(iterations=3, hours_between_sessions=1)
            
            if result["success"]:
                messages.success(request, f"Apprentissage continu terminé! Amélioration globale: {result['overall_improvement']:.2%}")
            else:
                messages.error(request, f"Échec de l'apprentissage continu: {result.get('error', 'Erreur inconnue')}")
                
        except Exception as e:
            messages.error(request, f"Erreur lors de l'apprentissage continu: {str(e)}")
    
    return redirect('home')

def training_stats(request):
    """Vue pour afficher les statistiques d'entraînement"""
    try:
        trainer = AutoTrainer()
        stats = trainer.get_training_stats()
        return JsonResponse(stats)
    except Exception as e:
        return JsonResponse({"error": str(e)})

def advanced_training_stats(request):
    """Vue pour afficher les statistiques d'entraînement avancées"""
    try:
        advanced_trainer = AdvancedTrainer()
        stats = advanced_trainer.get_advanced_training_stats()
        return JsonResponse(stats)
    except Exception as e:
        return JsonResponse({"error": str(e)})

def auto_train_check(request):
    """Vue pour vérifier si l'entraînement automatique est nécessaire"""
    try:
        trainer = AutoTrainer()
        should_train = trainer.should_train()
        return JsonResponse({"should_train": should_train})
    except Exception as e:
        return JsonResponse({"error": str(e), "should_train": False})

def validate_dataset(request):
    """Vue pour valider l'intégrité du dataset"""
    try:
        data_manager = DataManager()
        validation_report = data_manager.validate_dataset()
        return JsonResponse(validation_report)
    except Exception as e:
        return JsonResponse({"error": str(e)})