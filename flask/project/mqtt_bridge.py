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

conn = psycopg2.connect(
    host="localhost",
    database="flask",
    user="postgres",
    password=os.environ['DB_PASSWORD'])


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

    # set the timestamp as now
    timestamp = datetime.datetime.now()
    # get the sensor id from the topic
    sensor_id = msg.topic.split('/')[1]

    cur = conn.cursor()
    # insert the data into the database
    try:
        cur.execute("INSERT INTO sensor_data (sensor_id, timestamp, co2, humidity, rawdata, temperature) "
                    "VALUES (%s, %s, %s, %s, %s, %s)", (sensor_id, timestamp, co2, humidity, rawdata, temperature))
        conn.commit()
    except Exception as e:
        print(e)
        conn.rollback()

if 'DB_PASSWORD' not in os.environ:
    print("DB_PASSWORD not set")
    exit(1)
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