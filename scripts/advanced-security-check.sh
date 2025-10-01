#!/bin/bash

# Script de vérification de sécurité avancée

INCLUDE_DEPENDENCIES=true
INCLUDE_CODE_ANALYSIS=true
INCLUDE_CONTAINER_SCAN=true
INCLUDE_SECRETS=true
OUTPUT_FORMAT="console"
OUTPUT_FILE="./security-report.txt"

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-dependencies)
            INCLUDE_DEPENDENCIES=false
            shift
            ;;
        --no-code-analysis)
            INCLUDE_CODE_ANALYSIS=false
            shift
            ;;
        --no-container-scan)
            INCLUDE_CONTAINER_SCAN=false
            shift
            ;;
        --no-secrets)
            INCLUDE_SECRETS=false
            shift
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--no-dependencies] [--no-code-analysis] [--no-container-scan] [--no-secrets] [-f format] [-o output]"
            echo "  --no-dependencies     Exclure la vérification des dépendances"
            echo "  --no-code-analysis    Exclure l'analyse du code"
            echo "  --no-container-scan   Exclure le scan des conteneurs"
            echo "  --no-secrets          Exclure la détection des secrets"
            echo "  -f, --format FORMAT   Format de sortie (console, json, html) (défaut: console)"
            echo "  -o, --output FILE     Fichier de sortie (défaut: ./security-report.txt)"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mVérification de sécurité avancée de Dog Breed Identifier\033[0m"
echo -e "\033[1;36m================================================\033[0m"

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
TEMP_REPORT_FILE=$(mktemp)

# Fonction pour ajouter une entrée au rapport
add_report_entry() {
    local type=$1
    local severity=$2
    local message=$3
    local details=${4:-""}
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$type|$severity|$message|$details|$timestamp" >> "$TEMP_REPORT_FILE"
    
    # Afficher immédiatement si le format est console
    if [ "$OUTPUT_FORMAT" = "console" ]; then
        case $severity in
            "Critical")
                echo -e "\033[1;31m[$severity] $message\033[0m"
                ;;
            "High")
                echo -e "\033[1;31m[$severity] $message\033[0m"
                ;;
            "Medium")
                echo -e "\033[1;33m[$severity] $message\033[0m"
                ;;
            "Low")
                echo -e "\033[1;33m[$severity] $message\033[0m"
                ;;
            "Info")
                echo -e "\033[1;37m[$severity] $message\033[0m"
                ;;
            *)
                echo -e "\033[1;30m[$severity] $message\033[0m"
                ;;
        esac
        
        if [ -n "$details" ]; then
            echo -e "\033[1;30m  Détails: $details\033[0m"
        fi
    fi
}

# Fonction pour vérifier les dépendances vulnérables
check_vulnerable_dependencies() {
    echo -e "\033[1;33mVérification des dépendances vulnérables...\033[0m"
    
    # Vérifier si pip-audit est installé
    if command -v pip-audit &> /dev/null; then
        # Exécuter pip-audit
        if pip-audit >/dev/null 2>&1; then
            add_report_entry "Dependency" "Info" "Aucune dépendance vulnérable trouvée"
        else
            # Récupérer les résultats détaillés
            local audit_result=$(pip-audit 2>&1)
            echo "$audit_result" | while IFS= read -r line; do
                if echo "$line" | grep -q "is vulnerable"; then
                    local package_name=$(echo "$line" | grep -oE '[^ ]+ is vulnerable' | cut -d' ' -f1)
                    local cve=$(echo "$line" | grep -oE 'CVE-[0-9]+-[0-9]+')
                    add_report_entry "Dependency" "High" "Dépendance vulnérable trouvée" "$package_name - $cve"
                fi
            done
        fi
    else
        add_report_entry "Dependency" "Info" "pip-audit non installé" "Installation recommandée: pip install pip-audit"
    fi
}

