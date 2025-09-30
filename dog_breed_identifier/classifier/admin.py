from django.contrib import admin
from .models import DogBreed, UploadedImage

@admin.register(DogBreed)
class DogBreedAdmin(admin.ModelAdmin):
    list_display = ('name', 'origin_country')
    search_fields = ('name', 'origin_country')
    list_filter = ('origin_country',)

@admin.register(UploadedImage)
class UploadedImageAdmin(admin.ModelAdmin):
    list_display = ('id', 'uploaded_at', 'predicted_breed', 'confidence_score')
    list_filter = ('uploaded_at', 'predicted_breed')
    date_hierarchy = 'uploaded_at'