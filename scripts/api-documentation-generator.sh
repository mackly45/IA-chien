#!/bin/bash

# Script de génération de documentation API

# Paramètres par défaut
OUTPUT_DIR="./docs/api"
FORMAT="markdown"
SERVE=false

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
API_SPEC_FILE="./docs/api.md"
TEMPLATES_DIR="./templates"

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mGénération de la documentation API\033[0m"
    echo -e "\033[1;36m=============================\033[0m"
}

print_log() {
    local message=$1
    local level=${2:-"INFO"}
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case $level in
        "INFO")
            echo -e "\033[1;37m[$timestamp] [INFO] $message\033[0m"
            ;;
        "WARN")
            echo -e "\033[1;33m[$timestamp] [WARN] $message\033[0m"
            ;;
        "ERROR")
            echo -e "\033[1;31m[$timestamp] [ERROR] $message\033[0m"
            ;;
        "SUCCESS")
            echo -e "\033[1;32m[$timestamp] [SUCCESS] $message\033[0m"
            ;;
    esac
}

# Analyse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -s|--serve)
            SERVE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -o, --output DIR     Répertoire de sortie (défaut: ./docs/api)"
            echo "  -f, --format FORMAT  Format de sortie (markdown, html) (défaut: markdown)"
            echo "  -s, --serve          Servir la documentation localement"
            echo "  -h, --help           Afficher cette aide"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

print_header

# Créer le répertoire de sortie s'il n'existe pas
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    print_log "Répertoire de sortie créé: $OUTPUT_DIR" "INFO"
fi

# Charger la spécification API existante
if [ -f "$API_SPEC_FILE" ]; then
    print_log "Spécification API chargée: $API_SPEC_FILE" "SUCCESS"
else
    print_log "Fichier de spécification API non trouvé, génération d'un template" "WARN"
    cat > "$API_SPEC_FILE" << 'EOF'
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
    "Golden Retriever"
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
EOF
fi

# Générer la documentation selon le format spécifié
case $FORMAT in
    "html")
        print_log "Génération de la documentation HTML..." "INFO"
        
        # Convertir le markdown en HTML
        HTML_OUTPUT_FILE="$OUTPUT_DIR/api-documentation.html"
        cat > "$HTML_OUTPUT_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Documentation API - $PROJECT_NAME</title>
    <meta charset="UTF-8">
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background-color: #f8f9fa;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        h1, h2, h3, h4 { 
            color: #2c3e50; 
        }
        h1 {
            text-align: center;
            padding-bottom: 20px;
            border-bottom: 2px solid #3498db;
        }
        .section { 
            margin-bottom: 30px; 
            padding: 20px;
            border-radius: 8px;
            background-color: #ffffff;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }
        pre {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
        code {
            font-family: 'Courier New', monospace;
            background-color: #f1f8ff;
            padding: 2px 5px;
            border-radius: 3px;
        }
        .endpoint {
            border-left: 4px solid #3498db;
            padding-left: 20px;
            margin: 20px 0;
        }
        .method {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 4px;
            color: white;
            font-weight: bold;
        }
        .post { background-color: #27ae60; }
        .get { background-color: #3498db; }
        .put { background-color: #f39c12; }
        .delete { background-color: #e74c3c; }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        th {
            background-color: #3498db;
            color: white;
        }
        tr:hover {
            background-color: #f5f9ff;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Documentation API - $PROJECT_NAME</h1>
        
        <div class="section">
            <h2>Endpoints</h2>
            
            <div class="endpoint">
                <h3><span class="method post">POST</span> /api/identify/</h3>
                <p>Identifie la race d'un chien à partir d'une image.</p>
                
                <h4>Requête</h4>
                <pre><code>POST /api/identify/
Content-Type: multipart/form-data

image: &lt;fichier image&gt;</code></pre>
                
                <h4>Réponse</h4>
                <pre><code>{
  "success": true,
  "breed": "Labrador Retriever",
  "confidence": 0.95,
  "image_url": "/media/uploads/dog_image.jpg"
}</code></pre>
                
                <h4>Codes d'erreur</h4>
                <ul>
                    <li><code>400</code>: Image non fournie ou invalide</li>
                    <li><code>500</code>: Erreur interne du serveur</li>
                </ul>
            </div>
            
            <div class="endpoint">
                <h3><span class="method get">GET</span> /api/breeds/</h3>
                <p>Retourne la liste de toutes les races de chiens supportées.</p>
                
                <h4>Réponse</h4>
                <pre><code>{
  "breeds": [
    "Labrador Retriever",
    "German Shepherd",
    "Golden Retriever"
  ]
}</code></pre>
            </div>
        </div>
        
        <div class="section">
            <h2>Modèles de données</h2>
            
            <h3>Breed</h3>
            <pre><code>{
  "id": 1,
  "name": "Labrador Retriever",
  "description": "Un chien gentil et intelligent...",
  "origin": "Canada"
}</code></pre>
        </div>
        
        <div class="section">
            <h2>Authentification</h2>
            <p>L'API n'exige pas d'authentification pour les opérations de base d'identification.</p>
        </div>
        
        <div class="section">
            <h2>Limites d'utilisation</h2>
            <ul>
                <li>100 requêtes par heure par IP</li>
                <li>Images limitées à 5MB</li>
                <li>Formats supportés: JPEG, PNG</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF
        
        print_log "Documentation HTML générée: $HTML_OUTPUT_FILE" "SUCCESS"
        ;;
    
    *)
        print_log "Génération de la documentation Markdown..." "INFO"
        
        MD_OUTPUT_FILE="$OUTPUT_DIR/api-documentation.md"
        cp "$API_SPEC_FILE" "$MD_OUTPUT_FILE"
        print_log "Documentation Markdown générée: $MD_OUTPUT_FILE" "SUCCESS"
        ;;
esac

# Servir la documentation localement si demandé
if [ "$SERVE" = true ]; then
    print_log "Démarrage du serveur de documentation..." "INFO"
    
    # Vérifier si Python est disponible
    if command -v python3 &> /dev/null; then
        cd "$OUTPUT_DIR"
        print_log "Documentation disponible à http://localhost:8080/" "SUCCESS"
        print_log "Appuyez sur Ctrl+C pour arrêter le serveur" "INFO"
        python3 -m http.server 8080
    else
        print_log "Python non trouvé, impossible de démarrer le serveur" "ERROR"
        exit 1
    fi
fi

print_log "Génération de la documentation API terminée !" "SUCCESS"