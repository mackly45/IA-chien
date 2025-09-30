import os
import django

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dog_identifier.settings')
django.setup()

from django.db import connections

# Get the MySQL database connection
mysql_conn = connections['mysql']
cursor = mysql_conn.cursor()

try:
    # Check if the table exists and what fields it has
    cursor.execute("DESCRIBE classifier_uploadedimage")
    columns = cursor.fetchall()
    print("classifier_uploadedimage table structure:")
    for column in columns:
        print(column)
        
    print("\n" + "="*50 + "\n")
    
    # Check if the dogbreed table exists and what fields it has
    cursor.execute("DESCRIBE classifier_dogbreed")
    columns = cursor.fetchall()
    print("classifier_dogbreed table structure:")
    for column in columns:
        print(column)
        
except Exception as e:
    print(f"Error: {e}")
finally:
    cursor.close()