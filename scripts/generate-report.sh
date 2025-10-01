#!/bin/bash

# Script de génération de rapport

OUTPUT_DIR="./reports"
INCLUDE_TESTS=false
INCLUDE_COVERAGE=false

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -t|--tests)
            INCLUDE_TESTS=true
            shift
            ;;
        -c|--coverage)
            INCLUDE_COVERAGE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-o output_dir] [-t] [-c]"
            echo "  -o, --output DIR    Répertoire de sortie (défaut: ./reports)"
            echo "  -t, --tests         Inclure les résultats des tests"
            echo "  -c, --coverage      Inclure la couverture de code"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mGénération du rapport de projet\033[0m"
echo -e "\033[1;36m===========================\033[0m"

# Créer le répertoire de sortie s'il n'existe pas
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    echo -e "\033[1;33mCréation du répertoire de sortie: $OUTPUT_DIR\033[0m"
fi

# Générer le rapport principal
REPORT_FILE="$OUTPUT_DIR/project-report.md"
echo -e "\033[1;33mGénération du rapport principal...\033[0m"

# Informations de base du projet
PROJECT_NAME="Dog Breed Identifier"
PROJECT_VERSION="1.0.0"
PROJECT_AUTHOR="Mackly Loick Tchicaya"
GENERATION_DATE=$(date +"%Y-%m-%d %H:%M:%S")
PLATFORM=$(uname -s)

# Générer le contenu du rapport
cat > "$REPORT_FILE" << EOF
# Rapport du Projet Dog Breed Identifier

## Informations Générales

- **Nom du projet**: $PROJECT_NAME
- **Version**: $PROJECT_VERSION
- **Auteur**: $PROJECT_AUTHOR
- **Date de génération**: $GENERATION_DATE
- **Plateforme**: $PLATFORM

## Structure du Projet

EOF

# Ajouter la structure du projet
echo "Répertoires et fichiers:" >> "$REPORT_FILE"
find . -type d -not -path "*/.*" -not -path "./reports*" | sort | while read dir; do
    if [ "$dir" != "." ]; then
        file_count=$(find "$dir" -type f -not -path "*/.*" 2>/dev/null | wc -l)
        if [ "$file_count" -gt 0 ]; then
            echo "- $(basename "$dir"): $file_count fichiers" >> "$REPORT_FILE"
        fi
    fi
done

# Ajouter les dépendances
echo -e "\n## Dépendances" >> "$REPORT_FILE"
if [ -f "requirements.txt" ]; then
    grep -v "^#" requirements.txt | grep -v "^$" >> "$REPORT_FILE"
else
    echo "*Aucun fichier requirements.txt trouvé*" >> "$REPORT_FILE"
fi

# Ajouter les scripts disponibles
echo -e "\n## Scripts Disponibles" >> "$REPORT_FILE"
if [ -d "scripts" ]; then
    find scripts -name "*.sh" -type f | while read script; do
        echo "- $(basename "$script")" >> "$REPORT_FILE"
    done
else
    echo "*Aucun répertoire scripts trouvé*" >> "$REPORT_FILE"
fi

# Ajouter les résultats des tests si demandé
if [ "$INCLUDE_TESTS" = true ]; then
    echo -e "\n## Résultats des Tests" >> "$REPORT_FILE"
    echo "*Les résultats des tests seront ajoutés ici.*" >> "$REPORT_FILE"
fi

# Ajouter la couverture de code si demandé
if [ "$INCLUDE_COVERAGE" = true ]; then
    echo -e "\n## Couverture de Code" >> "$REPORT_FILE"
    echo "*Les informations de couverture de code seront ajoutées ici.*" >> "$REPORT_FILE"
fi

echo -e "\033[1;32m✅ Rapport généré: $REPORT_FILE\033[0m"

# Générer un rapport HTML si demandé
HTML_REPORT_FILE="$OUTPUT_DIR/project-report.html"
echo -e "\033[1;33mGénération du rapport HTML...\033[0m"

cat > "$HTML_REPORT_FILE" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Rapport du Projet Dog Breed Identifier</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1, h2, h3 { color: #333; }
        .section { margin-bottom: 30px; }
        .info { background-color: #f5f5f5; padding: 15px; border-radius: 5px; }
        .file-list { columns: 3; }
    </style>
</head>
<body>
    <h1>Rapport du Projet Dog Breed Identifier</h1>
    
    <div class="section">
        <h2>Informations Générales</h2>
        <div class="info">
            <p><strong>Nom du projet:</strong> '"$PROJECT_NAME"'</p>
            <p><strong>Version:</strong> '"$PROJECT_VERSION"'</p>
            <p><strong>Auteur:</strong> '"$PROJECT_AUTHOR"'</p>
            <p><strong>Date de génération:</strong> '"$GENERATION_DATE"'</p>
            <p><strong>Plateforme:</strong> '"$PLATFORM"'</p>
        </div>
    </div>
    
    <div class="section">
        <h2>Structure du Projet</h2>
        <div class="file-list">
EOF

# Ajouter la structure du projet au HTML
find . -type d -not -path "*/.*" -not -path "./reports*" | sort | while read dir; do
    if [ "$dir" != "." ]; then
        file_count=$(find "$dir" -type f -not -path "*/.*" 2>/dev/null | wc -l)
        if [ "$file_count" -gt 0 ]; then
            echo "<p><strong>$(basename "$dir"):</strong> $file_count fichiers</p>" >> "$HTML_REPORT_FILE"
        fi
    fi
done

cat >> "$HTML_REPORT_FILE" << 'EOF'
        </div>
    </div>
    
    <div class="section">
        <h2>Dépendances</h2>
        <ul>
EOF

# Ajouter les dépendances au HTML
if [ -f "requirements.txt" ]; then
    grep -v "^#" requirements.txt | grep -v "^$" | while read dep; do
        echo "<li>$dep</li>" >> "$HTML_REPORT_FILE"
    done
else
    echo "<li><em>Aucun fichier requirements.txt trouvé</em></li>" >> "$HTML_REPORT_FILE"
fi

cat >> "$HTML_REPORT_FILE" << 'EOF'
        </ul>
    </div>
    
    <div class="section">
        <h2>Scripts Disponibles</h2>
        <ul>
EOF

# Ajouter les scripts au HTML
if [ -d "scripts" ]; then
    find scripts -name "*.sh" -type f | while read script; do
        echo "<li>$(basename "$script")</li>" >> "$HTML_REPORT_FILE"
    done
else
    echo "<li><em>Aucun répertoire scripts trouvé</em></li>" >> "$HTML_REPORT_FILE"
fi

cat >> "$HTML_REPORT_FILE" << 'EOF'
        </ul>
    </div>
</body>
</html>
EOF

echo -e "\033[1;32m✅ Rapport HTML généré: $HTML_REPORT_FILE\033[0m"

echo -e "\033[1;36mGénération des rapports terminée !\033[0m"