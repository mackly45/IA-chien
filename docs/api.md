# API Documentation

## Endpoints

### Identification de race de chien

#### `POST /api/identify/`

Identifie la race d'un chien à partir d'une image.

**Request:**
```http
POST /api/identify/
Content-Type: multipart/form-data

image: <fichier image>
```

**Response:**
```json
{
  "success": true,
  "breed": "Labrador Retriever",
  "confidence": 0.95,
  "image_url": "/media/uploads/dog_image.jpg"
}
```

**Codes d'erreur:**
- `400`: Image non fournie ou invalide
- `500`: Erreur interne du serveur

### Liste des races de chiens

#### `GET /api/breeds/`

Retourne la liste de toutes les races de chiens supportées.

**Response:**
```json
{
  "breeds": [
    "Labrador Retriever",
    "German Shepherd",
    "Golden Retriever",
    // ... autres races
  ]
}
```

## Modèles de données

### Breed

```json
{
  "id": 1,
  "name": "Labrador Retriever",
  "description": "Un chien gentil et intelligent...",
  "origin": "Canada"
}
```

## Authentification

L'API n'exige pas d'authentification pour les opérations de base d'identification.

## Limites d'utilisation

- 100 requêtes par heure par IP
- Images limitées à 5MB
- Formats supportés: JPEG, PNG