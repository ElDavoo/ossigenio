#1. - Load libraries
from sqlalchemy import create_engine
import sqlite3
import pandas as pd

# 2.- Create your connection.
#engine = create_engine('sqlite:////home/antonio/test.db')
#cnx = sqlite3.connect('test.db')
cursor = cnx.cursor()

# 3.- Create tables
cursor.execute('CREATE TABLE IF NOT EXISTS device (id integer PRIMARY KEY);')

cursor.execute('CREATE TABLE IF NOT EXISTS utente(id serial PRIMARY KEY,'
                'email text NOT NULL,password text NOT NULL,name text NOT NULL,'
                'serialnum INTEGER NOT NULL,admin bool DEFAULT false,'
                'FOREIGN KEY (serialNum) REFERENCES device(id));'
                )

cursor.execute('CREATE TABLE IF NOT EXISTS sensor_data (sensor_id integer NOT NULL,'
                'timestamp timestamp NOT NULL,co2 integer NOT NULL,humidity integer NOT NULL,'
                'rawdata integer NOT NULL,temperature integer NOT NULL,lat integer NOT NULL,lon integer NOT NULL,'
                'FOREIGN KEY (sensor_id) REFERENCES device(id),PRIMARY KEY(sensor_id,timestamp));'
                )

cursor.execute('INSERT INTO device (id) VALUES (000)')

password=generate_password_hash('password123', method='sha256')
cursor.execute('INSERT INTO user (email,password,name,serialNum,admin) VALUES ("admin@admin.com","'+password+'","Admin",000,true)')

cnx.commit()
cnx.close()