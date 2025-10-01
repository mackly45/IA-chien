#!/bin/bash

# Script de génération de documentation

# Paramètres par défaut
SOURCE_DIR="./docs"
OUTPUT_DIR="./docs/build"
FORMAT="html"
SERVE=false
VERBOSE=false

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
SUPPORTED_FORMATS=("html" "pdf" "markdown")

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mGénération de la documentation\033[0m"
    echo -e "\033[1;36m===========================\033[0m"
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
        -s|--source)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        --serve)
            SERVE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -s, --source DIR     Répertoire source (défaut: ./docs)"
            echo "  -o, --output DIR     Répertoire de sortie (défaut: ./docs/build)"
            echo "  -f, --format FORMAT  Format de sortie (html, pdf, markdown) (défaut: html)"
            echo "  --serve              Servir la documentation localement"
            echo "  -v, --verbose        Mode verbeux"
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

# Fonction pour vérifier si un outil est installé
tool_exists() {
    command -v "$1" &> /dev/null
}

# Fonction pour copier les fichiers de documentation
copy_docs() {
    local src_dir=$1
    local dest_dir=$2
    
    print_log "Copie des fichiers de documentation..." "INFO"
    
    if [ ! -d "$src_dir" ]; then
        print_log "Répertoire source non trouvé: $src_dir" "ERROR"
        return 1
    fi
    
    # Créer le répertoire de destination s'il n'existe pas
    if [ ! -d "$dest_dir" ]; then
        mkdir -p "$dest_dir"
        print_log "Répertoire de destination créé: $dest_dir" "INFO"
    fi
    
    # Copier les fichiers
    if cp -r "$src_dir"/* "$dest_dir"/; then
        print_log "Fichiers de documentation copiés avec succès" "SUCCESS"
        return 0
    else
        print_log "Erreur lors de la copie des fichiers" "ERROR"
        return 1
    fi
}

# Fonction pour générer la documentation HTML
generate_html_docs() {
    local src_dir=$1
    local dest_dir=$2
    
    print_log "Génération de la documentation HTML..." "INFO"
    
    # Créer l'index HTML
    local index_file="$dest_dir/index.html"
    
    # Lire les fichiers Markdown existants
    local md_files=("$src_dir"/*.md)
    
    cat > "$index_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Documentation - $PROJECT_NAME</title>
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
        <h1>Documentation - $PROJECT_NAME</h1>
        
        <div class="nav">
EOF
    
    # Ajouter les liens de navigation
    for file in "${md_files[@]}"; do
        if [ -f "$file" ]; then
            filename=$(basename "$file" .md)
            display_name=$(echo "$filename" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
            echo "<a href='#$filename'>$display_name</a>" >> "$index_file"
        fi
    done
    
    cat >> "$index_file" << EOF
        </div>
        
        <div class="content">
EOF
    
    # Ajouter le contenu de chaque fichier
    for file in "${md_files[@]}"; do
        if [ -f "$file" ]; then
            filename=$(basename "$file" .md)
            display_name=$(echo "$filename" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
            
            cat >> "$index_file" << EOF
<div id='$filename'>
<h2>$display_name</h2>
EOF
            
            # Conversion basique Markdown vers HTML
            while IFS= read -r line; do
                if [[ $line =~ ^#(.*) ]]; then
                    echo "<h1>${BASH_REMATCH[1]}</h1>" >> "$index_file"
                elif [[ $line =~ ^##(.*) ]]; then
                    echo "<h2>${BASH_REMATCH[1]}</h2>" >> "$index_file"
                elif [[ $line =~ ^###(.*) ]]; then
                    echo "<h3>${BASH_REMATCH[1]}</h3>" >> "$index_file"
                elif [[ $line =~ ^####(.*) ]]; then
                    echo "<h4>${BASH_REMATCH[1]}</h4>" >> "$index_file"
                elif [[ $line =~ ^#####(.*) ]]; then
                    echo "<h5>${BASH_REMATCH[1]}</h5>" >> "$index_file"
                elif [[ $line =~ ^######(.*) ]]; then
                    echo "<h6>${BASH_REMATCH[1]}</h6>" >> "$index_file"
                elif [[ $line =~ ^\`\`\`(.*) ]]; then
                    echo "<pre><code>" >> "$index_file"
                elif [[ $line =~ ^\`\`\`$ ]]; then
                    echo "</code></pre>" >> "$index_file"
                elif [[ $line =~ ^>(.*) ]]; then
                    echo "<blockquote>${BASH_REMATCH[1]}</blockquote>" >> "$index_file"
                elif [[ $line =~ ^- (.*) ]]; then
                    echo "<ul><li>${BASH_REMATCH[1]}</li></ul>" >> "$index_file"
                elif [[ $line =~ ^[0-9]+\. (.*) ]]; then
                    echo "<ol><li>${BASH_REMATCH[1]}</li></ol>" >> "$index_file"
                elif [[ $line =~ ^\*\*(.*)\*\*$ ]]; then
                    echo "<strong>${BASH_REMATCH[1]}</strong>" >> "$index_file"
                elif [[ $line =~ ^\*(.*)\*$ ]]; then
                    echo "<em>${BASH_REMATCH[1]}</em>" >> "$index_file"
                elif [[ $line =~ ^\`(.*)\`$ ]]; then
                    echo "<code>${BASH_REMATCH[1]}</code>" >> "$index_file"
                elif [[ $line =~ ^\[(.+)\]\((.+)\)$ ]]; then
                    echo "<a href='${BASH_REMATCH[2]}'>${BASH_REMATCH[1]}</a>" >> "$index_file"
                else
                    echo "<p>$line</p>" >> "$index_file"
                fi
            done < "$file"
            
            echo "</div><hr>" >> "$index_file"
        fi
    done
    
    cat >> "$index_file" << EOF
        </div>
    </div>
</body>
</html>
EOF
    
    print_log "Documentation HTML générée: $index_file" "SUCCESS"
    return 0
}

# Fonction pour générer la documentation PDF
generate_pdf_docs() {
    local src_dir=$1
    local dest_dir=$2
    
    print_log "Génération de la documentation PDF..." "INFO"
    
    # Vérifier si wkhtmltopdf est disponible
    if tool_exists "wkhtmltopdf"; then
        # Générer d'abord la documentation HTML
        if generate_html_docs "$src_dir" "$dest_dir"; then
            local html_file="$dest_dir/index.html"
            local pdf_file="$dest_dir/documentation.pdf"
            
            if wkhtmltopdf "$html_file" "$pdf_file"; then
                print_log "Documentation PDF générée: $pdf_file" "SUCCESS"
                return 0
            else
                print_log "Erreur lors de la génération du PDF" "ERROR"
                return 1
            fi
        fi
    else
        print_log "wkhtmltopdf non trouvé, génération du PDF ignorée" "WARN"
        return 1
    fi
}

# Valider le format de sortie
valid_format=false
for supported_format in "${SUPPORTED_FORMATS[@]}"; do
    if [ "$FORMAT" = "$supported_format" ]; then
        valid_format=true
        break
    fi
done

if [ "$valid_format" = false ]; then
    print_log "Format non supporté: $FORMAT" "ERROR"
    print_log "Formats supportés: ${SUPPORTED_FORMATS[*]}" "INFO"
    exit 1
fi

# Copier les fichiers de documentation
if ! copy_docs "$SOURCE_DIR" "$OUTPUT_DIR"; then
    print_log "Échec de la copie des fichiers de documentation" "ERROR"
    exit 1
fi

# Générer la documentation selon le format spécifié
generation_success=false
case $FORMAT in
    "html")
        if generate_html_docs "$SOURCE_DIR" "$OUTPUT_DIR"; then
            generation_success=true
        fi
        ;;
    
    "pdf")
        if generate_pdf_docs "$SOURCE_DIR" "$OUTPUT_DIR"; then
            generation_success=true
        fi
        ;;
    
    "markdown")
        print_log "Documentation Markdown déjà disponible dans $SOURCE_DIR" "INFO"
        generation_success=true
        ;;
    
    *)
        print_log "Format non supporté: $FORMAT" "ERROR"
        exit 1
        ;;
esac

if [ "$generation_success" = false ]; then
    print_log "Échec de la génération de la documentation" "ERROR"
    exit 1
fi

# Servir la documentation si demandé
if [ "$SERVE" = true ]; then
    print_log "Démarrage du serveur de documentation..." "INFO"
    
    # Vérifier si Python est disponible
    if tool_exists "python3"; then
        cd "$OUTPUT_DIR"
        print_log "Documentation disponible à http://localhost:8080/" "SUCCESS"
        print_log "Appuyez sur Ctrl+C pour arrêter le serveur" "INFO"
        python3 -m http.server 8080
    else
        print_log "Python non trouvé, impossible de démarrer le serveur" "ERROR"
        exit 1
    fi
fi

print_log "Génération de la documentation terminée !" "SUCCESS"