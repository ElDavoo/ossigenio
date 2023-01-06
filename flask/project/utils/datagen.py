"""
A file that, every 30 minutes, generates a random number of CO2 for every place
and saves it into the database.
"""
from project.models.places import Place
from project.models.co2history import co2_history
from project import db
from project.api.common import plausible_random
import time
import threading


def generate(rnd_iter):
    # Get all the places
    places = Place.query.all()
    for place in places:
        # Generate a random number of CO2
        co2 = next(rnd_iter)
        # Save it into the database
        db.session.add(co2_history(place_id=place.id, timestamp=time.time(), co2=co2))
        db.session.commit()


def run(app):
    print("Starting the CO2 generator")
    rnd_gen = plausible_random(400, 2000)
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
