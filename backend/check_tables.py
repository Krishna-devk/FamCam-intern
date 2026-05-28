import sqlite3
conn = sqlite3.connect('famcare.db')
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = cursor.fetchall()
print(f"Tables: {tables}")

try:
    cursor.execute("SELECT * FROM services")
    services = cursor.fetchall()
    print(f"Services: {services}")
except Exception as e:
    print(f"Error querying services: {e}")
