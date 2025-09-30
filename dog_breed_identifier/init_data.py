"""
Script to initialize the database with sample dog breed data.
"""

import os
import django

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
django.setup()

from classifier.models import DogBreed

def create_sample_breeds(database='mysql'):
    """Create sample dog breeds in the specified database."""
    breeds = [
        {
            'name': 'Golden Retriever',
            'origin_country': 'Scotland',
            'description': 'Friendly, intelligent, and devoted Golden Retrievers are one of the most popular dog breeds in the United States. They are excellent family dogs and are known for their gentle and friendly nature.'
        },
        {
            'name': 'German Shepherd',
            'origin_country': 'Germany',
            'description': 'German Shepherds are confident, courageous, and smart. They are excellent working dogs and are often used in police and military roles.'
        },
        {
            'name': 'Bulldog',
            'origin_country': 'England',
            'description': 'Bulldogs are medium-sized dogs with a sturdy build and a distinctive pushed-in nose. They are known for their loose, wrinkled skin and docile temperament.'
        },
        {
            'name': 'Labrador Retriever',
            'origin_country': 'Canada',
            'description': 'Labrador Retrievers are friendly, active, and outgoing. They are one of the most popular dog breeds in many countries and are known for their love of water.'
        },
        {
            'name': 'Beagle',
            'origin_country': 'England',
            'description': 'Beagles are small to medium-sized dogs with a keen sense of smell. They are known for their musical howl and are often used as detection dogs.'
        }
    ]
    
    for breed_data in breeds:
        breed, created = DogBreed.objects.using(database).get_or_create(  # type: ignore[attr-defined]
            name=breed_data['name'],
            defaults={
                'origin_country': breed_data['origin_country'],
                'description': breed_data['description']
            }
        )
        
        if created:
            print(f"Created breed: {breed.name}")
        else:
            print(f"Breed already exists: {breed.name}")

if __name__ == '__main__':
    print("Initializing MySQL database with sample dog breeds...")
    create_sample_breeds('mysql')
    
    print("Initializing SQLite database with sample dog breeds...")
    create_sample_breeds('default')
    
    print("Done!")