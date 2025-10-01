# Script de génération de documentation API

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "./docs/api",
    
    [Parameter(Mandatory=$false)]
    [string]$Format = "markdown",
    
    [Parameter(Mandatory=$false)]
    [switch]$Serve = $false
)

Write-Host "Génération de la documentation API" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$apiSpecFile = "./docs/api.md"
$templatesDir = "./templates"

# Fonction pour afficher les messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Level) {
        "INFO" { Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor White }
        "WARN" { Write-Host "[$timestamp] [WARN] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor Red }
        "SUCCESS" { Write-Host "[$timestamp] [SUCCESS] $Message" -ForegroundColor Green }
    }
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Log "Répertoire de sortie créé: $OutputDir" "INFO"
}

# Charger la spécification API existante
$apiSpec = ""
if (Test-Path $apiSpecFile) {
    $apiSpec = Get-Content $apiSpecFile -Raw
    Write-Log "Spécification API chargée: $apiSpecFile" "SUCCESS"
} else {
    Write-Log "Fichier de spécification API non trouvé, génération d'un template" "WARN"
    $apiSpec = @"
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
"@
}

# Générer la documentation selon le format spécifié
switch ($Format.ToLower()) {
    "html" {
        Write-Log "Génération de la documentation HTML..." "INFO"
        
        # Convertir le markdown en HTML
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Documentation API - $projectName</title>
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
        <h1>Documentation API - $projectName</h1>
        
        <div class="section">
            <h2>Endpoints</h2>
"@
        
        # Ajouter les endpoints (extraction basique du markdown)
        $htmlContent += @"
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
"@
        
        $htmlOutputFile = Join-Path $OutputDir "api-documentation.html"
        Set-Content -Path $htmlOutputFile -Value $htmlContent
        Write-Log "Documentation HTML générée: $htmlOutputFile" "SUCCESS"
    }
    
    default {
        Write-Log "Génération de la documentation Markdown..." "INFO"
        
        $mdOutputFile = Join-Path $OutputDir "api-documentation.md"
        Set-Content -Path $mdOutputFile -Value $apiSpec
        Write-Log "Documentation Markdown générée: $mdOutputFile" "SUCCESS"
    }
}

# Servir la documentation localement si demandé
if ($Serve) {
    Write-Log "Démarrage du serveur de documentation..." "INFO"
    
    # Créer un serveur HTTP simple
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:8080/")
    $listener.Start()
    
    Write-Log "Documentation disponible à http://localhost:8080/" "SUCCESS"
    Write-Log "Appuyez sur Ctrl+C pour arrêter le serveur" "INFO"
    
    try {
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            # Déterminer le fichier à servir
            $filePath = ""
            if ($request.Url.AbsolutePath -eq "/" -or $request.Url.AbsolutePath -eq "/index.html") {
                $filePath = Join-Path $OutputDir "api-documentation.html"
            } else {
                $filePath = Join-Path $OutputDir $request.Url.AbsolutePath.TrimStart("/")
            }
            
            # Vérifier si le fichier existe
            if (Test-Path $filePath) {
                $buffer = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentType = "text/html"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            } else {
                $response.StatusCode = 404
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("<h1>404 - Fichier non trouvé</h1>")
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            
            $response.Close()
        }
    } finally {
        $listener.Stop()
    }
}

Write-Log "Génération de la documentation API terminée !" "SUCCESS"