""""
This python file saves the data from the MQTT broker
to a postgresql database.
"""
import os
from json import JSONDecodeError

import psycopg2
import paho.mqtt.client as mqtt
import json
import datetime
import certifi
from paho.mqtt.client import ssl

if 'SQLALCHEMY_DATABASE_URI' not in os.environ:
    print("'SQLALCHEMY_DATABASE_URI'not set")
    exit(1)

def conn_from_uri(uri):
    # Get the postgres uri from the environment variable
    uri = os.environ.get('SQLALCHEMY_DATABASE_URI')
    # get the various parts of the uri
    uri_parts = uri.split('://')[1].split('@')
    # get the username and password
    user = uri_parts[0].split(':')[0]
    password = uri_parts[0].split(':')[1]
    # get the host and port
    host = uri_parts[1].split('/')[0].split(':')[0]
    port = int(uri_parts[1].split('/')[0].split(':')[1])
    # get the database name
    db = uri_parts[1].split('/')[1].split('?')[0]
    # connect to the database with ssl
    conn = psycopg2.connect(dbname=db, user=user, password=password, host=host, port=port, sslmode='require')
    return conn

conn = conn_from_uri(os.environ.get('SQLALCHEMY_DATABASE_URI'))

def on_connect(client, userdata, flags, rc):
    print("Connected with result code " + str(rc))
    client.subscribe("sensors/+/combined")


def on_message(client, userdata, msg):
    print(msg.topic + " " + str(msg.payload))
    # desjsonify the payload
    try:
        data = json.loads(msg.payload)
    except JSONDecodeError:
        print("JSONDecodeError")
        return
    # get co2, humidity, rawdata and temperature, if present

    co2 = data.get('co2', None)
    humidity = data.get('humidity', None)
    rawdata = data.get('rawdata', None)
    temperature = data.get('temperature', None)
    place_id = data.get('place', None)

    # set the timestamp as now
    timestamp = datetime.datetime.now()
    # get the sensor id from the topic
    sensor_id = msg.topic.split('/')[1]

    cur = conn.cursor()
    # insert the sensor data into the database
    try:
        cur.execute("INSERT INTO sensor_data (sensor_id, timestamp, co2, humidity, rawdata, temperature, lat, lon) "
                    "VALUES (%s, %s, %s, %s, %s, %s, %s, %s)", (sensor_id, timestamp, co2, humidity, rawdata, temperature, 0, 0))
        conn.commit()
    except Exception as e:
        print(e)
        conn.rollback()
    
    cur = conn.cursor()
    # insert the sensor data into the co2_history table
    if place_id:
        try:
            cur = conn.cursor()
            cur.execute("INSERT INTO co2_history (place_id, timestamp, co2) VALUES (%s, %s, %s);",
                        (place_id, timestamp, co2)
                        )
            conn.commit()
        except Exception as e:
            print(e)
            conn.rollback()


client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
# only verify server certificate
#client.tls_set(ca_certs=certifi.where(), cert_reqs=ssl.CERT_REQUIRED,
#               tls_version=ssl.PROTOCOL_TLSv1_2)
#client.tls_insecure_set(True)
# set username and password
client.username_pw_set("test", "test2")

if __name__ != '__main__':
    client.loop_start()

try:
    client.connect("modena.davidepalma.it", 1883, 60)
    print("Connecting to MQTT broker...")
except Exception as e:
    print(e)

if __name__ == "__main__":
    client.loop_forever()