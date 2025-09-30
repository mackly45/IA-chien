import os
import django
import MySQLdb

# Configuration de Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
django.setup()

# Connexion à la base de données MySQL
try:
    conn = MySQLdb.connect(
        host='localhost',
        user='root',
        passwd='',
        db='dog_breed_db'
    )
    
    cursor = conn.cursor()
    
    # Vérifier les migrations Django dans la base de données
    cursor.execute("SELECT * FROM django_migrations WHERE app = 'classifier' ORDER BY id")
    migrations = cursor.fetchall()
    
    print("Migrations appliquées pour l'application 'classifier':")
    for migration in migrations:
        print(f"ID: {migration[0]}, App: {migration[1]}, Name: {migration[2]}, Applied: {migration[3]}")
        
    conn.close()
    
except Exception as e:
    print(f"Erreur: {e}")