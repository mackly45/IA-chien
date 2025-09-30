from django.core.management.base import BaseCommand
from classifier.models import DogBreed
from django.db import connections
from typing import Any, Optional

class Command(BaseCommand):
    help = 'Initialize the database with sample dog breeds'

    def add_arguments(self, parser):
        parser.add_argument(
            '--database',
            default='mysql',
            help='Database to use for initialization (default: mysql)',
        )

    def handle(self, *args: Any, **options: Any) -> Optional[str]:
        database = options['database']
        
        # Use the specified database connection
        connection = connections[database]
        
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
            # Use the specified database for the query
            breed, created = DogBreed.objects.using(database).get_or_create(  # type: ignore[attr-defined]
                name=breed_data['name'],
                defaults={
                    'origin_country': breed_data['origin_country'],
                    'description': breed_data['description']
                }
            )
            
            if created:
                self.stdout.write(
                    self.style.SUCCESS(f'Created breed: {breed.name}')  # type: ignore[attr-defined]
                )
            else:
                self.stdout.write(
                    f'Breed already exists: {breed.name}'
                )
        
        self.stdout.write(
            self.style.SUCCESS('Successfully initialized dog breeds')  # type: ignore[attr-defined]
        )
        return None