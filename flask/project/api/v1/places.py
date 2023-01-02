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


@places.route('/nearby', methods=['GET'])

class Nearby(MethodView):
    @places.arguments(LatLonSchema)
    @login_required
    @places.response(200, PlaceSchema(many=True))
    def get(self, args):
        # Get the places closer than 1km
        places = Place.query.filter(Place.location.ST_DistanceSphere(f"POINT({args['lon']} {args['lat']})") < 1000).all()
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
