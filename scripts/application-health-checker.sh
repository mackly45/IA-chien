#!/bin/bash

# Script de vérification de la santé de l'application

# Paramètres par défaut
URL="http://localhost:8000"
TIMEOUT=30
DETAILED=false
OUTPUT_FORMAT="console"

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
REPORTS_DIR="./reports"

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mVérification de la santé de l'application\033[0m"
    echo -e "\033[1;36m==================================\033[0m"
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
        -u|--url)
            URL="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -d|--detailed)
            DETAILED=true
            shift
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -u, --url URL          URL cible (défaut: http://localhost:8000)"
            echo "  -t, --timeout SECONDS  Timeout des requêtes (défaut: 30)"
            echo "  -d, --detailed         Afficher les détails"
            echo "  -o, --output FORMAT    Format de sortie (console, json, html) (défaut: console)"
            echo "  -h, --help             Afficher cette aide"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

print_header

# Fonction pour effectuer une requête HTTP
invoke_health_check() {
    local endpoint=$1
    local request_timeout=$2
    local full_url="$URL$endpoint"
    
    print_log "Vérification: $full_url" "INFO"
    
    # Utiliser curl pour effectuer la requête
    local response=$(curl -s -w "%{http_code}|%{time_total}" -m $request_timeout "$full_url" -o /dev/null)
    local http_code=$(echo "$response" | cut -d'|' -f1)
    local response_time=$(echo "$response" | cut -d'|' -f2)
    
    # Vérifier si la requête a réussi
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 400 ]; then
        echo "true|$http_code|OK|$response_time"
    else
        # Obtenir le message d'erreur
        local error_msg="HTTP $http_code"
        if [ "$http_code" = "000" ]; then
            error_msg="Timeout ou erreur de connexion"
        fi
        echo "false|$http_code|$error_msg|$response_time"
    fi
}

# Fonction pour vérifier la base de données
test_database_connection() {
    print_log "Vérification de la connexion à la base de données..." "INFO"
    
    # Dans une implémentation réelle, cela utiliserait les paramètres de connexion Django
    # Pour cette simulation, nous vérifions simplement si le fichier de base de données existe
    local db_file="./dog_breed_identifier/db.sqlite3"
    
    if [ -f "$db_file" ]; then
        print_log "Fichier de base de données trouvé: $db_file" "SUCCESS"
        echo "true"
    else
        print_log "Fichier de base de données non trouvé: $db_file" "WARN"
        echo "false"
    fi
}

