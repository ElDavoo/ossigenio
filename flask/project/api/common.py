"""
Here we define common utilities used in all the API versions
"""
import json
import os
import random

import pandas as pd
from prophet.serialize import model_from_json
from sqlalchemy import create_engine


def predict(place):
    """
    Predict 24 hours of values with prophet
    :param place: The place to predict
    :return: A json with the predicted values, or None if there is no model for the place
    """
    # Connect to postgresql database
    engine = create_engine(os.environ['SQLALCHEMY_DATABASE_URI'])

    # Read model from postgresql database
    model = pd.read_sql_query('SELECT model FROM "public"."prophet_models" WHERE place_id = ' + str(place), con=engine)

    # If there is no model for this place, return
    if len(model) == 0:
        return

    print("Loading model for place " + str(place))
    # FIXME
    m = model_from_json(json.dumps(model['model'][0]))

    # Create dataframe with future dates
    future = m.make_future_dataframe(periods=24, freq='H')
    # FIXME Cut the dataframe to make it faster
    future = future.tail(1000)

    print("Predicting for place " + str(place))
    # Predict future values
    forecast = m.predict(future)
    # cut to only forecasted values
    forecast = forecast.tail(24)
    print("Predicted for place " + str(place))
    # Return predicted values
    forecast['yhat'] = forecast['yhat'].astype(int)
    # If there are predictions, return them
    predicts = []
    for index, row in forecast.iterrows():
        predicts.append({
            'timestamp': row['ds'].isoformat(),
            'co2': row['yhat']
        })
    return predicts


def plausible_random(start_value, start, end):
    """
    A generator that chooses a random number and generates random numbers around it
    :param start_value: The starting value
    :param start: The start number
    :param end: The end number
    """
    # Choose a random number
    if start_value == 0:
        number = random.randint(start, end)
    else:
        number = start_value
    rng = (end - start) // 40
    while True:
        if (end - start) // 2 < number:
            # 51% of chance to generate a positive number
            if random.randint(0, 100) > 60:
                number += random.randint(0, rng)
            else:
                number -= random.randint(0, rng)
        else:
            # 51% of chance to generate a negative number
            if random.randint(0, 100) > 60:
                number -= random.randint(0, rng)
            else:
                number += random.randint(0, rng)

        # If the number is out of bounds, clamp it
        if number < start:
            number = start
        elif number > end:
            number = end
        yield number
