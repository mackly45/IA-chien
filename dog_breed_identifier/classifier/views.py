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
from ml_models.data_manager import DataManager

# Initialiser le classifieur amélioré
classifier = EnhancedDogBreedClassifier(num_classes=30)
classifier.build_model()

def home(request):
    return render(request, 'classifier/home.html')

def upload_image(request):
    if request.method == 'POST' and request.FILES.get('image'):
        image = request.FILES['image']
        
        # Save the uploaded image
        file_name = default_storage.save(f'dog_images/{image.name}', image)
        file_url = default_storage.url(file_name)
        
        # Create a new UploadedImage instance in MySQL database
        uploaded_image = UploadedImage.objects.using('mysql').create(image=file_name)  # type: ignore[attr-defined]
        
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
            
            uploaded_image.save(using='mysql')
        
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
        
        # Get or create the breed in our MySQL database
        breed, created = DogBreed.objects.using('mysql').get_or_create(  # type: ignore[attr-defined]
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
        for i, (breed_name, confidence) in enumerate(sorted_predictions[1:3]):  # Prendre les 2 suivantes
            alt_breed, _ = DogBreed.objects.using('mysql').get_or_create(  # type: ignore[attr-defined]
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
    # Get breed information from MySQL database
    breeds = DogBreed.objects.using('mysql').all()  # type: ignore[attr-defined]
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

def training_stats(request):
    """Vue pour afficher les statistiques d'entraînement"""
    try:
        trainer = AutoTrainer()
        stats = trainer.get_training_stats()
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