#!/bin/bash

# Script pour exécuter tous les tests du projet

echo -e "\033[1;36m=== Tests du Projet Dog Breed Identifier ===\033[0m"

# Créer un réseau Docker pour les tests
echo -e "\033[1;33mCréation du réseau Docker pour les tests...\033[0m"
docker network create dog-breed-test-net 2>/dev/null || true

# Construire l'image de test
echo -e "\033[1;33mConstruction de l'image de test...\033[0m"
docker build -t dog-breed-identifier-test -f Dockerfile.test .

# Exécuter les tests
echo -e "\033[1;33mExécution des tests...\033[0m"
docker run --rm \
  --network dog-breed-test-net \
  -v "$(pwd)/tests:/app/tests" \
  dog-breed-identifier-test

# Nettoyer
echo -e "\033[1;33mNettoyage...\033[0m"
docker network rm dog-breed-test-net 2>/dev/null || true

echo -e "\033[1;32mTests terminés !\033[0m"