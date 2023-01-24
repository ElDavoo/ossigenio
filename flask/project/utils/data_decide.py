"""
Questo file raccoglie i dati dalle varie fonti,
li elabora e li salva in co2_history.
"""
import datetime


def decide(conn, mqtt_client):
    """
    Decide i valori di co2 per ogni posto e li pubblica su MQTT.
    """
    cur = conn.cursor()
    cur.execute("SELECT * FROM place;")
    places = cur.fetchall()
    for place in places:
        # TODO la logica complicata, basata su euristica etc, va qui
        # Cerca nella tabella sensor_data il dato più recente
        # per ogni sensore di quel posto
        cur.execute(
            "SELECT sensor_id, timestamp, co2, humidity, rawdata, temperature, feedback, place "
            "FROM sensor_data "
            "WHERE place = %s "
            "ORDER BY timestamp DESC "
            "LIMIT 25;",
            (place[0],)
        )
        co2 = cur.fetchall()
        # Se non c'è, salta il posto
        if len(co2) == 0:
            continue
        # Calcola la media dei valori di co2
        co2_avg = sum([x[2] for x in co2]) / len(co2)
        # Per ogni feedback ricevuto, alza o abbassa la media
        for value in co2:
            if value[6] is None:
                continue
            if value[6] == "positive":
                co2_avg -= 100
            elif value[6] == "negative":
                co2_avg += 100
            elif value[6] == "neutral":
                co2_avg += 25
        # Se il valore è meno recente di 30 minuti, salta il posto
        # if co2[0][1] < datetime.datetime.now() - datetime.timedelta(minutes=30):
        #    continue
        # Se c'è, salva il dato nella tabella co2_history
        cur.execute("INSERT INTO co2_history (place_id, timestamp, co2) VALUES (%s, %s, %s)",
                    (place[0], datetime.datetime.now(), co2_avg))
        # Pubblica il dato su MQTT con retain
        mqtt_client.publish("places/{}/co2".format(place[0]), co2_avg, retain=True)
