# Connect to an existing database
import os

import psycopg2

# Check if DB_PASSWORD is set
if 'DB_PASSWORD' not in os.environ:
    print("DB_PASSWORD not set")
    exit(1)

conn = psycopg2.connect(
        host="localhost",
        database="iot",
        user="iot",
        password=os.environ['DB_PASSWORD'])

# Open a cursor to perform database operations
cur = conn.cursor()

# Check if table iot already exists
cur.execute("SELECT EXISTS(SELECT * FROM information_schema.tables WHERE table_name=%s)", ('measurements',))
if cur.fetchone()[0]:
    print("Warning: Table iot already exists, continue? (y/n)")
    if input() != 'y':
        exit(1)



# Execute a command: this creates a new table
cur.execute('CREATE TABLE IF NOT EXISTS measurements (id serial PRIMARY KEY,'
                                 'lat integer NOT NULL,'
                                 'lon integer NOT NULL,'
                                 'temp integer NOT NULL,'
                                 'hum integer NOT NULL,'
                                 'co2 integer NOT NULL);'
                                 )

# Insert data into the table

cur.execute('INSERT INTO measurements (lat, lon, temp, hum, co2) VALUES (1, 2, 3, 4, 5);')

conn.commit()

cur.close()
conn.close()
print("init done")