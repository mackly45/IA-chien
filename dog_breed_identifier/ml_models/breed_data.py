"""
Dog Breed Data

This module contains information about various dog breeds and their origins.
"""

DOG_BREEDS = {
    'golden retriever': {
        'name': 'Golden Retriever',
        'origin': 'Scotland',
        'description': 'Friendly, intelligent, and devoted Golden Retrievers are one of the most popular dog breeds in the United States. They are excellent family dogs and are known for their gentle and friendly nature.',
        'size': 'Large',
        'group': 'Sporting'
    },
    'german shepherd': {
        'name': 'German Shepherd',
        'origin': 'Germany',
        'description': 'German Shepherds are confident, courageous, and smart. They are excellent working dogs and are often used in police and military roles.',
        'size': 'Large',
        'group': 'Herding'
    },
    'bulldog': {
        'name': 'Bulldog',
        'origin': 'England',
        'description': 'Bulldogs are medium-sized dogs with a sturdy build and a distinctive pushed-in nose. They are known for their loose, wrinkled skin and docile temperament.',
        'size': 'Medium',
        'group': 'Non-Sporting'
    },
    'labrador retriever': {
        'name': 'Labrador Retriever',
        'origin': 'Canada',
        'description': 'Labrador Retrievers are friendly, active, and outgoing. They are one of the most popular dog breeds in many countries and are known for their love of water.',
        'size': 'Large',
        'group': 'Sporting'
    },
    'beagle': {
        'name': 'Beagle',
        'origin': 'England',
        'description': 'Beagles are small to medium-sized dogs with a keen sense of smell. They are known for their musical howl and are often used as detection dogs.',
        'size': 'Medium',
        'group': 'Hound'
    },
    'poodle': {
        'name': 'Poodle',
        'origin': 'Germany/France',
        'description': 'Poodles are highly intelligent and easily trained dogs. They come in three sizes (standard, miniature, and toy) and are known for their distinctive coat.',
        'size': 'Various',
        'group': 'Non-Sporting'
    },
    'rottweiler': {
        'name': 'Rottweiler',
        'origin': 'Germany',
        'description': 'Rottweilers are powerful, confident, and courageous dogs. They are loyal to their families and make excellent guard dogs.',
        'size': 'Large',
        'group': 'Working'
    },
    'yorkshire terrier': {
        'name': 'Yorkshire Terrier',
        'origin': 'England',
        'description': 'Yorkshire Terriers are small dogs with long, silky coats. They are known for their feisty personality and are popular companion dogs.',
        'size': 'Small',
        'group': 'Toy'
    },
    'boxer': {
        'name': 'Boxer',
        'origin': 'Germany',
        'description': 'Boxers are medium to large-sized dogs with a square build and a short muzzle. They are playful, energetic, and loyal to their families.',
        'size': 'Large',
        'group': 'Working'
    },
    'dachshund': {
        'name': 'Dachshund',
        'origin': 'Germany',
        'description': 'Dachshunds are small dogs with long bodies and short legs. They were originally bred to hunt badgers and are known for their curious nature.',
        'size': 'Small',
        'group': 'Hound'
    }
}

# Create a mapping for quick lookup by country
COUNTRIES = {}
for breed, info in DOG_BREEDS.items():
    country = info['origin']
    if country not in COUNTRIES:
        COUNTRIES[country] = []
    COUNTRIES[country].append(info['name'])