import datetime

from flask import jsonify
from flask.views import MethodView
from flask_login import login_required
from flask_smorest import Blueprint

from project.api.common import plausible_random
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
        # Get the predictions
        predictions_iter = plausible_random(400, 2000)
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
