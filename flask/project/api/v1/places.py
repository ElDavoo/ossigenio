from flask import jsonify
from flask.views import MethodView
from flask_smorest import Blueprint
from flask_login import login_required, current_user
from marshmallow import Schema, fields
from project import db

places = Blueprint('places', __name__)


class LatLonSchema(Schema):
    class Meta:
        strict = True
        ordered = True

    lat = fields.Float(required=True)
    lon = fields.Float(required=True)


from project.models.places import Place


@places.route('/nearby', methods=['GET'])

class Nearby(MethodView):
    @places.arguments(LatLonSchema)
    @login_required
    def get(self, args):
        # Get the places closer than 1km
        places = Place.query.filter(Place.location.ST_DistanceSphere(f"POINT({args['lon']} {args['lat']})") < 1000).all()
        places_list = []
        for place in places:
            places_list.append(place.serialize())
        return str(places_list)
    # TODO optimize query
