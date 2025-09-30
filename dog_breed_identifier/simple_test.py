import sys
import os

# Add current directory to Python path
sys.path.insert(0, os.getcwd())

print("Current working directory:", os.getcwd())
print("Python path:", sys.path[:3])  # Show first 3 entries

try:
    import dog_identifier
    print("✓ dog_identifier module imported successfully")
    print("Module file:", dog_identifier.__file__)
except ImportError as e:
    print("✗ Failed to import dog_identifier module:", e)

try:
    from dog_identifier import wsgi
    print("✓ WSGI module imported successfully")
except ImportError as e:
    print("✗ Failed to import WSGI module:", e)