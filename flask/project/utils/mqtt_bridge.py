"""
This python file saves the data from the MQTT broker
to a postgresql database.
"""
import datetime
import json
import os
import threading
from json import JSONDecodeError

import paho.mqtt.client as mqtt
import psycopg2
from paho.mqtt.client import ssl

from project.utils.telegram import on_update

if 'SQLALCHEMY_DATABASE_URI' not in os.environ:
    print("'SQLALCHEMY_DATABASE_URI'not set")
    exit(1)


def conn_from_uri():
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
    conne = psycopg2.connect(dbname=db, user=user, password=password, host=host, port=port, sslmode='require')
    return conne


def on_connect(mclient, _, __, rc):
    print("Connected with result code " + str(rc))
    mclient.subscribe("sensors/+/combined")


def on_message(_, __, msg):
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
    feedback = data.get('feedback', None)

    # set the timestamp as now
    timestamp = datetime.datetime.now()
    # get the sensor id from the topic
    sensor_id = msg.topic.split('/')[1]

    cur = conn.cursor()
    # insert the sensor data into the database
    try:
        cur.execute("INSERT INTO sensor_data (sensor_id, timestamp, co2, humidity, rawdata, temperature, feedback, "
                    "place)"
                    "VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                    (sensor_id, timestamp, co2, humidity, rawdata, temperature, feedback, place_id))
        conn.commit()
    except Exception as e:
        print(e)
        conn.rollback()

    # insert the sensor data into the co2_history table
    if place_id:
        try:
            cur = conn.cursor()
            cur.execute("INSERT INTO co2_history (place_id, timestamp, co2) VALUES (%s, %s, %s);",
                        (place_id, timestamp, co2)
                        )
            conn.commit()
        except Exception as ex:
            print(ex)
            conn.rollback()

    # send the data to the telegram bot
    cur = conn.cursor()
    try:
        on_update(data, cur)
        conn.commit()
    except Exception as e:
        print(e)
        conn.rollback()


conn = conn_from_uri()


def run():
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    # enable ssl
    client.tls_set(cert_reqs=ssl.CERT_REQUIRED,
                   tls_version=ssl.PROTOCOL_TLSv1_2)
    # client.tls_insecure_set(True)
    # set username and password
    client.username_pw_set("test", "test2")
    try:
        print("Connecting to MQTT broker...")
        client.connect("mqtt.ossigenio.it", 8080, 60)
        client.loop_forever()
    except Exception as e:
        print(e)


def start():
    return threading.Thread(target=run).start()
