"""
A file that, every 30 minutes, generates a random number of CO2 for every place
and saves it into the database.
"""
import datetime
import threading
import time

from project import db
from project.api.common import plausible_random
from project.models.co2history import Co2History
from project.models.places import Place


def generate(rnd_iter):
    # Get all the places
    places = Place.query.all()
    for place in places:
        # Generate a random number of CO2
        co2 = next(rnd_iter)
        # Get current time as a timestamp without timezone
        timestamp = datetime.datetime.now().replace(tzinfo=None)
        # Save it into the database
        db.session.add(Co2History(place_id=place.id, timestamp=timestamp, co2=co2))
        db.session.commit()


def run(app):
    print("Starting the CO2 generator")
    rnd_gen = plausible_random(0, 400, 2000)
    while True:
        # Wait 30 minutes
        time.sleep(1800)
        # Generate the CO2 values
        print("Generating CO2 values")
        with app.app_context():
            generate(rnd_gen)


# Start the thread and make it possible to fork it to the background
def start(app):
    return threading.Thread(target=run, args=(app,)).start()
