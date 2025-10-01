#!/bin/bash

# Script de vérification de la qualité du code

echo -e "\033[1;36mVérification de la qualité du code\033[0m"
echo -e "\033[1;36m================================\033[0m"

# Vérifier le formatage avec black
echo -e "\033[1;33mVérification du formatage avec black...\033[0m"
if ! command -v black &> /dev/null; then
    echo -e "\033[1;31mblack n'est pas installé. Installez-le avec 'pip install black'.\033[0m"
    exit 1
fi

black --check .

if [ $? -ne 0 ]; then
    echo -e "\033[1;31mLe code n'est pas correctement formaté. Exécutez 'black .' pour le formater.\033[0m"
    exit 1
fi

# Vérifier le linting avec flake8
echo -e "\033[1;33mVérification du linting avec flake8...\033[0m"
if ! command -v flake8 &> /dev/null; then
    echo -e "\033[1;31mflake8 n'est pas installé. Installez-le avec 'pip install flake8'.\033[0m"
    exit 1
fi

flake8 .

if [ $? -ne 0 ]; then
    echo -e "\033[1;31mDes problèmes de linting ont été détectés.\033[0m"
    exit 1
fi

# Vérifier l'ordonnancement des imports avec isort
echo -e "\033[1;33mVérification de l'ordonnancement des imports avec isort...\033[0m"
if ! command -v isort &> /dev/null; then
    echo -e "\033[1;31misort n'est pas installé. Installez-le avec 'pip install isort'.\033[0m"
    exit 1
fi

isort --check-only .

if [ $? -ne 0 ]; then
    echo -e "\033[1;31mLes imports ne sont pas correctement ordonnés. Exécutez 'isort .' pour les ordonner.\033[0m"
    exit 1
fi

echo -e "\033[1;32m✅ Toutes les vérifications de qualité du code ont réussi !\033[0m"