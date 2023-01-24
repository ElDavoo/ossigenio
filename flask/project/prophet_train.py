"""
Trains new Prophet model and saves them in the database.
Only run this in a powerful machine!
"""
import os

import pandas as pd
from prophet import Prophet
from prophet.serialize import model_to_json
from sqlalchemy import create_engine

engine = create_engine(os.environ['SQLALCHEMY_DATABASE_URI'])
places = pd.read_sql_query('SELECT id FROM place', con=engine)

for place in places['id']:

    # Read data from postgresql database
    df = pd.read_sql_query(
        'SELECT timestamp, co2 FROM "public"."sensor_data" WHERE place = ' + str(place) + ' ORDER BY timestamp',
        con=engine)

    if len(df) < 10:
        continue

    print("Processing place " + str(place) + " with " + str(len(df)) + " data points")

    # Rename columns
    df = df.rename(columns={'timestamp': 'ds', 'co2': 'y'})

    # Create model
    m = Prophet()

    # Fit model
    m.fit(df)

    # Save model to postgresql database
    model_json = model_to_json(m)

    # If there is already a model for this place, delete it
    engine.execute('DELETE FROM "public"."prophet_models" WHERE place_id = ' + str(place))

    # Save model to postgresql database
    engine.execute(
        'INSERT INTO "public"."prophet_models" (place_id, model) VALUES (' + str(place) + ', \'' + model_json + '\')')
