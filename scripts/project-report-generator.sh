#!/bin/bash

# Script de génération de rapport de projet complet

# Paramètres
OUTPUT_DIR="./reports"
INCLUDE_TESTS=false
INCLUDE_COVERAGE=false
INCLUDE_SECURITY=false
INCLUDE_PERFORMANCE=false

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mGénération du rapport de projet complet\033[0m"
    echo -e "\033[1;36m===================================\033[0m"
}

print_info() {
    echo -e "\033[1;33m$1\033[0m"
}

print_success() {
    echo -e "\033[1;32m✅ $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m❌ $1\033[0m"
}

# Analyse des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --include-tests)
            INCLUDE_TESTS=true
            shift
            ;;
        --include-coverage)
            INCLUDE_COVERAGE=true
            shift
            ;;
        --include-security)
            INCLUDE_SECURITY=true
            shift
            ;;
        --include-performance)
            INCLUDE_PERFORMANCE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -o, --output DIR     Répertoire de sortie (défaut: ./reports)"
            echo "  --include-tests      Inclure les résultats des tests"
            echo "  --include-coverage   Inclure la couverture de code"
            echo "  --include-security   Inclure l'analyse de sécurité"
            echo "  --include-performance Inclure les tests de performance"
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
    print_info "Création du répertoire de sortie: $OUTPUT_DIR"
fi

# Générer le rapport principal
REPORT_FILE="$OUTPUT_DIR/complete-project-report.md"
print_info "Génération du rapport principal..."

# Informations de base du projet
PROJECT_NAME="Dog Breed Identifier"
VERSION="1.0.0"
AUTHOR="Mackly Loick Tchicaya"
DATE=$(date +"%Y-%m-%d %H:%M:%S")
PLATFORM=$(uname -s)

# Structure du projet
PROJECT_STRUCTURE=$(find . -type f | sed 's|^\./||' | grep -v "^$OUTPUT_DIR/" | awk -F'/' '{print $1}' | sort | uniq -c)

# Dépendances
DEPENDENCIES=""
if [ -f "requirements.txt" ]; then
    DEPENDENCIES=$(grep -v "^#" requirements.txt | grep -v "^$" | sed 's/^/- /')
fi

# Scripts
SCRIPTS=$(find scripts -name "*.sh" -type f | sort)

# Générer le contenu du rapport
cat > "$REPORT_FILE" << EOF
# Rapport Complet du Projet Dog Breed Identifier

## Informations Générales

- **Nom du projet**: $PROJECT_NAME
- **Version**: $VERSION
- **Auteur**: $AUTHOR
- **Date de génération**: $DATE
- **Plateforme**: $PLATFORM

## Structure du Projet

EOF

# Ajouter la structure du projet
echo "$PROJECT_STRUCTURE" | while read count dir; do
    if [ -n "$dir" ]; then
        echo "### $dir" >> "$REPORT_FILE"
        echo "Fichiers: $count" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
done

cat >> "$REPORT_FILE" << EOF
## Dépendances

$DEPENDENCIES

## Scripts Disponibles

EOF

# Ajouter les scripts
echo "$SCRIPTS" | while read script; do
    if [ -n "$script" ]; then
        echo "- $script" >> "$REPORT_FILE"
    fi
done

# Ajouter les sections conditionnelles
if [ "$INCLUDE_TESTS" = true ]; then
    cat >> "$REPORT_FILE" << EOF

## Résultats des Tests

*Les résultats des tests seront ajoutés ici.*
EOF
fi

if [ "$INCLUDE_COVERAGE" = true ]; then
    cat >> "$REPORT_FILE" << EOF

## Couverture de Code

*Les informations de couverture de code seront ajoutées ici.*
EOF
fi

if [ "$INCLUDE_SECURITY" = true ]; then
    cat >> "$REPORT_FILE" << EOF

## Analyse de Sécurité

*Les résultats de l'analyse de sécurité seront ajoutés ici.*
EOF
fi

if [ "$INCLUDE_PERFORMANCE" = true ]; then
    cat >> "$REPORT_FILE" << EOF

## Performances

*Les résultats des tests de performance seront ajoutés ici.*
EOF
fi

print_success "Rapport Markdown généré: $REPORT_FILE"

# Générer un rapport HTML complet
HTML_REPORT_FILE="$OUTPUT_DIR/complete-project-report.html"
print_info "Génération du rapport HTML..."

# Compter les fichiers, dépendances et scripts
FILE_COUNT=$(find . -type f | grep -v "^$OUTPUT_DIR/" | wc -l)
DEP_COUNT=$(echo "$DEPENDENCIES" | grep -c "^-")
SCRIPT_COUNT=$(echo "$SCRIPTS" | grep -c ".")

