#!/bin/bash

# Script de vérification de sécurité

echo -e "\033[1;36mVérification de la sécurité du projet\033[0m"
echo -e "\033[1;36m===================================\033[0m"

# Vérifier les dépendances vulnérables avec pip-audit
echo -e "\033[1;33mVérification des dépendances vulnérables...\033[0m"
if command -v pip-audit &> /dev/null; then
    pip-audit
    if [ $? -ne 0 ]; then
        echo -e "\033[1;31mDes vulnérabilités ont été détectées dans les dépendances !\033[0m"
        exit 1
    fi
else
    echo -e "\033[1;33mpip-audit n'est pas installé. Installez-le avec 'pip install pip-audit'.\033[0m"
fi

# Vérifier les secrets dans le code
echo -e "\033[1;33mVérification des secrets dans le code...\033[0m"
secret_patterns=(
    "password[[:space:]]*=[[:space:]]*['\"]"
    "secret[[:space:]]*=[[:space:]]*['\"]"
    "token[[:space:]]*=[[:space:]]*['\"]"
    "key[[:space:]]*=[[:space:]]*['\"]"
)

# Trouver les fichiers à vérifier
files=$(find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.env" \) \
    -not -path "*/.*" \
    -not -name "package-lock.json" \
    -not -name "yarn.lock")

secrets_found=false
for file in $files; do
    for pattern in "${secret_patterns[@]}"; do
        if grep -qE "$pattern" "$file"; then
            echo -e "\033[1;31mPotentiel secret trouvé dans $file\033[0m"
            secrets_found=true
        fi
    done
done

if [ "$secrets_found" = true ]; then
    echo -e "\033[1;33m⚠️  Des secrets potentiels ont été trouvés dans le code !\033[0m"
    echo -e "\033[1;33mVeuillez vérifier ces fichiers et utiliser des variables d'environnement à la place.\033[0m"
fi

echo -e "\033[1;32m✅ Vérification de sécurité terminée !\033[0m"