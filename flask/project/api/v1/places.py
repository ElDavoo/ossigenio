from flask import jsonify
from flask.views import MethodView
from flask_smorest import Blueprint
from marshmallow import Schema, fields

from project.api.common import login_required_cookie, StatusSchema
from project.models.co2history import Co2History
from project.models.places import Place, PlaceSchema

places = Blueprint('places', __name__)


class LatLonSchema(Schema):
    """
    Schema che denota una coordinata geografica
    """

    class Meta:
        strict = True
        ordered = True

    lat = fields.Float(required=True)
    lon = fields.Float(required=True)


@places.route('/places', methods=['POST'])
class Placs(MethodView):
    @places.arguments(LatLonSchema, description='Coordinate geografiche')
    @login_required_cookie(places)
    @places.response(200, PlaceSchema(many=True), description='Lista di luoghi vicini alle coordinate date')
    def post(self, args):
        """ Ottiene i luoghi più vicini alla posizione indicata

        Questo endpoint restituisce i 1000 luoghi più vicini alla posizione indicata.
        ---
        Viene utilizzato per popolare la mappa nell'app mobile.
        """
        limit = 1000
        placs = Place.query.order_by(Place.location.ST_DistanceSphere(f"POINT({args['lat']} {args['lon']})")).limit(
            limit).all()
        places_list = []
        for plc in placs:
            plc_json = plc.serialize()
            # Ottiene la co2 dalla tabella dedicata
            last_co2 = Co2History.query.filter_by(place_id=plc.id).order_by(Co2History.timestamp.desc()).first()
            if last_co2 is not None:
                plc_json['co2'] = last_co2.co2
            else:
                plc_json['co2'] = None
            places_list.append(plc_json)
        return jsonify(places_list)


def add_co2(plc):
    """
    Aggiunge la co2 a un luogo, o con None se non è disponibile
    :param plc: Il luogo a cui aggiungere la co2
    :return: Il luogo con la co2 aggiunta
    """
    place = plc.serialize()
    last_co2 = Co2History.query.filter_by(place_id=plc.id).order_by(Co2History.timestamp.desc()).first()
    if last_co2 is not None:
        place['co2'] = last_co2.co2
    else:
        place['co2'] = None
    return place


@places.route('/nearby', methods=['POST'])
class Nearby(MethodView):
    @places.arguments(LatLonSchema, description='Coordinate geografiche')
    @login_required_cookie(places)
    @places.response(200, PlaceSchema(many=True), description='Lista di luoghi vicini alle coordinate date')
    def post(self, args):
        """ Ottiene i luoghi entro un certo raggio dalla posizione indicata

        Questo endpoint restituisce i 10 luoghi più vicini alla posizione indicata,
        entro un raggio di 200 metri.
        ---
        Viene utilizzato per popolare la lista dei luoghi nelle vicinanze nell'app mobile.
        """
        range_radius = 200
        query_limit = 10
        close_places = Place.query \
            .filter(Place.location.ST_DistanceSphere(f"POINT({args['lat']} {args['lon']})") < range_radius) \
            .order_by(Place.location.ST_DistanceSphere(f"POINT({args['lat']} {args['lon']})")).limit(query_limit).all()
        places_list = []
        for plc in close_places:
            place_co2 = add_co2(plc)
            places_list.append(place_co2)
        return jsonify(places_list)


@places.route('/place/<int:place_id>', methods=['GET'])
class Plc(MethodView):
    @login_required_cookie(places)
    @places.response(200, PlaceSchema, description='Luogo cercato')
    @places.response(404, StatusSchema, description='Messaggio di errore')
    def get(self, place_id):
        """ Ottiene i dati di un luogo

        Questo endpoint restituisce i dati di un luogo.
        ---
        """
        place = Place.query.filter_by(id=place_id).first()
        if place is None:
            return jsonify(status="Place not found"), 404
        # Cerca la CO2 più recente
        place = add_co2(place)
        return jsonify(place)
