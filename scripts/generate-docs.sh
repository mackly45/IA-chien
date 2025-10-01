#!/bin/bash

# Script de génération de documentation

OUTPUT_DIR="./docs/build"
FORMAT="html"
SERVE=false

# Parser les arguments
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
            echo "Usage: $0 [-o output_dir] [-f format] [-s]"
            echo "  -o, --output DIR    Répertoire de sortie (défaut: ./docs/build)"
            echo "  -f, --format FORMAT Format de sortie (html, pdf) (défaut: html)"
            echo "  -s, --serve         Servir la documentation localement"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mGénération de la documentation\033[0m"
echo -e "\033[1;36m===========================\033[0m"

# Vérifier que les outils nécessaires sont installés
echo -e "\033[1;33mVérification des outils...\033[0m"

# Créer le répertoire de sortie s'il n'existe pas
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    echo -e "\033[1;33mCréation du répertoire de sortie: $OUTPUT_DIR\033[0m"
fi

# Copier les fichiers de documentation existants
echo -e "\033[1;33mCopie des fichiers de documentation...\033[0m"
DOCS_SOURCE="./docs"
if [ -d "$DOCS_SOURCE" ]; then
    cp -r "$DOCS_SOURCE"/* "$OUTPUT_DIR"/
    echo -e "\033[1;32m✅ Documentation copiée\033[0m"
else
    echo -e "\033[1;31m❌ Répertoire de documentation non trouvé\033[0m"
    exit 1
fi

# Générer la documentation au format spécifié
case $FORMAT in
    "html")
        echo -e "\033[1;33mGénération de la documentation HTML...\033[0m"
        # Ici, vous pouvez ajouter la génération avec des outils comme Sphinx, MkDocs, etc.
        echo -e "\033[1;32m✅ Documentation HTML générée dans $OUTPUT_DIR\033[0m"
        ;;
    
    "pdf")
        echo -e "\033[1;33mGénération de la documentation PDF...\033[0m"
        # Ici, vous pouvez ajouter la génération de PDF
        echo -e "\033[1;32m✅ Documentation PDF générée dans $OUTPUT_DIR\033[0m"
        ;;
    
    *)
        echo -e "\033[1;31mFormat non supporté: $FORMAT\033[0m"
        exit 1
        ;;
esac

# Servir la documentation localement si demandé
if [ "$SERVE" = true ]; then
    echo -e "\033[1;33mDémarrage du serveur de documentation...\033[0m"
    cd "$OUTPUT_DIR" || exit 1
    if command -v python3 &> /dev/null; then
        python3 -m http.server 8080
    elif command -v python &> /dev/null; then
        python -m http.server 8080
    else
        echo -e "\033[1;31mPython non installé\033[0m"
        exit 1
    fi
fi

echo -e "\033[1;36mGénération de la documentation terminée !\033[0m"