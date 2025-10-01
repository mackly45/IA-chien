# Script de génération de documentation

param(
    [Parameter(Mandatory=$false)]
    [string]$SourceDir = "./docs",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "./docs/build",
    
    [Parameter(Mandatory=$false)]
    [string]$Format = "html",
    
    [Parameter(Mandatory=$false)]
    [switch]$Serve = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

Write-Host "Génération de la documentation" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

# Variables de configuration
$projectName = "Dog Breed Identifier"
$supportedFormats = @("html", "pdf", "markdown")

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

# Fonction pour vérifier si un outil est installé
function Test-Tool {
    param([string]$Tool)
    
    try {
        $result = Get-Command $Tool -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Fonction pour copier les fichiers de documentation
function Copy-Docs {
    param([string]$SrcDir, [string]$DestDir)
    
    Write-Log "Copie des fichiers de documentation..." "INFO"
    
    if (-not (Test-Path $SrcDir)) {
        Write-Log "Répertoire source non trouvé: $SrcDir" "ERROR"
        return $false
    }
    
    # Créer le répertoire de destination s'il n'existe pas
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
        Write-Log "Répertoire de destination créé: $DestDir" "INFO"
    }
    
    # Copier les fichiers
    try {
        Copy-Item -Path "$SrcDir/*" -Destination $DestDir -Recurse -Force
        Write-Log "Fichiers de documentation copiés avec succès" "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de la copie des fichiers: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Fonction pour générer la documentation HTML
function Generate-HtmlDocs {
    param([string]$SrcDir, [string]$DestDir)
    
    Write-Log "Génération de la documentation HTML..." "INFO"
    
    # Créer l'index HTML
    $indexFile = Join-Path $DestDir "index.html"
    
    # Lire les fichiers Markdown existants
    $mdFiles = Get-ChildItem -Path $SrcDir -Filter "*.md" -Recurse
    
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Documentation - $projectName</title>
    <meta charset="UTF-8">
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background-color: #f8f9fa;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        h1, h2, h3 { 
            color: #2c3e50; 
        }
        h1 {
            text-align: center;
            padding-bottom: 20px;
            border-bottom: 2px solid #3498db;
        }
        .nav {
            background-color: #3498db;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .nav a {
            color: white;
            text-decoration: none;
            padding: 10px;
            display: inline-block;
        }
        .nav a:hover {
            background-color: #2980b9;
            border-radius: 3px;
        }
        .content {
            line-height: 1.6;
        }
        code {
            background-color: #f1f8ff;
            padding: 2px 5px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
        }
        pre {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
        blockquote {
            border-left: 4px solid #3498db;
            padding-left: 20px;
            margin: 20px 0;
            color: #7f8c8d;
        }
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
    </style>
</head>
<body>
    <div class="container">
        <h1>Documentation - $projectName</h1>
        
        <div class="nav">
"@
    
    # Ajouter les liens de navigation
    foreach ($file in $mdFiles) {
        $fileName = $file.BaseName
        $displayName = $fileName -replace "-", " "
        $displayName = (Get-Culture).TextInfo.ToTitleCase($displayName)
        $htmlContent += "<a href='#$fileName'>$displayName</a>`n"
    }
    
    $htmlContent += @"
        </div>
        
        <div class="content">
"@
    
    # Ajouter le contenu de chaque fichier
    foreach ($file in $mdFiles) {
        $fileName = $file.BaseName
        $content = Get-Content $file.FullName -Raw
        
        # Convertir le Markdown en HTML basique
        $htmlContent += "<div id='$fileName'>`n"
        $htmlContent += "<h2>$($file.BaseName -replace '-', ' ' | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) })</h2>`n"
        
        # Conversion basique Markdown vers HTML
        $lines = $content -split "`n"
        $inCodeBlock = $false
        $inList = $false
        
        foreach ($line in $lines) {
            if ($line -match "^# (.*)") {
                $htmlContent += "<h1>$($matches[1])</h1>`n"
            }
            elseif ($line -match "^## (.*)") {
                $htmlContent += "<h2>$($matches[1])</h2>`n"
            }
            elseif ($line -match "^### (.*)") {
                $htmlContent += "<h3>$($matches[1])</h3>`n"
            }
            elseif ($line -match "^#### (.*)") {
                $htmlContent += "<h4>$($matches[1])</h4>`n"
            }
            elseif ($line -match "^##### (.*)") {
                $htmlContent += "<h5>$($matches[1])</h5>`n"
            }
            elseif ($line -match "^###### (.*)") {
                $htmlContent += "<h6>$($matches[1])</h6>`n"
            }
            elseif ($line -match "^```(.*)") {
                if (-not $inCodeBlock) {
                    $htmlContent += "<pre><code>`n"
                    $inCodeBlock = $true
                } else {
                    $htmlContent += "</code></pre>`n"
                    $inCodeBlock = $false
                }
            }
            elseif ($line -match "^> (.*)") {
                $htmlContent += "<blockquote>$($matches[1])</blockquote>`n"
            }
            elseif ($line -match "^- (.*)") {
                if (-not $inList) {
                    $htmlContent += "<ul>`n"
                    $inList = $true
                }
                $htmlContent += "<li>$($matches[1])</li>`n"
            }
            elseif ($line -match "^\d+\. (.*)") {
                if (-not $inList) {
                    $htmlContent += "<ol>`n"
                    $inList = $true
                }
                $htmlContent += "<li>$($matches[1])</li>`n"
            }
            elseif ($line -match "^\s*$" -and $inList) {
                if ($htmlContent -match "<ul>$") {
                    $htmlContent += "</ul>`n"
                } else {
                    $htmlContent += "</ol>`n"
                }
                $inList = $false
            }
            elseif ($line -match "^\*\*(.*)\*\*$") {
                $htmlContent += "<strong>$($matches[1])</strong>`n"
            }
            elseif ($line -match "^\*(.*)\*$") {
                $htmlContent += "<em>$($matches[1])</em>`n"
            }
            elseif ($line -match "^`(.*)`$") {
                $htmlContent += "<code>$($matches[1])</code>`n"
            }
            elseif ($line -match "^\[(.+)\]\((.+)\)$") {
                $htmlContent += "<a href='$($matches[2])'>$($matches[1])</a>`n"
            }
            else {
                if ($inCodeBlock) {
                    $htmlContent += "$line`n"
                } else {
                    $htmlContent += "<p>$line</p>`n"
                }
            }
        }
        
        # Fermer les blocs ouverts
        if ($inCodeBlock) {
            $htmlContent += "</code></pre>`n"
        }
        if ($inList) {
            if ($htmlContent -match "<ul>$") {
                $htmlContent += "</ul>`n"
            } else {
                $htmlContent += "</ol>`n"
            }
        }
        
        $htmlContent += "</div>`n<hr>`n"
    }
    
    $htmlContent += @"
        </div>
    </div>
</body>
</html>
"@
    
    # Écrire le fichier index.html
    Set-Content -Path $indexFile -Value $htmlContent
    Write-Log "Documentation HTML générée: $indexFile" "SUCCESS"
    
    return $true
}

# Fonction pour générer la documentation PDF
function Generate-PdfDocs {
    param([string]$SrcDir, [string]$DestDir)
    
    Write-Log "Génération de la documentation PDF..." "INFO"
    
    # Vérifier si wkhtmltopdf est disponible
    if (Test-Tool "wkhtmltopdf") {
        # Générer d'abord la documentation HTML
        if (Generate-HtmlDocs -SrcDir $SrcDir -DestDir $DestDir) {
            $htmlFile = Join-Path $DestDir "index.html"
            $pdfFile = Join-Path $DestDir "documentation.pdf"
            
            try {
                wkhtmltopdf $htmlFile $pdfFile
                Write-Log "Documentation PDF générée: $pdfFile" "SUCCESS"
                return $true
            } catch {
                Write-Log "Erreur lors de la génération du PDF: $($_.Exception.Message)" "ERROR"
                return $false
            }
        }
    } else {
        Write-Log "wkhtmltopdf non trouvé, génération du PDF ignorée" "WARN"
        return $false
    }
}

# Fonction pour servir la documentation
function Start-DocServer {
    param([string]$DocDir, [int]$Port = 8080)
    
    Write-Log "Démarrage du serveur de documentation sur le port $Port..." "INFO"
    
    # Créer un serveur HTTP simple
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$Port/")
    $listener.Start()
    
    Write-Log "Documentation disponible à http://localhost:$Port/" "SUCCESS"
    Write-Log "Appuyez sur Ctrl+C pour arrêter le serveur" "INFO"
    
    try {
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            # Déterminer le fichier à servir
            $filePath = ""
            if ($request.Url.AbsolutePath -eq "/" -or $request.Url.AbsolutePath -eq "/index.html") {
                $filePath = Join-Path $DocDir "index.html"
            } else {
                $filePath = Join-Path $DocDir $request.Url.AbsolutePath.TrimStart("/")
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

# Valider le format de sortie
if ($supportedFormats -notcontains $Format) {
    Write-Log "Format non supporté: $Format" "ERROR"
    Write-Log "Formats supportés: $($supportedFormats -join ', ')" "INFO"
    exit 1
}

# Copier les fichiers de documentation
if (-not (Copy-Docs -SrcDir $SourceDir -DestDir $OutputDir)) {
    Write-Log "Échec de la copie des fichiers de documentation" "ERROR"
    exit 1
}

# Générer la documentation selon le format spécifié
$generationSuccess = $false
switch ($Format.ToLower()) {
    "html" {
        $generationSuccess = Generate-HtmlDocs -SrcDir $SourceDir -DestDir $OutputDir
    }
    
    "pdf" {
        $generationSuccess = Generate-PdfDocs -SrcDir $SourceDir -DestDir $OutputDir
    }
    
    "markdown" {
        Write-Log "Documentation Markdown déjà disponible dans $SourceDir" "INFO"
        $generationSuccess = $true
    }
    
    default {
        Write-Log "Format non supporté: $Format" "ERROR"
        exit 1
    }
}

if (-not $generationSuccess) {
    Write-Log "Échec de la génération de la documentation" "ERROR"
    exit 1
}

# Servir la documentation si demandé
if ($Serve) {
    Start-DocServer -DocDir $OutputDir
}

Write-Log "Génération de la documentation terminée !" "SUCCESS"