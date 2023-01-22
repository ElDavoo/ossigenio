from flask import jsonify
from flask.views import MethodView
from flask_login import current_user
from flask_smorest import Blueprint
from marshmallow import Schema, fields

from project import db
from project.api.common import login_required_cookie, StatusSchema
from project.models.device import Device as DeviceModel

device = Blueprint('device', __name__)


class IdSchema(Schema):
    class Meta:
        strict = True
        ordered = True

    id = fields.Integer(required=True)


@device.route('/associate', methods=['POST'])
class Device(MethodView):
    @device.arguments(IdSchema)
    @login_required_cookie(device)
    @device.response(200, content_type='application/json', schema=StatusSchema,
                     description='Risposta per segnalare che si è (già) proprietari del dispositivo. Può anche '
                                 'ritornare "Device is already yours"',
                     example={'status': 'Device is associated'})
    @device.alt_response(404, {
        'content_type': 'application/json',
        'schema': StatusSchema,
        'description': 'Risposta per segnalare che il dispositivo non esiste',
        'example': {
            'status': 'Device not found'
        }
    })
    @device.alt_response(409, {
        'content_type': 'application/json',
        'schema': StatusSchema,
        'description': 'Risposta per segnalare che il dispositivo è già associato ad un altro utente',
        'example': {
            'status': 'Device already associated'
        }
    })
    def post(self, args):
        """
        Associa un dispositivo a un utente.

        Usare questo endpoint per associare un sensore Ossigenio
        a un utente. In questo modo, si attesta che il dispositivo
        a cui ci si connette è originale ed è di proprietà dell'utente.

        ---
        API non ancora attiva/enforced.
        """
        dvc = DeviceModel.query.filter_by(id=args['id']).first()
        # TODO rate limit
        if dvc is None:
            return jsonify(status='Device not found'), 404
        if dvc.owner == current_user.id:
            return jsonify(status='Device is already yours'), 200
        if dvc.owner is not None:
            return jsonify(status='Device already associated'), 409
        dvc.owner = current_user.id
        db.session.commit()
        # TODO better security: require a token cryptographically signed by the device
        return jsonify("Device associated"), 200