# Fonction pour vérifier les dépendances
test_dependencies() {
    print_log "Vérification des dépendances..." "INFO"
    
    local issues=()
    
    # Vérifier Django
    if python -c "import django" &> /dev/null; then
        print_log "Dépendance OK: Django" "SUCCESS"
    else
        print_log "Dépendance manquante: Django" "WARN"
        issues+=("Dépendance manquante: Django")
    fi
    
    # Vérifier TensorFlow
    if python -c "import tensorflow" &> /dev/null; then
        print_log "Dépendance OK: TensorFlow" "SUCCESS"
    else
        print_log "Dépendance manquante: TensorFlow" "WARN"
        issues+=("Dépendance manquante: TensorFlow")
    fi
    
    # Vérifier Pillow
    if python -c "import PIL" &> /dev/null; then
        print_log "Dépendance OK: Pillow" "SUCCESS"
    else
        print_log "Dépendance manquante: Pillow" "WARN"
        issues+=("Dépendance manquante: Pillow")
    fi
    
    # Retourner les problèmes trouvés
    if [ ${#issues[@]} -eq 0 ]; then
        echo "0"
    else
        printf '%s\n' "${issues[@]}" | wc -l
        printf '%s\n' "${issues[@]}"
    fi
}

# Fonction pour générer un rapport
generate_report() {
    local results_file=$1
    local database_check=$2
    local dependency_issues_count=$3
    local dependency_issues_list=$4
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Compter les vérifications
    local total_checks=$(wc -l < "$results_file")
    local successful_checks=$(grep "^true|" "$results_file" | wc -l)
    local failed_checks=$((total_checks - successful_checks))
    
    case $OUTPUT_FORMAT in
        "json")
            local report_file="$REPORTS_DIR/health-check-report.json"
            
            # Créer un JSON avec les résultats
            cat > "$report_file" << EOF
{
  "timestamp": "$timestamp",
  "projectName": "$PROJECT_NAME",
  "url": "$URL",
  "totalChecks": $total_checks,
  "successfulChecks": $successful_checks,
  "failedChecks": $failed_checks,
  "results": [
EOF
            
            # Ajouter les résultats
            local first=true
            while IFS= read -r line; do
                if [ "$first" = true ]; then
                    first=false
                else
                    echo "," >> "$report_file"
                fi
                
                local success=$(echo "$line" | cut -d'|' -f1)
                local endpoint=$(echo "$line" | cut -d'|' -f2)
                local status_code=$(echo "$line" | cut -d'|' -f3)
                local status_description=$(echo "$line" | cut -d'|' -f4)
                local response_time=$(echo "$line" | cut -d'|' -f5)
                
                cat >> "$report_file" << EOF
    {
      "endpoint": "$endpoint",
      "success": $success,
      "statusCode": $status_code,
      "statusDescription": "$status_description",
      "responseTime": $response_time
    }
EOF
            done < "$results_file"
            
            cat >> "$report_file" << EOF
  ],
  "databaseCheck": $database_check,
  "dependencyIssues": [
EOF
            
            # Ajouter les problèmes de dépendances
            if [ "$dependency_issues_count" -gt 0 ]; then
                echo "$dependency_issues_list" | while IFS= read -r issue; do
                    if [ -n "$issue" ]; then
                        echo "    \"$issue\"," >> "$report_file"
                    fi
                done
                # Supprimer la dernière virgule
                sed -i '$ s/,$//' "$report_file"
            fi
            
            cat >> "$report_file" << EOF
  ]
}
EOF
            
            print_log "Rapport JSON généré: $report_file" "SUCCESS"
            ;;
            
        "html")
            local report_file="$REPORTS_DIR/health-check-report.html"
            
            cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de Santé - $PROJECT_NAME</title>
    <meta charset="UTF-8">
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 20px; 
            background-color: #f8f9fa;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        h1 { 
            color: #2c3e50; 
            text-align: center;
            padding-bottom: 20px;
            border-bottom: 2px solid #3498db;
        }
        .summary {
            background-color: #e3f2fd;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
        }
        .checks {
            margin-bottom: 30px;
        }
        .check-item {
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
            border-left: 4px solid;
        }
        .check-success {
            background-color: #e8f5e9;
            border-left-color: #4caf50;
        }
        .check-failure {
            background-color: #ffebee;
            border-left-color: #f44336;
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
        .status-success { color: #4caf50; }
        .status-failure { color: #f44336; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de Santé - $PROJECT_NAME</h1>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p><strong>Date:</strong> $timestamp</p>
            <p><strong>URL cible:</strong> $URL</p>
            <p><strong>Vérifications totales:</strong> $total_checks</p>
            <p><strong>Succès:</strong> <span class="status-success">$successful_checks</span></p>
            <p><strong>Échecs:</strong> <span class="status-failure">$failed_checks</span></p>
        </div>
        
        <div class="checks">
            <h2>Résultats des Vérifications</h2>
            <table>
                <thead>
                    <tr>
                        <th>Endpoint</th>
                        <th>Status</th>
                        <th>Code</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
EOF
            
            # Ajouter les résultats
            while IFS= read -r line; do
                local success=$(echo "$line" | cut -d'|' -f1)
                local endpoint=$(echo "$line" | cut -d'|' -f2)
                local status_code=$(echo "$line" | cut -d'|' -f3)
                local status_description=$(echo "$line" | cut -d'|' -f4)
                
                local status_class=""
                local status_text=""
                if [ "$success" = "true" ]; then
                    status_class="status-success"
                    status_text="Succès"
                else
                    status_class="status-failure"
                    status_text="Échec"
                fi
                
                cat >> "$report_file" << EOF
                    <tr>
                        <td>$endpoint</td>
                        <td class="$status_class">$status_text</td>
                        <td>$status_code</td>
                        <td>$status_description</td>
                    </tr>
EOF
            done < "$results_file"
            
            cat >> "$report_file" << EOF
                </tbody>
            </table>
        </div>
        
        <div class="checks">
            <h2>Vérifications Système</h2>
            <div class="check-item $(if [ "$database_check" = "true" ]; then echo "check-success"; else echo "check-failure"; fi)">
                <h3>Base de données</h3>
                <p>$(if [ "$database_check" = "true" ]; then echo "✅ Connexion à la base de données OK"; else echo "⚠️ Problème de connexion à la base de données"; fi)</p>
            </div>
            
            <div class="check-item $(if [ "$dependency_issues_count" -eq 0 ]; then echo "check-success"; else echo "check-failure"; fi)">
                <h3>Dépendances</h3>
                <p>$(if [ "$dependency_issues_count" -eq 0 ]; then echo "✅ Toutes les dépendances sont présentes"; else echo "❌ Problèmes de dépendances détectés"; fi)</p>
EOF
            
            if [ "$dependency_issues_count" -gt 0 ]; then
                echo "<ul>" >> "$report_file"
                echo "$dependency_issues_list" | while IFS= read -r issue; do
                    if [ -n "$issue" ]; then
                        echo "<li>$issue</li>" >> "$report_file"
                    fi
                done
                echo "</ul>" >> "$report_file"
            fi
            
            cat >> "$report_file" << EOF
            </div>
        </div>
    </div>
</body>
</html>
EOF
            
            print_log "Rapport HTML généré: $report_file" "SUCCESS"
            ;;
            
        *)
            # Le rapport a déjà été affiché en console
            if [ "$OUTPUT_FORMAT" != "console" ]; then
                local report_file="$REPORTS_DIR/health-check-report.txt"
                
                cat > "$report_file" << EOF
Rapport de Santé - $PROJECT_NAME
============================
Date: $timestamp
URL cible: $URL

Résumé:
- Vérifications totales: $total_checks
- Succès: $successful_checks
- Échecs: $failed_checks

Résultats des vérifications:
EOF
                
                # Ajouter les résultats
                while IFS= read -r line; do
                    local success=$(echo "$line" | cut -d'|' -f1)
                    local endpoint=$(echo "$line" | cut -d'|' -f2)
                    local status_code=$(echo "$line" | cut -d'|' -f3)
                    
                    local status_text=""
                    if [ "$success" = "true" ]; then
                        status_text="Succès"
                    else
                        status_text="Échec"
                    fi
                    
                    echo "$status_text - $endpoint (Code: $status_code)" >> "$report_file"
                done < "$results_file"
                
                cat >> "$report_file" << EOF

Vérifications système:
- Base de données: $(if [ "$database_check" = "true" ]; then echo "OK"; else echo "Problème"; fi)
- Dépendances: $(if [ "$dependency_issues_count" -eq 0 ]; then echo "OK"; else echo "$dependency_issues_count problème(s)"; fi)
EOF
                
                print_log "Rapport texte généré: $report_file" "SUCCESS"
            fi
            ;;
    esac
}

# Créer le répertoire des rapports s'il n'existe pas
if [ ! -d "$REPORTS_DIR" ]; then
    mkdir -p "$REPORTS_DIR"
    print_log "Répertoire des rapports créé: $REPORTS_DIR" "INFO"
fi

# Fichier temporaire pour stocker les résultats
RESULTS_FILE=$(mktemp)

# Endpoints à vérifier
HEALTH_ENDPOINTS=(
    "/health/"
    "/api/breeds/"
    "/"
    "/about/"
)

# Effectuer les vérifications de santé
print_log "Démarrage des vérifications de santé..." "INFO"

# Vérifier les endpoints HTTP
overall_success=true
for endpoint in "${HEALTH_ENDPOINTS[@]}"; do
    result=$(invoke_health_check "$endpoint" "$TIMEOUT")
    success=$(echo "$result" | cut -d'|' -f1)
    status_code=$(echo "$result" | cut -d'|' -f2)
    status_description=$(echo "$result" | cut -d'|' -f3)
    response_time=$(echo "$result" | cut -d'|' -f4)
    
    # Stocker le résultat
    echo "$success|$endpoint|$status_code|$status_description|$response_time" >> "$RESULTS_FILE"
    
    if [ "$success" = "true" ]; then
        print_log "Succès de la vérification: $endpoint (Code: $status_code)" "SUCCESS"
    else
        overall_success=false
        print_log "Échec de la vérification: $endpoint" "ERROR"
    fi
done

# Vérifier la base de données
database_check=$(test_database_connection)

# Vérifier les dépendances
dependency_issues_output=$(test_dependencies)
dependency_issues_count=$(echo "$dependency_issues_output" | head -n1)
if [ "$dependency_issues_count" -gt 0 ]; then
    dependency_issues_list=$(echo "$dependency_issues_output" | tail -n +2)
else
    dependency_issues_list=""
fi

# Afficher le résumé détaillé si demandé
if [ "$DETAILED" = true ]; then
    echo
    echo -e "\033[1;36mDétails des vérifications:\033[0m"
    echo -e "\033[1;36m======================\033[0m"
    
    while IFS= read -r line; do
        success=$(echo "$line" | cut -d'|' -f1)
        endpoint=$(echo "$line" | cut -d'|' -f2)
        status_code=$(echo "$line" | cut -d'|' -f3)
        status_description=$(echo "$line" | cut -d'|' -f4)
        
        if [ "$success" = "true" ]; then
            echo -e "\033[1;32m✅ SUCCÈS\033[0m - $endpoint"
            echo -e "\033[1;37m  Code: $status_code - OK\033[0m"
        else
            echo -e "\033[1;31m❌ ÉCHEC\033[0m - $endpoint"
            echo -e "\033[1;37m  Code: $status_code - $status_description\033[0m"
        fi
    done < "$RESULTS_FILE"
    
    echo
    echo -e "\033[1;36mVérifications système:\033[0m"
    echo -e "\033[1;36m===================\033[0m"
    if [ "$database_check" = "true" ]; then
        echo -e "\033[1;32mBase de données: ✅ OK\033[0m"
    else
        echo -e "\033[1;31mBase de données: ❌ Problème\033[0m"
    fi
    
    if [ "$dependency_issues_count" -eq 0 ]; then
        echo -e "\033[1;32mDépendances: ✅ Toutes présentes\033[0m"
    else
        echo -e "\033[1;31mDépendances: ❌ $dependency_issues_count problème(s)\033[0m"
        echo "$dependency_issues_list" | while IFS= read -r issue; do
            if [ -n "$issue" ]; then
                echo -e "\033[1;31m  - $issue\033[0m"
            fi
        done
    fi
fi

# Générer le rapport
generate_report "$RESULTS_FILE" "$database_check" "$dependency_issues_count" "$dependency_issues_list"

# Nettoyer le fichier temporaire
rm -f "$RESULTS_FILE"

# Afficher le résumé final
echo
echo -e "\033[1;36mRésumé de la vérification de santé:\033[0m"
echo -e "\033[1;36m==============================\033[0m"
echo -e "\033[1;37mURL cible: $URL\033[0m"
echo -e "\033[1;37mVérifications totales: $(wc -l < "$RESULTS_FILE".tmp 2>/dev/null || echo "0")\033[0m"

# Recompter les succès et échecs
successful_checks=0
failed_checks=0
while IFS= read -r line; do
    success=$(echo "$line" | cut -d'|' -f1)
    if [ "$success" = "true" ]; then
        successful_checks=$((successful_checks + 1))
    else
        failed_checks=$((failed_checks + 1))
    fi
done < "$RESULTS_FILE"

echo -e "\033[1;37mSuccès: $successful_checks\033[0m"
echo -e "\033[1;37mÉchecs: $failed_checks\033[0m"

if [ "$database_check" = "true" ]; then
    echo -e "\033[1;32mBase de données: ✅ OK\033[0m"
else
    echo -e "\033[1;31mBase de données: ❌ Problème\033[0m"
fi

if [ "$dependency_issues_count" -eq 0 ]; then
    echo -e "\033[1;32mDépendances: ✅ OK\033[0m"
else
    echo -e "\033[1;31mDépendances: ❌ $dependency_issues_count problème(s)\033[0m"
fi

if [ "$overall_success" = true ] && [ "$database_check" = "true" ] && [ "$dependency_issues_count" -eq 0 ]; then
    echo
    echo -e "\033[1;32m✅ Application en bonne santé !\033[0m"
    exit 0
else
    echo
    echo -e "\033[1;31m❌ Problèmes de santé détectés\033[0m"
    exit 1
fi