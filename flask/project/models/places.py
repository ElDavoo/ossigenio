from geoalchemy2 import Geometry
from geoalchemy2.shape import to_shape
from marshmallow import Schema, fields

from project import db


class PlaceSchema(Schema):
    id = fields.Integer(required=True)
    name = fields.String(required=True)
    lat = fields.Float(required=True)
    lon = fields.Float(required=True)
    description = fields.String(required=False)


class Place(db.Model):
    id = db.Column(db.Integer, primary_key=True)  # primary keys are required by SQLAlchemy
    # put postgis geometry
    location = db.Column(Geometry(geometry_type='POINT', srid=4326))
    name = db.Column(db.String(1000))
    description = db.Column(db.String(1000))
    co2 = db.Column(db.Float)

    # Serialize the data for the API
    def serialize(self):
        # Convert the location to a pair of coordinates
        location = to_shape(self.location)
        long = location.x
        lat = location.y
        return {
            'id': self.id,
            'lat': lat,
            'lon': long,
            'name': self.name,
            'description': self.description,
            'co2': self.co2
        }
