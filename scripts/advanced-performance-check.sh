#!/bin/bash

# Script de vérification de performance avancée

DURATION=300  # 5 minutes par défaut
URL="http://localhost:8000"
CONCURRENT_USERS=10
ENDPOINTS=("/")
INCLUDE_DATABASE=false
INCLUDE_ML=false
OUTPUT_FORMAT="console"
OUTPUT_FILE="./performance-report.txt"

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -u|--url)
            URL="$2"
            shift 2
            ;;
        -c|--concurrent)
            CONCURRENT_USERS="$2"
            shift 2
            ;;
        -e|--endpoints)
            IFS=',' read -ra ENDPOINTS <<< "$2"
            shift 2
            ;;
        --include-database)
            INCLUDE_DATABASE=true
            shift
            ;;
        --include-ml)
            INCLUDE_ML=true
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
            echo "Usage: $0 [-d duration] [-u url] [-c concurrent] [-e endpoints] [--include-database] [--include-ml] [-f format] [-o output]"
            echo "  -d, --duration SECONDS     Durée du test (défaut: 300)"
            echo "  -u, --url URL              URL de test (défaut: http://localhost:8000)"
            echo "  -c, --concurrent USERS     Nombre d'utilisateurs concurrents (défaut: 10)"
            echo "  -e, --endpoints ENDPOINTS  Endpoints à tester (séparés par des virgules) (défaut: /)"
            echo "  --include-database         Inclure le test de performance de la base de données"
            echo "  --include-ml               Inclure le test de performance du modèle ML"
            echo "  -f, --format FORMAT        Format de sortie (console, json, html) (défaut: console)"
            echo "  -o, --output FILE          Fichier de sortie (défaut: ./performance-report.txt)"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mVérification de performance avancée de Dog Breed Identifier\033[0m"
echo -e "\033[1;36m====================================================\033[0m"

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
TEMP_REPORT_FILE=$(mktemp)
METRICS_FILE=$(mktemp)

# Initialiser les métriques
echo "totalRequests:0" > "$METRICS_FILE"
echo "successfulRequests:0" >> "$METRICS_FILE"
echo "failedRequests:0" >> "$METRICS_FILE"
echo "totalTime:0" >> "$METRICS_FILE"
echo "throughput:0" >> "$METRICS_FILE"
echo "errorRate:0" >> "$METRICS_FILE"

# Fonction pour ajouter une entrée au rapport
add_report_entry() {
    local type=$1
    local message=$2
    shift 2
    local details=""
    
    # Récupérer les détails
    while [[ $# -gt 0 ]]; do
        details="$details$1;"
        shift
    done
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$type|$message|$details|$timestamp" >> "$TEMP_REPORT_FILE"
    
    # Afficher immédiatement si le format est console
    if [ "$OUTPUT_FORMAT" = "console" ]; then
        echo -e "\033[1;37m[$type] $message\033[0m"
        if [ -n "$details" ]; then
            IFS=';' read -ra detail_array <<< "$details"
            for detail in "${detail_array[@]}"; do
                if [ -n "$detail" ]; then
                    echo -e "\033[1;30m  $detail\033[0m"
                fi
            done
        fi
    fi
}

# Fonction pour mettre à jour une métrique
update_metric() {
    local metric_name=$1
    local value=$2
    
    # Mettre à jour le fichier de métriques
    sed -i "s/^$metric_name:.*/$metric_name:$value/" "$METRICS_FILE"
}

# Fonction pour obtenir une métrique
get_metric() {
    local metric_name=$1
    grep "^$metric_name:" "$METRICS_FILE" | cut -d: -f2
}

# Fonction pour effectuer un test de charge HTTP
invoke_load_test() {
    local target_url=$1
    local users=$2
    local test_duration=$3
    shift 3
    local test_endpoints=("$@")
    
    echo -e "\033[1;33mExécution du test de charge...\033[0m"
    add_report_entry "LoadTest" "Démarrage du test de charge" \
        "URL:$target_url" \
        "Utilisateurs:$users" \
        "Durée:$test_duration secondes" \
        "Endpoints:$(IFS=,; echo "${test_endpoints[*]}")"
    
    # Variables pour le suivi des métriques
    local requests=0
    local successes=0
    local failures=0
    local total_response_time=0
    local response_times_file=$(mktemp)
    
    # Calculer l'heure de fin
    local end_time=$(($(date +%s) + test_duration))
    
    # Créer des processus pour simuler les utilisateurs concurrents
    local pids=()
    
    for ((i=0; i<users; i++)); do
        (
            local job_requests=0
            local job_successes=0
            local job_failures=0
            local job_response_times_file=$(mktemp)
            
            while [ $(date +%s) -lt $end_time ]; do
                # Choisir un endpoint aléatoire
                local endpoint_index=$((RANDOM % ${#test_endpoints[@]}))
                local endpoint=${test_endpoints[$endpoint_index]}
                local full_url="$target_url$endpoint"
                
                local request_start_time=$(date +%s%3N)  # millisecondes
                if command -v curl &> /dev/null; then
                    if curl -s -f -o /dev/null "$full_url"; then
                        local request_end_time=$(date +%s%3N)
                        local response_time=$((request_end_time - request_start_time))
                        echo "$response_time" >> "$job_response_times_file"
                        ((job_successes++))
                    else
                        local request_end_time=$(date +%s%3N)
                        local response_time=$((request_end_time - request_start_time))
                        echo "$response_time" >> "$job_response_times_file"
                        ((job_failures++))
                    fi
                fi
                
                ((job_requests++))
                
                # Petit délai pour ne pas surcharger
                sleep $(awk "BEGIN {print $((RANDOM % 150 + 50)) / 1000}")
            done
            
            # Retourner les résultats
            echo "requests:$job_requests" >> "/tmp/job_$i.result"
            echo "successes:$job_successes" >> "/tmp/job_$i.result"
            echo "failures:$job_failures" >> "/tmp/job_$i.result"
            cat "$job_response_times_file" >> "/tmp/job_$i.times"
            rm -f "$job_response_times_file"
        ) &
        
        pids+=($!)
    done
    
    # Attendre la fin de tous les processus
    for pid in "${pids[@]}"; do
        wait $pid
    done
    
    # Agréger les résultats
    for ((i=0; i<users; i++)); do
        if [ -f "/tmp/job_$i.result" ]; then
            local job_requests=$(grep "^requests:" "/tmp/job_$i.result" | cut -d: -f2)
            local job_successes=$(grep "^successes:" "/tmp/job_$i.result" | cut -d: -f2)
            local job_failures=$(grep "^failures:" "/tmp/job_$i.result" | cut -d: -f2)
            
            requests=$((requests + job_requests))
            successes=$((successes + job_successes))
            failures=$((failures + job_failures))
            
            if [ -f "/tmp/job_$i.times" ]; then
                cat "/tmp/job_$i.times" >> "$response_times_file"
            fi
            
            rm -f "/tmp/job_$i.result" "/tmp/job_$i.times"
        fi
    done
    
    # Calculer les métriques
    local total_time=$test_duration
    local throughput=0
    local error_rate=0
    
    if [ $total_time -gt 0 ]; then
        throughput=$(echo "scale=2; $requests / $total_time" | bc)
    fi
    
    if [ $requests -gt 0 ]; then
        error_rate=$(echo "scale=2; ($failures / $requests) * 100" | bc)
    fi
    
    # Calculer les temps de réponse
    local avg_response_time=0
    local min_response_time=0
    local max_response_time=0
    
    if [ -s "$response_times_file" ]; then
        local response_count=$(wc -l < "$response_times_file")
        local response_sum=$(awk '{sum+=$1} END {print sum}' "$response_times_file")
        avg_response_time=$(echo "scale=2; $response_sum / $response_count" | bc)
        min_response_time=$(sort -n "$response_times_file" | head -n1)
        max_response_time=$(sort -n "$response_times_file" | tail -n1)
    fi
    
    # Mettre à jour les métriques globales
    update_metric "totalRequests" "$requests"
    update_metric "successfulRequests" "$successes"
    update_metric "failedRequests" "$failures"
    update_metric "totalTime" "$total_time"
    update_metric "throughput" "$throughput"
    update_metric "errorRate" "$error_rate"
    
    # Ajouter au rapport
    add_report_entry "LoadTest" "Test de charge terminé" \
        "Requêtes totales:$requests" \
        "Requêtes réussies:$successes" \
        "Requêtes échouées:$failures" \
        "Débit (req/s):$throughput" \
        "Taux d'erreur (%):$error_rate" \
        "Temps de réponse moyen (ms):$avg_response_time" \
        "Temps de réponse minimum (ms):$min_response_time" \
        "Temps de réponse maximum (ms):$max_response_time"
    
    # Nettoyer le fichier temporaire
    rm -f "$response_times_file"
}

# Fonction pour tester les performances de la base de données
test_database_performance() {
    echo -e "\033[1;33mTest des performances de la base de données...\033[0m"
    
    # Vérifier si l'application est accessible
    if command -v curl &> /dev/null; then
        if curl -s -f -o /dev/null "$URL/health/"; then
            add_report_entry "Database" "Endpoint de santé accessible"
        else
            add_report_entry "Database" "Endpoint de santé non accessible" "Code:$(curl -s -o /dev/null -w "%{http_code}" "$URL/health/")"
            return
        fi
    else
        add_report_entry "Database" "curl non installé"
        return
    fi
    
    # Test de latence de la base de données
    local start_time=$(date +%s%3N)
    local db_test_result=false
    
    if curl -s -f -o /dev/null "$URL/api/db-test/"; then
        db_test_result=true
    fi
    
    local end_time=$(date +%s%3N)
    local db_latency=$((end_time - start_time))
    
    add_report_entry "Database" "Test de latence de la base de données" "Latence (ms):$db_latency"
}

# Fonction pour tester les performances du modèle ML
test_ml_performance() {
    echo -e "\033[1;33mTest des performances du modèle ML...\033[0m"
    
    # Créer une image de test temporaire
    local test_image_path=$(mktemp --suffix=.jpg)
    
    # Générer une image de test (vous pouvez utiliser une image existante)
    echo "Test image content" > "$test_image_path"
    
    # Mesurer le temps de traitement de l'image
    local start_time=$(date +%s%3N)
    local ml_test_result=false
    
    if command -v curl &> /dev/null; then
        if curl -s -f -o /dev/null -X POST -H "Content-Type: image/jpeg" --data-binary "@$test_image_path" "$URL/api/identify/"; then
            ml_test_result=true
        fi
    fi
    
    local end_time=$(date +%s%3N)
    local ml_latency=$((end_time - start_time))
    
    add_report_entry "ML" "Test de latence du modèle ML" "Latence (ms):$ml_latency"
    
    # Nettoyer le fichier de test
    rm -f "$test_image_path"
}

# Fonction pour générer le rapport
generate_report() {
    echo -e "\033[1;33mGénération du rapport de performance...\033[0m"
    
    case $OUTPUT_FORMAT in
        "json")
            # Générer un rapport JSON
            {
                echo "{"
                echo "  \"project\": \"$PROJECT_NAME\","
                echo "  \"generated\": \"$(date)\","
                echo "  \"metrics\": {"
                echo "    \"totalRequests\": $(get_metric "totalRequests"),"
                echo "    \"successfulRequests\": $(get_metric "successfulRequests"),"
                echo "    \"failedRequests\": $(get_metric "failedRequests"),"
                echo "    \"totalTime\": $(get_metric "totalTime"),"
                echo "    \"throughput\": $(get_metric "throughput"),"
                echo "    \"errorRate\": $(get_metric "errorRate")"
                echo "  },"
                echo "  \"findings\": ["
                
                local first_entry=true
                while IFS='|' read -r type message details timestamp; do
                    if [ "$first_entry" = false ]; then
                        echo "    ,"
                    fi
                    echo "    {"
                    echo "      \"type\": \"$type\","
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
                echo "    <title>Rapport de Performance - $PROJECT_NAME</title>"
                echo "    <style>"
                echo "        body { font-family: Arial, sans-serif; margin: 20px; }"
                echo "        h1 { color: #333; }"
                echo "        .metrics { background-color: #f5f5f5; padding: 20px; border-radius: 5px; margin: 20px 0; }"
                echo "        .finding { border-left: 5px solid #2196f3; padding: 10px; margin: 10px 0; }"
                echo "        .finding.loadtest { border-left-color: #4caf50; }"
                echo "        .finding.database { border-left-color: #ff9800; }"
                echo "        .finding.ml { border-left-color: #9c27b0; }"
                echo "        table { width: 100%; border-collapse: collapse; margin: 20px 0; }"
                echo "        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }"
                echo "        th { background-color: #f2f2f2; }"
                echo "    </style>"
                echo "</head>"
                echo "<body>"
                echo "    <h1>Rapport de Performance - $PROJECT_NAME</h1>"
                echo "    <p>Généré le: $(date)</p>"
                
                echo "    <div class=\"metrics\">"
                echo "        <h2>Métriques Globales</h2>"
                echo "        <table>"
                echo "            <tr><th>Métrique</th><th>Valeur</th></tr>"
                echo "            <tr><td>Requêtes totales</td><td>$(get_metric "totalRequests")</td></tr>"
                echo "            <tr><td>Requêtes réussies</td><td>$(get_metric "successfulRequests")</td></tr>"
                echo "            <tr><td>Requêtes échouées</td><td>$(get_metric "failedRequests")</td></tr>"
                echo "            <tr><td>Durée totale (s)</td><td>$(get_metric "totalTime")</td></tr>"
                echo "            <tr><td>Débit (req/s)</td><td>$(get_metric "throughput")</td></tr>"
                echo "            <tr><td>Taux d'erreur (%)</td><td>$(get_metric "errorRate")</td></tr>"
                
                # Ajouter les temps de réponse si disponibles
                while IFS='|' read -r type message details timestamp; do
                    if [[ $details == *"Temps de réponse moyen (ms):"* ]]; then
                        local avg_time=$(echo "$details" | grep -oE "Temps de réponse moyen \(ms\):[^;]+" | cut -d: -f2)
                        local min_time=$(echo "$details" | grep -oE "Temps de réponse minimum \(ms\):[^;]+" | cut -d: -f2)
                        local max_time=$(echo "$details" | grep -oE "Temps de réponse maximum \(ms\):[^;]+" | cut -d: -f2)
                        
                        if [ -n "$avg_time" ]; then
                            echo "            <tr><td>Temps de réponse moyen (ms)</td><td>$avg_time</td></tr>"
                            echo "            <tr><td>Temps de réponse minimum (ms)</td><td>$min_time</td></tr>"
                            echo "            <tr><td>Temps de réponse maximum (ms)</td><td>$max_time</td></tr>"
                        fi
                        break
                    fi
                done < "$TEMP_REPORT_FILE"
                
                echo "        </table>"
                echo "    </div>"
                
                echo "    <h2>Résultats des Tests</h2>"
                
                while IFS='|' read -r type message details timestamp; do
                    local class_name=$(echo "$type" | tr '[:upper:]' '[:lower:]')
                    echo "    <div class=\"finding $class_name\">"
                    echo "        <h3>[$type] $message</h3>"
                    
                    if [ -n "$details" ]; then
                        echo "        <ul>"
                        IFS=';' read -ra detail_array <<< "$details"
                        for detail in "${detail_array[@]}"; do
                            if [ -n "$detail" ]; then
                                local key=$(echo "$detail" | cut -d: -f1)
                                local value=$(echo "$detail" | cut -d: -f2-)
                                echo "            <li><strong>$key:</strong> $value</li>"
                            fi
                        done
                        echo "        </ul>"
                    fi
                    
                    echo "        <small>$timestamp</small>"
                    echo "    </div>"
                done < "$TEMP_REPORT_FILE"
                
                echo "</body>"
                echo "</html>"
            } > "$OUTPUT_FILE"
            echo -e "\033[1;32m✅ Rapport HTML généré: $OUTPUT_FILE\033[0m"
            ;;
            
        *)
            # Le rapport a déjà été affiché en console
            if [ "$OUTPUT_FILE" != "./performance-report.txt" ]; then
                {
                    echo "Rapport de Performance - $PROJECT_NAME"
                    echo "Généré le: $(date)"
                    echo ""
                    
                    echo "Métriques Globales:"
                    echo "=================="
                    echo "Requêtes totales: $(get_metric "totalRequests")"
                    echo "Requêtes réussies: $(get_metric "successfulRequests")"
                    echo "Requêtes échouées: $(get_metric "failedRequests")"
                    echo "Durée totale (s): $(get_metric "totalTime")"
                    echo "Débit (req/s): $(get_metric "throughput")"
                    echo "Taux d'erreur (%): $(get_metric "errorRate")"
                    echo ""
                    
                    echo "Résultats des Tests:"
                    echo "==================="
                    
                    while IFS='|' read -r type message details timestamp; do
                        echo "[$type] $message"
                        if [ -n "$details" ]; then
                            IFS=';' read -ra detail_array <<< "$details"
                            for detail in "${detail_array[@]}"; do
                                if [ -n "$detail" ]; then
                                    echo "  $detail"
                                fi
                            done
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

# Exécuter les tests selon les paramètres
echo -e "\033[1;33mExécution des tests de performance...\033[0m"

# Test de charge principal
invoke_load_test "$URL" "$CONCURRENT_USERS" "$DURATION" "${ENDPOINTS[@]}"

# Tests supplémentaires si demandés
if [ "$INCLUDE_DATABASE" = true ]; then
    test_database_performance
fi

if [ "$INCLUDE_ML" = true ]; then
    test_ml_performance
fi

# Générer le rapport
generate_report

# Afficher le résumé
echo -e "\n\033[1;36mRésumé des performances:\033[0m"
echo -e "\033[1;36m=====================\033[0m"

echo -e "\033[1;37mMétriques Globales:\033[0m"
echo -e "\033[1;30m  Requêtes totales: $(get_metric "totalRequests")\033[0m"
echo -e "\033[1;30m  Requêtes réussies: $(get_metric "successfulRequests")\033[0m"
echo -e "\033[1;30m  Requêtes échouées: $(get_metric "failedRequests")\033[0m"
echo -e "\033[1;30m  Débit (req/s): $(get_metric "throughput")\033[0m"
echo -e "\033[1;30m  Taux d'erreur (%): $(get_metric "errorRate")\033[0m"

# Nettoyer les fichiers temporaires
rm -f "$TEMP_REPORT_FILE" "$METRICS_FILE"

echo -e "\033[1;36mVérification de performance avancée terminée !\033[0m"