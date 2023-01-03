from flask_login import UserMixin
from marshmallow import Schema, fields

from project import db


class UserResponseSchema(Schema):
    class Meta:
        strict = True
        ordered = True

    email = fields.String(required=True)
    name = fields.String(required=True)
    is_admin = fields.Boolean(required=True)


class Utente(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)  # primary keys are required by SQLAlchemy
    email = db.Column(db.String(100), unique=True)
    password = db.Column(db.String(100))
    name = db.Column(db.String(1000))
    admin = db.Column(db.Boolean)

    def serialize_partial(self):
        return {
            'email': self.email,
            'name': self.name,
            'is_admin': self.admin,
        }

