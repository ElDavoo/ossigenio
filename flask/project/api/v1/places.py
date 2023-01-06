from flask import jsonify
from flask.views import MethodView
from flask_smorest import Blueprint
from flask_login import login_required, current_user
from marshmallow import Schema, fields

places = Blueprint('places', __name__)


class LatLonSchema(Schema):
    class Meta:
        strict = True
        ordered = True

    lat = fields.Float(required=True)
    lon = fields.Float(required=True)


from project.models.places import Place, PlaceSchema
from project.models.co2history import co2_history


# Route to get the closest N places to a given location
@places.route('/places', methods=['POST'])
class Placs(MethodView):
    @places.arguments(LatLonSchema)
    def post(self, args):
        # Get the closest places
        placs = Place.query.order_by(Place.location.ST_DistanceSphere(f"POINT({args['lat']} {args['lon']})")).limit(
            1000)
        places = []
        for plc in placs:
            plc_json = PlaceSchema().dump(plc)
            last_co2 = co2_history.query.filter_by(place_id=plc.id).order_by(co2_history.timestamp.desc()).first()
            if last_co2 is not None:
                plc_json['co2'] = last_co2.co2
            else:
                plc_json['co2'] = None
            places.append(plc_json)
        return jsonify(places)


@places.route('/nearby', methods=['POST'])
class Nearby(MethodView):
    @places.arguments(LatLonSchema)
    @login_required
    @places.response(200, PlaceSchema(many=True))
    def post(self, args):
        # Get the places closer than 1km
        places = Place.query.filter(Place.location.ST_DistanceSphere(f"POINT({args['lat']} {args['lon']})") < 100)\
            .order_by(Place.location.ST_DistanceSphere(f"POINT({args['lat']} {args['lon']})")).limit(10).all()
        places_list = []
        for place in places:
            lst = place.serialize()
            last_co2 = co2_history.query.filter_by(place_id=place.id).order_by(co2_history.timestamp.desc()).first()
            if last_co2 is not None:
                lst['co2'] = last_co2.co2
            else:
                lst['co2'] = None
            places_list.append(lst)
        return jsonify(places_list)
    # TODO optimize query


@places.route('/place/<int:place_id>', methods=['GET'])
class Plc(MethodView):
    @login_required
    @places.response(200, PlaceSchema)
    def get(self, place_id):
        place = Place.query.filter_by(id=place_id).first()
        if place is None:
            return "Place not found", 404
        # add the last co2 value from the co2_history table
        lst = place.serialize()
        last_co2 = co2_history.query.filter_by(place_id=place.id).order_by(co2_history.timestamp.desc()).first()
        if last_co2 is not None:
            lst['co2'] = last_co2.co2
        else:
            lst['co2'] = None
        return jsonify(lst)
