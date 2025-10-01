#!/bin/bash

# Script de vérification de la qualité du code

# Paramètres par défaut
PATHS="./dog_breed_identifier ./scripts ./tests"
FIX=false
VERBOSE=false
OUTPUT_FORMAT="console"

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
REPORTS_DIR="./reports"
QUALITY_TOOLS=("flake8" "black" "isort" "pylint")

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mVérification de la qualité du code\033[0m"
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
        -p|--paths)
            PATHS="$2"
            shift 2
            ;;
        --fix)
            FIX=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -p, --paths PATHS    Chemins à vérifier (défaut: ./dog_breed_identifier ./scripts ./tests)"
            echo "  --fix                Corriger automatiquement les problèmes"
            echo "  -v, --verbose        Mode verbeux"
            echo "  -o, --output FORMAT  Format de sortie (console, file) (défaut: console)"
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

# Fonction pour exécuter une commande et récupérer la sortie
run_tool() {
    local command=$1
    local description=$2
    
    print_log "Exécution: $description" "INFO"
    
    if [ "$VERBOSE" = true ]; then
        eval "$command"
        local exit_code=$?
    else
        eval "$command" > /dev/null 2>&1
        local exit_code=$?
    fi
    
    if [ $exit_code -eq 0 ]; then
        print_log "Succès: $description" "SUCCESS"
        return 0
    else
        print_log "Erreurs trouvées: $description" "WARN"
        return 1
    fi
}

# Créer le répertoire des rapports s'il n'existe pas
if [ ! -d "$REPORTS_DIR" ]; then
    mkdir -p "$REPORTS_DIR"
    print_log "Répertoire des rapports créé: $REPORTS_DIR" "INFO"
fi

# Vérifier les outils de qualité
print_log "Vérification des outils de qualité..." "INFO"
missing_tools=()
available_tools=()

for tool in "${QUALITY_TOOLS[@]}"; do
    if tool_exists "$tool"; then
        print_log "Outil disponible: $tool" "SUCCESS"
        available_tools+=("$tool")
    else
        print_log "Outil manquant: $tool" "WARN"
        missing_tools+=("$tool")
    fi
done

if [ ${#missing_tools[@]} -gt 0 ]; then
    print_log "Certains outils de qualité sont manquants: ${missing_tools[*]}" "WARN"
    print_log "Installez-les avec: pip install ${missing_tools[*]}" "INFO"
fi

if [ ${#available_tools[@]} -eq 0 ]; then
    print_log "Aucun outil de qualité disponible, arrêt du script" "ERROR"
    exit 1
fi

# Exécuter les vérifications de qualité
issues_found=0
checks_performed=0

# Convertir les chemins en tableau
read -ra PATH_ARRAY <<< "$PATHS"

for path in "${PATH_ARRAY[@]}"; do
    if [ ! -d "$path" ] && [ ! -f "$path" ]; then
        print_log "Chemin non trouvé: $path" "WARN"
        continue
    fi
    
    print_log "Vérification de la qualité du code dans: $path" "INFO"
    
    # Vérifier avec flake8
    if [[ " ${available_tools[*]} " =~ " flake8 " ]]; then
        checks_performed=$((checks_performed + 1))
        flake8_cmd="flake8 $path"
        if ! run_tool "$flake8_cmd" "Vérification flake8"; then
            issues_found=$((issues_found + 1))
        fi
    fi
    
    # Vérifier avec pylint
    if [[ " ${available_tools[*]} " =~ " pylint " ]]; then
        checks_performed=$((checks_performed + 1))
        pylint_cmd="pylint $path"
        
        if [ "$OUTPUT_FORMAT" = "console" ]; then
            pylint_cmd+=" --output-format=text"
        else
            pylint_report="$REPORTS_DIR/pylint-report.txt"
            pylint_cmd+=" --output-format=text > $pylint_report"
        fi
        
        if ! run_tool "$pylint_cmd" "Vérification pylint"; then
            issues_found=$((issues_found + 1))
        fi
    fi
    
    # Formater avec black (et corriger si demandé)
    if [[ " ${available_tools[*]} " =~ " black " ]]; then
        checks_performed=$((checks_performed + 1))
        black_cmd="black"
        
        if [ "$FIX" = false ]; then
            black_cmd+=" --check"
        fi
        
        black_cmd+=" $path"
        
        if ! run_tool "$black_cmd" "Formatage black"; then
            issues_found=$((issues_found + 1))
        fi
    fi
    
    # Trier les imports avec isort (et corriger si demandé)
    if [[ " ${available_tools[*]} " =~ " isort " ]]; then
        checks_performed=$((checks_performed + 1))
        isort_cmd="isort"
        
        if [ "$FIX" = false ]; then
            isort_cmd+=" --check-only"
        fi
        
        isort_cmd+=" $path"
        
        if ! run_tool "$isort_cmd" "Tri des imports isort"; then
            issues_found=$((issues_found + 1))
        fi
    fi
done

# Afficher le résumé
echo
echo -e "\033[1;36mRésumé de la vérification de qualité:\033[0m"
echo -e "\033[1;36m================================\033[0m"
echo -e "\033[1;37mChemins vérifiés: $PATHS\033[0m"
echo -e "\033[1;37mOutils disponibles: ${available_tools[*]}\033[0m"
echo -e "\033[1;37mVérifications effectuées: $checks_performed\033[0m"
echo -e "\033[1;37mProblèmes trouvés: $issues_found\033[0m"

if [ $issues_found -eq 0 ]; then
    echo -e "\033[1;32m✅ Code de qualité vérifié avec succès !\033[0m"
    exit 0
else
    echo -e "\033[1;31m❌ Problèmes de qualité du code détectés ($issues_found)\033[0m"
    if [ "$FIX" = false ]; then
        echo -e "\033[1;33m💡 Utilisez l'option --fix pour corriger automatiquement certains problèmes\033[0m"
    fi
    exit 1
fi