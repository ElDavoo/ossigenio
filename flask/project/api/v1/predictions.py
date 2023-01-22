import datetime

from flask import jsonify
from flask.views import MethodView
from flask_smorest import Blueprint
from marshmallow import Schema, fields

from project.api.common import plausible_random, predict, login_required_cookie, StatusSchema
from project.models.co2history import Co2History
from project.models.places import Place

predictions = Blueprint('predictions', __name__)


class PredictionSchema(Schema):
    """ Schema che denota una lista di previsioni
    Una previsione è una coppia timestamp - co2"""

    class Meta:
        strict = True
        ordered = True

    timestamp = fields.DateTime(required=True)
    co2 = fields.Float(required=True)


@predictions.route('/<int:place_id>/predictions', methods=['GET'])
class Predictions(MethodView):
    @login_required_cookie(predictions)
    @predictions.response(200, PredictionSchema(many=True), description='Lista di previsioni')
    @predictions.alt_response(404, schema=StatusSchema, description='Luogo non trovato')
    def get(self, place_id):
        """ Ottiene le previsioni per un luogo

        Questo endpoint restituisce le previsioni per un luogo.
        Ogni previsione è in un'ora nel futuro (dal momento della richiesta), per un totale di 24 previsioni.
        ---
        Viene fatto il fallback su un modello casuale se non è disponibile un modello per il luogo.
        """
        # Controlla se il posto esiste
        place = Place.query.filter_by(id=place_id).first()
        if place is None:
            return jsonify(status="Place not found"), 404
        # Invoca il profeta
        predicts = predict(place.id)
        if predicts is not None:
            return jsonify(predicts)
        # Ottiene la co2 dalla tabella dedicata
        last_co2 = Co2History.query.filter_by(place_id=place.id).order_by(Co2History.timestamp.desc()).first()
        # Ottiene le predizioni
        predictions_iter = plausible_random(last_co2.co2, 400, 2000)
        predicts = []
        time_now = datetime.datetime.now()
        # Aggiunge l'informazione oraria alla previsione
        for i in range(24):
            tstamp = time_now + datetime.timedelta(hours=i)
            tstamp = tstamp.isoformat()
            predicts.append({
                'timestamp': tstamp,
                'co2': next(predictions_iter)
            })
        return jsonify(predicts)
