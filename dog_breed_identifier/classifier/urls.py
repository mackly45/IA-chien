from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='home'),
    path('upload/', views.upload_image, name='upload_image'),
    path('about/', views.about, name='about'),
    path('train/', views.train_model, name='train_model'),
    path('advanced-train/', views.advanced_train_model, name='advanced_train_model'),
    path('comprehensive-train/', views.comprehensive_train_model, name='comprehensive_train_model'),
    path('continuous-learning/', views.continuous_learning, name='continuous_learning'),
    path('training-stats/', views.training_stats, name='training_stats'),
    path('advanced-training-stats/', views.advanced_training_stats, name='advanced_training_stats'),
    path('auto-train-check/', views.auto_train_check, name='auto_train_check'),
    path('validate-dataset/', views.validate_dataset, name='validate_dataset'),
]