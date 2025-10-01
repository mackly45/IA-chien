#!/bin/bash

# Script de vérification de performance

DURATION=60
URL="http://localhost:8000"
DETAILED=false

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
        --detailed)
            DETAILED=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-d duration] [-u url] [--detailed]"
            echo "  -d, --duration DURATION  Durée du test en secondes (défaut: 60)"
            echo "  -u, --url URL           URL à tester (défaut: http://localhost:8000)"
            echo "  --detailed              Afficher les détails des requêtes"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mVérification de performance\033[0m"
echo -e "\033[1;36m========================\033[0m"

# Vérifier que l'application est accessible
echo -e "\033[1;33mVérification de l'accessibilité de l'application...\033[0m"

if command -v curl &> /dev/null; then
    if curl -f -s -o /dev/null -w "%{http_code}" "$URL" | grep -q "200"; then
        echo -e "\033[1;32m✅ Application accessible\033[0m"
    else
        echo -e "\033[1;31m❌ Application non accessible\033[0m"
        exit 1
    fi
else
    echo -e "\033[1;31mcurl non installé\033[0m"
    exit 1
fi

# Effectuer un test de charge simple
echo -e "\033[1;33mExécution du test de charge pendant $DURATION secondes...\033[0m"

START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION))
REQUEST_COUNT=0
SUCCESS_COUNT=0
ERROR_COUNT=0

# Tableaux pour stocker les temps de réponse
declare -a RESPONSE_TIMES

while [ $(date +%s) -lt $END_TIME ]; do
    REQUEST_START_TIME=$(date +%s%3N)  # millisecondes
    
    if curl -f -s -o /dev/null "$URL"; then
        REQUEST_END_TIME=$(date +%s%3N)
        RESPONSE_TIME=$((REQUEST_END_TIME - REQUEST_START_TIME))
        
        REQUEST_COUNT=$((REQUEST_COUNT + 1))
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        RESPONSE_TIMES+=($RESPONSE_TIME)
        
        if [ "$DETAILED" = true ]; then
            echo -e "\033[1;32mRequête $REQUEST_COUNT: Succès (Temps: $RESPONSE_TIME ms)\033[0m"
        fi
    else
        REQUEST_END_TIME=$(date +%s%3N)
        RESPONSE_TIME=$((REQUEST_END_TIME - REQUEST_START_TIME))
        
        REQUEST_COUNT=$((REQUEST_COUNT + 1))
        ERROR_COUNT=$((ERROR_COUNT + 1))
        RESPONSE_TIMES+=($RESPONSE_TIME)
        
        if [ "$DETAILED" = true ]; then
            echo -e "\033[1;31mRequête $REQUEST_COUNT: Erreur (Temps: $RESPONSE_TIME ms)\033[0m"
        fi
    fi
    
    # Petit délai pour ne pas surcharger le serveur
    sleep 0.1
done

# Calculer les statistiques
TOTAL_TIME=$((END_TIME - START_TIME))
if [ $TOTAL_TIME -gt 0 ]; then
    REQUESTS_PER_SECOND=$(echo "scale=2; $REQUEST_COUNT / $TOTAL_TIME" | bc)
else
    REQUESTS_PER_SECOND=0
fi

if [ $REQUEST_COUNT -gt 0 ]; then
    SUCCESS_RATE=$(echo "scale=2; $SUCCESS_COUNT * 100 / $REQUEST_COUNT" | bc)
else
    SUCCESS_RATE=0
fi

# Calculer les temps de réponse
AVERAGE_RESPONSE_TIME=0
MIN_RESPONSE_TIME=0
MAX_RESPONSE_TIME=0

if [ ${#RESPONSE_TIMES[@]} -gt 0 ]; then
    # Calculer la moyenne
    SUM=0
    for time in "${RESPONSE_TIMES[@]}"; do
        SUM=$((SUM + time))
    done
    AVERAGE_RESPONSE_TIME=$(echo "scale=2; $SUM / ${#RESPONSE_TIMES[@]}" | bc)
    
    # Trouver le minimum et maximum
    MIN_RESPONSE_TIME=${RESPONSE_TIMES[0]}
    MAX_RESPONSE_TIME=${RESPONSE_TIMES[0]}
    
    for time in "${RESPONSE_TIMES[@]}"; do
        if [ $time -lt $MIN_RESPONSE_TIME ]; then
            MIN_RESPONSE_TIME=$time
        fi
        if [ $time -gt $MAX_RESPONSE_TIME ]; then
            MAX_RESPONSE_TIME=$time
        fi
    done
fi

# Afficher les résultats
echo -e "\n\033[1;36mRésultats de performance:\033[0m"
echo -e "\033[1;36m=====================\033[0m"
echo -e "\033[1;37mDurée du test: $TOTAL_TIME secondes\033[0m"
echo -e "\033[1;37mNombre total de requêtes: $REQUEST_COUNT\033[0m"
echo -e "\033[1;37mRequêtes par seconde: $REQUESTS_PER_SECOND\033[0m"
echo -e "\033[1;37mTaux de succès: $SUCCESS_RATE%\033[0m"
echo -e "\033[1;37mTemps de réponse moyen: $AVERAGE_RESPONSE_TIME ms\033[0m"
echo -e "\033[1;37mTemps de réponse minimum: $MIN_RESPONSE_TIME ms\033[0m"
echo -e "\033[1;37mTemps de réponse maximum: $MAX_RESPONSE_TIME ms\033[0m"

# Afficher les erreurs détaillées si présentes
if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "\n\033[1;31mErreurs détectées: $ERROR_COUNT\033[0m"
    echo -e "\033[1;33mConsultez les logs de l'application pour plus de détails\033[0m"
fi

# Évaluation de la performance
echo -e "\n\033[1;36mÉvaluation:\033[0m"
echo -e "\033[1;36m=========\033[0m"

if (( $(echo "$SUCCESS_RATE >= 95" | bc -l) )); then
    echo -e "\033[1;32m✅ Performance excellente (Taux de succès ≥ 95%)\033[0m"
elif (( $(echo "$SUCCESS_RATE >= 90" | bc -l) )); then
    echo -e "\033[1;33m⚠️  Performance bonne (Taux de succès ≥ 90%)\033[0m"
else
    echo -e "\033[1;31m❌ Performance insuffisante (Taux de succès < 90%)\033[0m"
fi

if (( $(echo "$AVERAGE_RESPONSE_TIME <= 200" | bc -l) )); then
    echo -e "\033[1;32m✅ Temps de réponse excellent (Moyenne ≤ 200ms)\033[0m"
elif (( $(echo "$AVERAGE_RESPONSE_TIME <= 500" | bc -l) )); then
    echo -e "\033[1;33m⚠️  Temps de réponse acceptable (Moyenne ≤ 500ms)\033[0m"
else
    echo -e "\033[1;31m❌ Temps de réponse lent (Moyenne > 500ms)\033[0m"
fi

echo -e "\033[1;36mVérification de performance terminée !\033[0m"