# Fonction pour analyser le code à la recherche de problèmes de sécurité
analyze_code_security() {
    echo -e "\033[1;33mAnalyse du code pour les problèmes de sécurité...\033[0m"
    
    # Vérifier si bandit est installé (pour Python)
    if command -v bandit &> /dev/null; then
        if bandit -r . -f json >/dev/null 2>&1; then
            add_report_entry "Code" "Info" "Aucun problème de sécurité dans le code trouvé"
        else
            # Récupérer les résultats détaillés
            local bandit_result=$(bandit -r . -f json 2>/dev/null)
            if [ -n "$bandit_result" ]; then
                # Parser le JSON avec jq si disponible
                if command -v jq &> /dev/null; then
                    echo "$bandit_result" | jq -r '.results[] | "\(.issue_severity)|\(.filename):\(.line_number) - \(.issue_text)"' 2>/dev/null | while IFS='|' read -r severity location message; do
                        case $severity in
                            "HIGH")
                                add_report_entry "Code" "High" "Problème de sécurité dans le code" "$location - $message"
                                ;;
                            "MEDIUM")
                                add_report_entry "Code" "Medium" "Problème de sécurité dans le code" "$location - $message"
                                ;;
                            "LOW")
                                add_report_entry "Code" "Low" "Problème de sécurité dans le code" "$location - $message"
                                ;;
                        esac
                    done
                fi
            fi
        fi
    else
        add_report_entry "Code" "Info" "bandit non installé" "Installation recommandée: pip install bandit"
    fi
    
    # Vérifier les patterns dangereux dans le code
    local dangerous_patterns=(
        "eval(:Utilisation de eval() - risque d'exécution de code arbitraire"
        "exec(:Utilisation de exec() - risque d'exécution de code arbitraire"
        "os\.system(:Utilisation de os.system() - risque d'exécution de commande"
        "subprocess\.:Utilisation de subprocess - vérifier les paramètres"
        "input(:Utilisation de input() - risque XSS si non validé"
        "pickle\.:Utilisation de pickle - risque de désérialisation dangereuse"
    )
    
    local files=$(find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.sh" \) -not -path "*/node_modules/*" -not -path "*/venv/*" -not -path "*/.venv/*")
    
    for file in $files; do
        for pattern_info in "${dangerous_patterns[@]}"; do
            IFS=':' read -ra pattern_data <<< "$pattern_info"
            local pattern=${pattern_data[0]}
            local message=${pattern_data[1]}
            
            if grep -qE "$pattern" "$file"; then
                local line_numbers=$(grep -nE "$pattern" "$file" | cut -d: -f1 | tr '\n' ',')
                add_report_entry "Code" "Medium" "Pattern dangereux trouvé" "$file:lignes $line_numbers - $message"
            fi
        done
    done
}

# Fonction pour scanner les conteneurs Docker
scan_docker_containers() {
    echo -e "\033[1;33mScan des conteneurs Docker...\033[0m"
    
    # Vérifier si Docker est installé
    if ! command -v docker &> /dev/null; then
        add_report_entry "Container" "Info" "Docker non installé" "Scan des conteneurs impossible"
        return
    fi
    
    # Vérifier si trivy est installé
    if command -v trivy &> /dev/null; then
        if trivy image --format json dog-breed-identifier >/dev/null 2>&1; then
            add_report_entry "Container" "Info" "Aucune vulnérabilité dans le conteneur trouvée"
        else
            # Récupérer les résultats détaillés
            local trivy_result=$(trivy image --format json dog-breed-identifier 2>/dev/null)
            if [ -n "$trivy_result" ] && command -v jq &> /dev/null; then
                echo "$trivy_result" | jq -r '.Results.Vulnerabilities[] | "\(.Severity)|\(.PkgName):\(.InstalledVersion) - \(.Title)"' 2>/dev/null | while IFS='|' read -r severity package_info title; do
                    case $severity in
                        "CRITICAL")
                            add_report_entry "Container" "Critical" "Vulnérabilité dans le conteneur" "$package_info - $title"
                            ;;
                        "HIGH")
                            add_report_entry "Container" "High" "Vulnérabilité dans le conteneur" "$package_info - $title"
                            ;;
                        "MEDIUM")
                            add_report_entry "Container" "Medium" "Vulnérabilité dans le conteneur" "$package_info - $title"
                            ;;
                        "LOW")
                            add_report_entry "Container" "Low" "Vulnérabilité dans le conteneur" "$package_info - $title"
                            ;;
                    esac
                done
            fi
        fi
    else
        add_report_entry "Container" "Info" "trivy non installé" "Installation recommandée: https://aquasecurity.github.io/trivy/"
    fi
    
    # Vérifier les bonnes pratiques Docker
    if [ -f "Dockerfile" ]; then
        local dockerfile_content=$(cat "Dockerfile")
        
        # Vérifier l'utilisation de USER root
        if echo "$dockerfile_content" | grep -q "USER\s+root"; then
            add_report_entry "Container" "Medium" "Utilisation de USER root dans Dockerfile" "Recommandé: utiliser un utilisateur non-root"
        fi
        
        # Vérifier l'exposition de ports privilégiés
        if echo "$dockerfile_content" | grep -qE "EXPOSE\s+(1|2|3|4|5|6|7|8|9)[0-9]{0,3}"; then
            add_report_entry "Container" "Low" "Exposition de port privilégié" "Les ports < 1024 sont privilégiés"
        fi
        
        # Vérifier ADD vs COPY
        if echo "$dockerfile_content" | grep -q "ADD\s+"; then
            add_report_entry "Container" "Low" "Utilisation de ADD dans Dockerfile" "Recommandé: utiliser COPY au lieu de ADD"
        fi
    fi
}

# Fonction pour détecter les secrets dans le code
detect_secrets() {
    echo -e "\033[1;33mDétection des secrets dans le code...\033[0m"
    
    # Patterns de secrets courants
    local secret_patterns=(
        "AWS Access Key:AKIA[0-9A-Z]{16}:AWS Access Key trouvé"
        "Google API Key:AIza[0-9A-Za-z\\-_]{35}:Google API Key trouvé"
        "Generic API Key:(?i)api(.{0,20})?[\"'][0-9a-zA-Z]{32,45}[\"']:API Key générique trouvée"
        "Password:(?i)(password|pwd)(.{0,20})?[\"'][^\"']{8,}[\"']:Mot de passe trouvé"
        "Token:(?i)token(.{0,20})?[\"'][0-9a-zA-Z\-_]{20,}[\"']:Token trouvé"
        "Private Key:-----BEGIN(.*)PRIVATE KEY-----:Clé privée trouvée"
    )
    
    # Fichiers à exclure
    local exclude_patterns=(
        "\.git"
        "node_modules"
        "venv"
        "\.venv"
        "__pycache__"
        "\.tox"
        "\.eggs"
    )
    
    # Obtenir tous les fichiers
    local files=$(find . -type f -not -path "*/\.*" -not -path "*/node_modules/*" -not -path "*/venv/*" -not -path "*/\.venv/*")
    
    for file in $files; do
        # Vérifier la taille du fichier
        local file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        if [ "$file_size" -gt 10485760 ]; then  # 10MB
            continue
        fi
        
        # Lire le contenu du fichier
        local content=$(cat "$file" 2>/dev/null || continue)
        
        for pattern_info in "${secret_patterns[@]}"; do
            IFS=':' read -ra pattern_data <<< "$pattern_info"
            local pattern_name=${pattern_data[0]}
            local pattern=${pattern_data[1]}
            local message=${pattern_data[2]}
            
            if echo "$content" | grep -qE "$pattern"; then
                # Vérifier les faux positifs
                local is_false_positive=false
                
                if [ "$pattern_name" = "Password" ] && echo "$content" | grep -qiE "(correct|wrong|invalid|placeholder|example)"; then
                    is_false_positive=true
                fi
                
                if [ "$is_false_positive" = false ]; then
                    add_report_entry "Secret" "High" "Potentiel secret trouvé" "$pattern_name dans $file"
                fi
            fi
        done
    done
    
    # Vérifier les fichiers d'environnement
    local env_files=$(find . -name ".env" -o -name ".env.*" | grep -v "\.env\.example")
    for file in $env_files; do
        add_report_entry "Secret" "High" "Fichier d'environnement trouvé" "$file - Ne doit pas être commité"
    done
}

# Fonction pour générer le rapport
generate_report() {
    echo -e "\033[1;33mGénération du rapport de sécurité...\033[0m"
    
    case $OUTPUT_FORMAT in
        "json")
            # Convertir le rapport en JSON
            {
                echo "{"
                echo "  \"project\": \"$PROJECT_NAME\","
                echo "  \"generated\": \"$(date)\","
                echo "  \"findings\": ["
                
                local first_entry=true
                while IFS='|' read -r type severity message details timestamp; do
                    if [ "$first_entry" = false ]; then
                        echo "    ,"
                    fi
                    echo "    {"
                    echo "      \"type\": \"$type\","
                    echo "      \"severity\": \"$severity\","
                    echo "      \"message\": \"$message\","
                    echo "      \"details\": \"$details\","
                    echo "      \"timestamp\": \"$timestamp\""
                    echo "    }"
                    first_entry=false
                done < "$TEMP_REPORT_FILE"
                
                echo "  ]"
                echo "}"
            } > "$OUTPUT_FILE"
            echo -e "\033[1;32m✅ Rapport JSON généré: $OUTPUT_FILE\033[0m"
            ;;
            
        "html")
            # Générer un rapport HTML
            {
                echo "<!DOCTYPE html>"
                echo "<html>"
                echo "<head>"
                echo "    <title>Rapport de Sécurité - $PROJECT_NAME</title>"
                echo "    <style>"
                echo "        body { font-family: Arial, sans-serif; margin: 20px; }"
                echo "        h1 { color: #333; }"
                echo "        .critical { background-color: #ffebee; border-left: 5px solid #f44336; padding: 10px; margin: 10px 0; }"
                echo "        .high { background-color: #fff3e0; border-left: 5px solid #ff9800; padding: 10px; margin: 10px 0; }"
                echo "        .medium { background-color: #fff8e1; border-left: 5px solid #ffc107; padding: 10px; margin: 10px 0; }"
                echo "        .low { background-color: #f1f8e9; border-left: 5px solid #8bc34a; padding: 10px; margin: 10px 0; }"
                echo "        .info { background-color: #e3f2fd; border-left: 5px solid #2196f3; padding: 10px; margin: 10px 0; }"
                echo "        .severity { font-weight: bold; }"
                echo "    </style>"
                echo "</head>"
                echo "<body>"
                echo "    <h1>Rapport de Sécurité - $PROJECT_NAME</h1>"
                echo "    <p>Généré le: $(date)</p>"
                
                while IFS='|' read -r type severity message details timestamp; do
                    local class_name=$(echo "$severity" | tr '[:upper:]' '[:lower:]')
                    echo "    <div class=\"$class_name\">"
                    echo "        <span class=\"severity\">[$severity]</span> $message"
                    echo "        <br><small>$details</small>"
                    echo "        <br><small>$timestamp</small>"
                    echo "    </div>"
                done < "$TEMP_REPORT_FILE"
                
                echo "</body>"
                echo "</html>"
            } > "$OUTPUT_FILE"
            echo -e "\033[1;32m✅ Rapport HTML généré: $OUTPUT_FILE\033[0m"
            ;;
            
        *)
            # Le rapport a déjà été affiché en console
            if [ "$OUTPUT_FILE" != "./security-report.txt" ]; then
                {
                    echo "Rapport de Sécurité - $PROJECT_NAME"
                    echo "Généré le: $(date)"
                    echo ""
                    
                    while IFS='|' read -r type severity message details timestamp; do
                        echo "[$severity] $message"
                        if [ -n "$details" ]; then
                            echo "  Détails: $details"
                        fi
                        echo "  $timestamp"
                        echo ""
                    done < "$TEMP_REPORT_FILE"
                } > "$OUTPUT_FILE"
                echo -e "\033[1;32m✅ Rapport texte généré: $OUTPUT_FILE\033[0m"
            fi
            ;;
    esac
}

# Exécuter les vérifications selon les paramètres
echo -e "\033[1;33mExécution des vérifications de sécurité...\033[0m"

if [ "$INCLUDE_DEPENDENCIES" = true ]; then
    check_vulnerable_dependencies
fi

if [ "$INCLUDE_CODE_ANALYSIS" = true ]; then
    analyze_code_security
fi

if [ "$INCLUDE_CONTAINER_SCAN" = true ]; then
    scan_docker_containers
fi

if [ "$INCLUDE_SECRETS" = true ]; then
    detect_secrets
fi

# Générer le rapport
generate_report

# Afficher le résumé
echo -e "\n\033[1;36mRésumé de la sécurité:\033[0m"
echo -e "\033[1;36m===================\033[0m"

# Compter les problèmes par sévérité
critical_count=$(grep -c "|Critical|" "$TEMP_REPORT_FILE" || echo "0")
high_count=$(grep -c "|High|" "$TEMP_REPORT_FILE" || echo "0")
medium_count=$(grep -c "|Medium|" "$TEMP_REPORT_FILE" || echo "0")
low_count=$(grep -c "|Low|" "$TEMP_REPORT_FILE" || echo "0")

if [ "$critical_count" -gt 0 ]; then
    echo -e "\033[1;31m❌ Critique: $critical_count\033[0m"
fi
if [ "$high_count" -gt 0 ]; then
    echo -e "\033[1;31m⚠️  Haut: $high_count\033[0m"
fi
if [ "$medium_count" -gt 0 ]; then
    echo -e "\033[1;33m⚠️  Moyen: $medium_count\033[0m"
fi
if [ "$low_count" -gt 0 ]; then
    echo -e "\033[1;33mℹ️  Bas: $low_count\033[0m"
fi

total_issues=$((critical_count + high_count + medium_count + low_count))
if [ $total_issues -eq 0 ]; then
    echo -e "\033[1;32m✅ Aucun problème de sécurité trouvé\033[0m"
else
    echo -e "\033[1;37m🔧 $total_issues problèmes de sécurité trouvés\033[0m"
fi

# Nettoyer le fichier temporaire
rm -f "$TEMP_REPORT_FILE"

echo -e "\033[1;36mVérification de sécurité avancée terminée !\033[0m"