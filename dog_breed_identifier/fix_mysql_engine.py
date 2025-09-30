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
    
    # Modifier le moteur de stockage pour utiliser InnoDB
    cursor.execute("ALTER TABLE classifier_uploadedimage ENGINE=InnoDB")
    cursor.execute("ALTER TABLE classifier_dogbreed ENGINE=InnoDB")
    
    print("Moteur de stockage modifié avec succès pour utiliser InnoDB")
    
    # Vérifier la structure de la table classifier_uploadedimage
    cursor.execute('DESCRIBE classifier_uploadedimage')
    columns = cursor.fetchall()
    
    print("\nStructure de la table classifier_uploadedimage:")
    for column in columns:
        print(column)
        
    conn.commit()
    conn.close()
    
except Exception as e:
    print(f"Erreur: {e}")