#!/bin/bash

# Script de benchmark de performance

ITERATIONS=100
IMAGE_URL="https://example.com/test-dog-image.jpg"

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--iterations)
            ITERATIONS="$2"
            shift 2
            ;;
        -u|--url)
            IMAGE_URL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-i iterations] [-u image_url]"
            echo "  -i, --iterations ITERATIONS  Nombre d'itérations (défaut: 100)"
            echo "  -u, --url IMAGE_URL          URL de l'image de test"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

echo -e "\033[1;36mBenchmark de performance Dog Breed Identifier\033[0m"
echo -e "\033[1;36m===========================================\033[0m"

# Vérifier que l'application est en cours d'exécution
echo -e "\033[1;33mVérification de l'application...\033[0m"
if command -v curl &> /dev/null; then
    if curl -f -s -o /dev/null -w "%{http_code}" "http://localhost:8000/health/" | grep -q "200"; then
        echo -e "\033[1;32m✅ Application en cours d'exécution\033[0m"
    else
        echo -e "\033[1;31m❌ Application non accessible\033[0m"
        exit 1
    fi
else
    echo -e "\033[1;31mcurl non installé\033[0m"
    exit 1
fi

# Télécharger une image de test si nécessaire
TEST_IMAGE="./test-image.jpg"
if [ ! -f "$TEST_IMAGE" ]; then
    echo -e "\033[1;33mTéléchargement de l'image de test...\033[0m"
    if command -v wget &> /dev/null; then
        if wget -q "$IMAGE_URL" -O "$TEST_IMAGE"; then
            echo -e "\033[1;32m✅ Image de test téléchargée\033[0m"
        else
            echo -e "\033[1;31m❌ Échec du téléchargement de l'image de test\033[0m"
            exit 1
        fi
    elif command -v curl &> /dev/null; then
        if curl -s -o "$TEST_IMAGE" "$IMAGE_URL"; then
            echo -e "\033[1;32m✅ Image de test téléchargée\033[0m"
        else
            echo -e "\033[1;31m❌ Échec du téléchargement de l'image de test\033[0m"
            exit 1
        fi
    else
        echo -e "\033[1;31mwget ou curl non installé\033[0m"
        exit 1
    fi
fi

# Effectuer le benchmark
echo -e "\033[1;33mExécution du benchmark avec $ITERATIONS itérations...\033[0m"

timings=()
total_time=0

for ((i=1; i<=ITERATIONS; i++)); do
    start_time=$(date +%s%3N)  # millisecondes
    
    if curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Content-Type: image/jpeg" \
        --data-binary "@$TEST_IMAGE" \
        "http://localhost:8000/api/identify/" | grep -q "200"; then
        
        end_time=$(date +%s%3N)
        duration=$((end_time - start_time))
        timings+=($duration)
        total_time=$((total_time + duration))
        
        # Afficher la progression
        percent=$((i * 100 / ITERATIONS))
        printf "\r\033[1;37mProgression: %d/%d (%d%%)\033[0m" $i $ITERATIONS $percent
    else
        end_time=$(date +%s%3N)
        duration=$((end_time - start_time))
        timings+=($duration)
        total_time=$((total_time + duration))
        
        printf "\r\033[1;31m❌ Itération %d échouée\033[0m" $i
    fi
done

echo -e "\n"

# Calculer les statistiques
if [ ${#timings[@]} -gt 0 ]; then
    average_time=$((total_time / ${#timings[@]}))
    
    # Trier les timings pour calculer min, max et percentiles
    sorted_timings=($(printf '%s\n' "${timings[@]}" | sort -n))
    min_time=${sorted_timings[0]}
    max_time=${sorted_timings[$((${#sorted_timings[@]} - 1))]}
    
    # Calculer le 95e percentile
    percentile_95_index=$((${#sorted_timings[@]} * 95 / 100))
    percentile_95=${sorted_timings[$percentile_95_index]}
    
    echo -e "\033[1;36mRésultats du benchmark:\033[0m"
    echo -e "\033[1;36m=====================\033[0m"
    echo -e "\033[1;37mItérations: $ITERATIONS\033[0m"
    echo -e "\033[1;37mTemps moyen: $(echo "scale=2; $average_time/1" | bc) ms\033[0m"
    echo -e "\033[1;37mTemps minimum: $min_time ms\033[0m"
    echo -e "\033[1;37mTemps maximum: $max_time ms\033[0m"
    echo -e "\033[1;37m95e percentile: $percentile_95 ms\033[0m"
else
    echo -e "\033[1;31m❌ Aucune itération réussie\033[0m"
fi

# Nettoyer l'image de test
if [ -f "$TEST_IMAGE" ]; then
    rm "$TEST_IMAGE"
fi

echo -e "\033[1;36mBenchmark terminé !\033[0m"