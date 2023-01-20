import datetime

from flask import jsonify
from flask.views import MethodView
from flask_login import login_required
from flask_smorest import Blueprint

from project.api.common import plausible_random, predict
from project.models.co2history import Co2History
from project.models.places import Place

predictions = Blueprint('predictions', __name__)


@predictions.route('/predictions/<int:place_id>', methods=['GET'])
class Predictions(MethodView):
    @login_required
    def get(self, place_id):
        # Check if place exists
        place = Place.query.filter_by(id=place_id).first()
        if place is None:
            return "Place not found", 404
        # Get the last co2 value of this place from the co2_history table
        last_co2 = Co2History.query.filter_by(place_id=place.id).order_by(Co2History.timestamp.desc()).first()
        # get the predictions for this place from prophet
        predicts = predict(place.id)
        if predicts is not None:
            return jsonify(predicts)
        # If there are no predictions, returns a random value
        if predicts is None:
            # Get the predictions
            predictions_iter = plausible_random(last_co2.co2, 400, 2000)
            predicts = []
            timenow = datetime.datetime.now()
            for i in range(24):
                # Add a timestamp to the prediction
                tstamp = timenow + datetime.timedelta(hours=i)
                # Set it as ISO format
                tstamp = tstamp.isoformat()
                predicts.append({
                    'timestamp': tstamp,
                    'co2': next(predictions_iter)
                })
            return jsonify(predicts)
