#!/bin/bash

# Script de monitoring de l'application

PORT=${1:-8000}

echo -e "\033[1;36mMonitoring de l'application Dog Breed Identifier\033[0m"
echo -e "\033[1;36m=============================================\033[0m"

# Vérifier si le port est utilisé
echo -e "\033[1;33mVérification du port $PORT...\033[0m"
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "\033[1;32m✅ Port $PORT en cours d'utilisation\033[0m"
    PID=$(lsof -t -i:$PORT)
    PROCESS=$(ps -p $PID -o comm=)
    echo -e "\033[1;37mProcessus: $PROCESS (PID: $PID)\033[0m"
else
    echo -e "\033[1;31m❌ Port $PORT non utilisé\033[0m"
fi

# Vérifier les conteneurs Docker
echo -e "\033[1;33mVérification des conteneurs Docker...\033[0m"
if command -v docker &> /dev/null; then
    containers=$(docker ps --filter "ancestor=dog-breed-identifier" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")
    
    if [ -n "$containers" ]; then
        echo -e "\033[1;32m✅ Conteneurs Docker trouvés:\033[0m"
        echo -e "\033[1;37m$containers\033[0m"
    else
        echo -e "\033[1;31m❌ Aucun conteneur Docker trouvé pour dog-breed-identifier\033[0m"
    fi
else
    echo -e "\033[1;33mDocker non installé\033[0m"
fi

# Vérifier l'utilisation des ressources
echo -e "\033[1;33mVérification de l'utilisation des ressources...\033[0m"
if command -v top &> /dev/null; then
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo -e "\033[1;37mCPU Usage: ${cpu_usage}%\033[0m"
fi

if command -v free &> /dev/null; then
    memory_usage=$(free | grep Mem | awk '{printf("%.2f"), $3/$2 * 100.0}')
    echo -e "\033[1;37mMemory Usage: ${memory_usage}%\033[0m"
fi

# Vérifier la connectivité réseau
echo -e "\033[1;33mVérification de la connectivité réseau...\033[0m"
if command -v curl &> /dev/null; then
    if curl -f -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/health/" | grep -q "200"; then
        echo -e "\033[1;32m✅ Application accessible sur http://localhost:$PORT/\033[0m"
    else
        echo -e "\033[1;31m❌ Impossible de joindre l'application sur http://localhost:$PORT/\033[0m"
    fi
else
    echo -e "\033[1;33mcurl non installé\033[0m"
fi

echo -e "\033[1;36mMonitoring terminé !\033[0m"