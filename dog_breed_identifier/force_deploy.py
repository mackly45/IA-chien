#!/usr/bin/env python3
"""
Script pour forcer un nouveau déploiement sur Render
"""

import requests
import json

# Remplacez ces valeurs par les vôtres
SERVICE_ID = "srv-d3dqss8dl3ps73c4flpg"
API_KEY = "TrLrhr9ZV14"

def trigger_deploy():
    """Déclenche un nouveau déploiement sur Render"""
    url = f"https://api.render.com/v1/services/{SERVICE_ID}/deploys"
    
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Accept": "application/vnd.render+json; version=latest",
        "Content-Type": "application/json"
    }
    
    # Données pour forcer un déploiement du dernier commit
    data = {
        "branch": "main"  # ou "master" selon votre branche principale
    }
    
    try:
        response = requests.post(url, headers=headers, json=data)
        
        if response.status_code == 201:
            deploy_info = response.json()
            print("✅ Déploiement déclenché avec succès !")
            print(f"🆔 ID du déploiement : {deploy_info.get('id')}")
            print(f"🔄 Statut : {deploy_info.get('status')}")
            print(f"🔗 URL du déploiement : https://dashboard.render.com/web/srv-{SERVICE_ID}/deploys")
        else:
            print(f"❌ Erreur lors du déploiement : {response.status_code}")
            print(f"📝 Réponse : {response.text}")
            
    except Exception as e:
        print(f"❌ Erreur lors de la requête : {str(e)}")

if __name__ == "__main__":
    print("🚀 Déclenchement d'un nouveau déploiement sur Render...")
    trigger_deploy()