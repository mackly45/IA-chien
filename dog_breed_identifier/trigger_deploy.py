import requests
import os

# Replace with your actual service ID and API key
SERVICE_ID = "srv-d3dqss8dl3ps73c4flpg"
API_KEY = "TrLrhr9ZV14"

# Render API endpoint for triggering deployment
url = f"https://api.render.com/v1/services/{SERVICE_ID}/deploys"

# Headers for the API request
headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Accept": "application/vnd.render+json; version=latest"
}

# Data for the deployment (empty for redeploying latest commit)
data = {}

try:
    # Make the API request
    response = requests.post(url, headers=headers, json=data)
    
    # Check if the request was successful
    if response.status_code == 201:
        print("Deployment triggered successfully!")
        print(f"Deployment ID: {response.json()['id']}")
    else:
        print(f"Failed to trigger deployment. Status code: {response.status_code}")
        print(f"Response: {response.text}")
        
except Exception as e:
    print(f"An error occurred: {str(e)}")