from django.db import models
from django.utils import timezone

class DogBreed(models.Model):
    name = models.CharField(max_length=100, unique=True)
    origin_country = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    size = models.CharField(max_length=20, blank=True)  # Small, Medium, Large, etc.
    group = models.CharField(max_length=50, blank=True)  # Sporting, Herding, Working, etc.
    lifespan = models.CharField(max_length=20, blank=True)  # e.g., "10-12 years"
    temperament = models.TextField(blank=True)  # Friendly, Energetic, etc.
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)
    
    def __str__(self):
        return str(self.name)

class UploadedImage(models.Model):
    image = models.ImageField(upload_to='dog_images/')
    uploaded_at = models.DateTimeField(auto_now_add=True)
    predicted_breed = models.ForeignKey(DogBreed, on_delete=models.SET_NULL, null=True, blank=True)
    confidence_score = models.FloatField(null=True, blank=True)
    # Ajouter des champs pour les prédictions alternatives
    second_breed = models.ForeignKey(DogBreed, on_delete=models.SET_NULL, null=True, blank=True, related_name='second_breed_predictions')
    second_confidence = models.FloatField(null=True, blank=True)
    third_breed = models.ForeignKey(DogBreed, on_delete=models.SET_NULL, null=True, blank=True, related_name='third_breed_predictions')
    third_confidence = models.FloatField(null=True, blank=True)
    
    def __str__(self):
        return f"Image uploaded at {self.uploaded_at}"