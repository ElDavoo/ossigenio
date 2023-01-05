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


def generate():
    # Get all the places
    places = Place.query.all()
    for place in places:
        # Generate a random number of CO2
        co2 = next(plausible_random(400, 2000))
        # Save it into the database
        db.session.add(co2_history(place_id=place.id, co2=co2))
        db.session.commit()


def run():
    print("Starting the CO2 generator")
    while True:
        # Wait 30 minutes
        time.sleep(1800)
        # Generate the CO2 values
        print("Generating CO2 values")
        generate()


# Start the thread and make it possible to fork it to the background
def start():
    return threading.Thread(target=run).start()
