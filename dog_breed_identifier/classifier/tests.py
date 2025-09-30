from django.test import TestCase
from django.urls import reverse
from .models import DogBreed

class ClassifierViewsTest(TestCase):
    def setUp(self):
        """Set up test data"""
        self.breed = DogBreed.objects.using('mysql').create(  # type: ignore[attr-defined]
            name='Golden Retriever',
            origin_country='Scotland',
            description='Friendly, intelligent, and devoted.'
        )

    def test_home_page(self):
        """Test that the home page loads correctly"""
        response = self.client.get(reverse('home'))
        self.assertEqual(response.status_code, 200)  # type: ignore[attr-defined]
        self.assertContains(response, 'Identify Dog Breeds & Origins')

    def test_about_page(self):
        """Test that the about page loads correctly"""
        response = self.client.get(reverse('about'))
        self.assertEqual(response.status_code, 200)  # type: ignore[attr-defined]
        self.assertContains(response, 'About Dog Breed Identifier')

    def test_dog_breed_model(self):
        """Test the DogBreed model"""
        self.assertEqual(str(self.breed), 'Golden Retriever')
        self.assertEqual(self.breed.origin_country, 'Scotland')