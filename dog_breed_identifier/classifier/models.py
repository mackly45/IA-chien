from django.db import models

class DogBreed(models.Model):
    name = models.CharField(max_length=100)
    origin_country = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    
    def __str__(self):
        return str(self.name)

class UploadedImage(models.Model):
    image = models.ImageField(upload_to='dog_images/')
    uploaded_at = models.DateTimeField(auto_now_add=True)
    predicted_breed = models.ForeignKey(DogBreed, on_delete=models.SET_NULL, null=True, blank=True)
    confidence_score = models.FloatField(null=True, blank=True)
    
    def __str__(self):
        return f"Image uploaded at {self.uploaded_at}"