cat > "$HTML_REPORT_FILE" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Rapport Complet du Projet Dog Breed Identifier</title>
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
        h1, h2, h3 { 
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
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .info-card {
            background-color: #e3f2fd;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }
        .info-card h3 {
            margin-top: 0;
            color: #3498db;
        }
        .file-list { 
            columns: 2; 
            column-gap: 30px;
        }
        .file-list div {
            break-inside: avoid;
            margin-bottom: 10px;
        }
        ul {
            line-height: 1.6;
        }
        .stats {
            display: flex;
            justify-content: space-around;
            text-align: center;
            margin: 30px 0;
        }
        .stat-item {
            padding: 20px;
            background-color: #f1f8ff;
            border-radius: 8px;
            flex: 1;
            margin: 0 10px;
        }
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            color: #3498db;
        }
        .stat-label {
            color: #7f8c8d;
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
        <h1>Rapport Complet du Projet Dog Breed Identifier</h1>
        
        <div class="stats">
            <div class="stat-item">
                <div class="stat-number">SCRIPT_COUNT</div>
                <div class="stat-label">Scripts</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">DEP_COUNT</div>
                <div class="stat-label">Dépendances</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">FILE_COUNT</div>
                <div class="stat-label">Fichiers</div>
            </div>
        </div>
        
        <div class="section">
            <h2>Informations Générales</h2>
            <div class="info-grid">
                <div class="info-card">
                    <h3>Nom du projet</h3>
                    <p>PROJECT_NAME</p>
                </div>
                <div class="info-card">
                    <h3>Version</h3>
                    <p>VERSION</p>
                </div>
                <div class="info-card">
                    <h3>Auteur</h3>
                    <p>AUTHOR</p>
                </div>
                <div class="info-card">
                    <h3>Date de génération</h3>
                    <p>DATE</p>
                </div>
                <div class="info-card">
                    <h3>Plateforme</h3>
                    <p>PLATFORM</p>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>Structure du Projet</h2>
            <div class="file-list">
EOF

# Ajouter la structure du projet en HTML
echo "$PROJECT_STRUCTURE" | while read count dir; do
    if [ -n "$dir" ]; then
        echo "<div><strong>$dir:</strong> $count fichiers</div>" >> "$HTML_REPORT_FILE"
    fi
done

cat >> "$HTML_REPORT_FILE" << 'EOF'
            </div>
        </div>
        
        <div class="section">
            <h2>Dépendances</h2>
            <table>
                <thead>
                    <tr>
                        <th>Dépendance</th>
                    </tr>
                </thead>
                <tbody>
EOF

# Ajouter les dépendances
echo "$DEPENDENCIES" | while read dep; do
    if [ -n "$dep" ]; then
        dep_name=$(echo "$dep" | sed 's/^- //')
        echo "<tr><td><code>$dep_name</code></td></tr>" >> "$HTML_REPORT_FILE"
    fi
done

cat >> "$HTML_REPORT_FILE" << 'EOF'
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>Scripts Disponibles</h2>
            <table>
                <thead>
                    <tr>
                        <th>Nom du Script</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
EOF

# Ajouter les scripts
echo "$SCRIPTS" | while read script; do
    if [ -n "$script" ]; then
        script_name=$(basename "$script")
        description="Script Bash pour $(basename "$script" .sh)"
        echo "<tr><td><code>$script_name</code></td><td>$description</td></tr>" >> "$HTML_REPORT_FILE"
    fi
done

cat >> "$HTML_REPORT_FILE" << 'EOF'
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>Fonctionnalités Clés</h2>
            <ul>
                <li>Identification automatique des races de chiens via IA</li>
                <li>Interface web responsive</li>
                <li>Système de déploiement automatisé</li>
                <li>Tests unitaires et d'intégration</li>
                <li>Analyse de sécurité complète</li>
                <li>Monitoring des performances</li>
                <li>Génération de documentation</li>
                <li>Gestion des versions</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Remplacer les variables dans le fichier HTML
sed -i "s/SCRIPT_COUNT/$SCRIPT_COUNT/g" "$HTML_REPORT_FILE"
sed -i "s/DEP_COUNT/$DEP_COUNT/g" "$HTML_REPORT_FILE"
sed -i "s/FILE_COUNT/$FILE_COUNT/g" "$HTML_REPORT_FILE"
sed -i "s/PROJECT_NAME/$PROJECT_NAME/g" "$HTML_REPORT_FILE"
sed -i "s/VERSION/$VERSION/g" "$HTML_REPORT_FILE"
sed -i "s/AUTHOR/$AUTHOR/g" "$HTML_REPORT_FILE"
sed -i "s/DATE/$DATE/g" "$HTML_REPORT_FILE"
sed -i "s/PLATFORM/$PLATFORM/g" "$HTML_REPORT_FILE"

print_success "Rapport HTML généré: $HTML_REPORT_FILE"

print_info "Génération des rapports terminée !"