#!/bin/bash

# Script de vérification de la santé des conteneurs

# Paramètres par défaut
CONTAINER_NAMES=()
TIMEOUT=30
DETAILED=false
OUTPUT_FORMAT="console"

# Variables de configuration
PROJECT_NAME="Dog Breed Identifier"
REPORTS_DIR="./reports"

# Fonction d'affichage
print_header() {
    echo -e "\033[1;36mVérification de la santé des conteneurs\033[0m"
    echo -e "\033[1;36m=================================\033[0m"
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
        -n|--names)
            IFS=',' read -ra CONTAINER_NAMES <<< "$2"
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
            echo "  -n, --names NAMES    Noms des conteneurs (séparés par des virgules)"
            echo "  -t, --timeout SECONDS Timeout (défaut: 30)"
            echo "  -d, --detailed       Afficher les détails"
            echo "  -o, --output FORMAT  Format de sortie (console, json, html) (défaut: console)"
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

# Fonction pour vérifier si Docker est installé
test_docker() {
    if command -v docker &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Fonction pour obtenir la liste des conteneurs
get_containers() {
    local names=("$@")
    
    print_log "Récupération de la liste des conteneurs..." "INFO"
    
    if [ ${#names[@]} -gt 0 ]; then
        # Filtrer par noms spécifiés
        local containers=""
        for name in "${names[@]}"; do
            local container=$(docker ps --filter "name=$name" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null)
            if [ -n "$container" ]; then
                containers+="$container"$'\n'
            fi
        done
        echo "$containers"
    else
        # Obtenir tous les conteneurs
        docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null
    fi
}

# Fonction pour vérifier la santé d'un conteneur
test_container_health() {
    local container_id=$1
    
    print_log "Vérification de la santé du conteneur: $container_id" "INFO"
    
    # Obtenir l'état du conteneur
    local inspect=$(docker inspect "$container_id" 2>/dev/null)
    if [ -n "$inspect" ]; then
        local status=$(echo "$inspect" | jq -r '.[0].State.Status')
        local running=$(echo "$inspect" | jq -r '.[0].State.Running')
        local health=$(echo "$inspect" | jq -r '.[0].State.Health.Status // "unknown"')
        local started_at=$(echo "$inspect" | jq -r '.[0].State.StartedAt')
        local error=$(echo "$inspect" | jq -r '.[0].State.Error')
        
        echo "$container_id|$status|$running|$health|$started_at|$error"
    fi
}

# Fonction pour vérifier les logs d'un conteneur
get_container_logs() {
    local container_id=$1
    local lines=${2:-20}
    
    print_log "Récupération des logs du conteneur: $container_id" "INFO"
    
    docker logs --tail "$lines" "$container_id" 2>/dev/null
}

# Fonction pour générer un rapport
generate_report() {
    local health_file=$1
    local format=$2
    
    case $format in
        "json")
            local report_file="$REPORTS_DIR/container-health.json"
            
            # Créer un JSON avec les résultats
            cat > "$report_file" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "projectName": "$PROJECT_NAME",
  "containers": [
EOF
            
            # Ajouter les conteneurs
            local first=true
            while IFS='|' read -r id status running health started_at error; do
                if [ "$first" = true ]; then
                    first=false
                else
                    echo "," >> "$report_file"
                fi
                
                cat >> "$report_file" << EOF
    {
      "id": "$id",
      "status": "$status",
      "running": $running,
      "health": "$health",
      "startedAt": "$started_at",
      "error": "$error"
    }
EOF
            done < "$health_file"
            
            cat >> "$report_file" << EOF
  ]
}
EOF
            
            print_log "Rapport JSON généré: $report_file" "SUCCESS"
            ;;
            
        "html")
            local report_file="$REPORTS_DIR/container-health.html"
            
            cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Santé des Conteneurs - $PROJECT_NAME</title>
    <meta charset="UTF-8">
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 20px; 
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
        h1 { 
            color: #2c3e50; 
            text-align: center;
            padding-bottom: 20px;
            border-bottom: 2px solid #3498db;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-item {
            background-color: #e3f2fd;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        .summary-number {
            font-size: 2em;
            font-weight: bold;
            color: #3498db;
        }
        .summary-label {
            color: #7f8c8d;
        }
        .section {
            margin-bottom: 30px;
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
        .health-healthy { color: #4caf50; }
        .health-unhealthy { color: #e74c3c; }
        .health-starting { color: #f39c12; }
        .health-unknown { color: #95a5a6; }
        .status-running { color: #4caf50; }
        .status-stopped { color: #e74c3c; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Santé des Conteneurs - $PROJECT_NAME</h1>
        
        <div class="summary">
            <div class="summary-item">
                <div class="summary-number">$(wc -l < "$health_file")</div>
                <div class="summary-label">Conteneurs</div>
            </div>
EOF
            
            # Compter les conteneurs sains
            local healthy_count=$(grep -c "healthy" "$health_file" || echo "0")
            echo "            <div class=\"summary-item\">" >> "$report_file"
            echo "                <div class=\"summary-number\">$healthy_count</div>" >> "$report_file"
            echo "                <div class=\"summary-label\">Sains</div>" >> "$report_file"
            echo "            </div>" >> "$report_file"
            
            # Compter les conteneurs malades
            local unhealthy_count=$(grep -c "unhealthy" "$health_file" || echo "0")
            echo "            <div class=\"summary-item\">" >> "$report_file"
            echo "                <div class=\"summary-number\">$unhealthy_count</div>" >> "$report_file"
            echo "                <div class=\"summary-label\">Malades</div>" >> "$report_file"
            echo "            </div>" >> "$report_file"
            
            # Compter les conteneurs en cours
            local running_count=$(grep -c "true" "$health_file" || echo "0")
            echo "            <div class=\"summary-item\">" >> "$report_file"
            echo "                <div class=\"summary-number\">$running_count</div>" >> "$report_file"
            echo "                <div class=\"summary-label\">En cours</div>" >> "$report_file"
            echo "            </div>" >> "$report_file"
            
            cat >> "$report_file" << EOF
        </div>
        
        <div class="section">
            <h2>État des Conteneurs</h2>
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Statut</th>
                        <th>Santé</th>
                        <th>Démarré</th>
                    </tr>
                </thead>
                <tbody>
EOF
            
            # Ajouter les conteneurs
            while IFS='|' read -r id status running health started_at error; do
                local status_class=""
                local health_class=""
                
                if [ "$running" = "true" ]; then
                    status_class="status-running"
                else
                    status_class="status-stopped"
                fi
                
                health_class="health-$health"
                
                cat >> "$report_file" << EOF
                    <tr>
                        <td>${id:0:12}</td>
                        <td class="$status_class">$(if [ "$running" = "true" ]; then echo "En cours"; else echo "Arrêté"; fi)</td>
                        <td class="$health_class">$health</td>
                        <td>$started_at</td>
                    </tr>
EOF
            done < "$health_file"
            
            cat >> "$report_file" << EOF
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
EOF
            
            print_log "Rapport HTML généré: $report_file" "SUCCESS"
            ;;
            
        *)
            # Affichage console
            echo
            echo -e "\033[1;36mRésumé de la santé des conteneurs:\033[0m"
            echo -e "\033[1;36m=============================\033[0m"
            echo -e "\033[1;37mConteneurs totaux: $(wc -l < "$health_file")\033[0m"
            
            local healthy_count=$(grep -c "healthy" "$health_file" || echo "0")
            echo -e "\033[1;37mConteneurs sains: $healthy_count\033[0m"
            
            local unhealthy_count=$(grep -c "unhealthy" "$health_file" || echo "0")
            echo -e "\033[1;37mConteneurs malades: $unhealthy_count\033[0m"
            
            local running_count=$(grep -c "true" "$health_file" || echo "0")
            echo -e "\033[1;37mConteneurs en cours: $running_count\033[0m"
            
            if [ "$DETAILED" = true ]; then
                echo
                echo -e "\033[1;36mDétails par conteneur:\033[0m"
                echo -e "\033[1;36m===================\033[0m"
                
                while IFS='|' read -r id status running health started_at error; do
                    echo
                    echo -e "\033[1;37mConteneur: ${id:0:12}\033[0m"
                    if [ "$running" = "true" ]; then
                        echo -e "\033[1;32m  Statut: ✅ En cours\033[0m"
                    else
                        echo -e "\033[1;31m  Statut: ❌ Arrêté\033[0m"
                    fi
                    
                    case $health in
                        "healthy")
                            echo -e "\033[1;32m  Santé: $health\033[0m"
                            ;;
                        "unhealthy")
                            echo -e "\033[1;31m  Santé: $health\033[0m"
                            ;;
                        *)
                            echo -e "\033[1;33m  Santé: $health\033[0m"
                            ;;
                    esac
                    
                    echo -e "\033[1;37m  Démarré: $started_at\033[0m"
                    
                    if [ -n "$error" ] && [ "$error" != "null" ]; then
                        echo -e "\033[1;31m  Erreur: $error\033[0m"
                    fi
                done < "$health_file"
            fi
            ;;
    esac
}

# Vérifier que Docker est installé
if ! test_docker; then
    print_log "Docker n'est pas installé ou n'est pas accessible" "ERROR"
    exit 1
fi

# Créer le répertoire des rapports s'il n'existe pas
if [ ! -d "$REPORTS_DIR" ]; then
    mkdir -p "$REPORTS_DIR"
    print_log "Répertoire des rapports créé: $REPORTS_DIR" "INFO"
fi

# Obtenir la liste des conteneurs
containers=$(get_containers "${CONTAINER_NAMES[@]}")

if [ -z "$containers" ]; then
    print_log "Aucun conteneur trouvé" "WARN"
    exit 0
fi

container_count=$(echo "$containers" | wc -l)
container_count=$((container_count - 1))  # Soustraire l'en-tête
print_log "$container_count conteneurs trouvés" "SUCCESS"

# Fichier temporaire pour stocker la santé des conteneurs
HEALTH_FILE=$(mktemp)

# Vérifier la santé de chaque conteneur
echo "$containers" | while IFS= read -r line; do
    # Extraire l'ID du conteneur (première colonne)
    container_id=$(echo "$line" | awk '{print $1}')
    
    # Ignorer l'en-tête
    if [ "$container_id" = "CONTAINER" ] || [ "$container_id" = "ID" ]; then
        continue
    fi
    
    # Vérifier la santé du conteneur
    health_info=$(test_container_health "$container_id")
    if [ -n "$health_info" ]; then
        echo "$health_info" >> "$HEALTH_FILE"
    fi
done

# Afficher les logs si en mode détaillé
if [ "$DETAILED" = true ]; then
    while IFS='|' read -r id status running health started_at error; do
        echo
        echo -e "\033[1;36mLogs du conteneur ${id:0:12}:\033[0m"
        echo -e "\033[1;36m================================\033[0m"
        get_container_logs "$id"
    done < "$HEALTH_FILE"
fi

# Générer le rapport
generate_report "$HEALTH_FILE" "$OUTPUT_FORMAT"

# Nettoyer le fichier temporaire
rm -f "$HEALTH_FILE"

# Afficher le résumé final
echo
echo -e "\033[1;36mRésumé de la santé des conteneurs:\033[0m"
echo -e "\033[1;36m=============================\033[0m"
echo -e "\033[1;37mConteneurs vérifiés: $(wc -l < "$HEALTH_FILE")\033[0m"

healthy_count=$(grep -c "healthy" "$HEALTH_FILE" || echo "0")
echo -e "\033[1;37mConteneurs sains: $healthy_count\033[0m"

unhealthy_count=$(grep -c "unhealthy" "$HEALTH_FILE" || echo "0")
echo -e "\033[1;37mConteneurs malades: $unhealthy_count\033[0m"

# Déterminer le statut global
all_healthy=false
if [ "$healthy_count" -eq "$(wc -l < "$HEALTH_FILE")" ]; then
    all_healthy=true
fi

any_unhealthy=false
if [ "$unhealthy_count" -gt 0 ]; then
    any_unhealthy=true
fi

if [ "$all_healthy" = true ]; then
    echo
    echo -e "\033[1;32m✅ Tous les conteneurs sont en bonne santé !\033[0m"
    exit 0
elif [ "$any_unhealthy" = true ]; then
    echo
    echo -e "\033[1;31m❌ Certains conteneurs sont en mauvaise santé\033[0m"
    exit 1
else
    echo
    echo -e "\033[1;33m⚠️  Certains conteneurs ont un état de santé inconnu\033[0m"
    exit 0
fi