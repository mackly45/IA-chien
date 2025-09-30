from django.shortcuts import render, redirect
from django.core.files.storage import default_storage
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings
import os
import json

from .models import UploadedImage, DogBreed
from ml_models.dog_breed_classifier import DogBreedClassifier

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
    Function to predict dog breed using our machine learning model.
    """
    classifier = DogBreedClassifier()
    result = classifier.predict_breed(image_path)
    
    if result:
        # Get or create the breed in our MySQL database
        breed, created = DogBreed.objects.using('mysql').get_or_create(  # type: ignore[attr-defined]
            name=result['breed_name'],
            defaults={
                'origin_country': result['origin_country'],
                'description': result['description']
            }
        )
        
        return {
            'breed': breed,
            'confidence': result['confidence'],
            'origin': result['origin_country']
        }
    
    return None

def about(request):
    # Get breed information from MySQL database
    breeds = DogBreed.objects.using('mysql').all()  # type: ignore[attr-defined]
    return render(request, 'classifier/about.html', {'breeds': breeds})