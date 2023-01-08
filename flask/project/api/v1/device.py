from flask.views import MethodView
from flask_login import login_required, current_user
from flask_smorest import Blueprint
from marshmallow import Schema, fields

from project.models.device import Device as DeviceModel
from project import db

device = Blueprint('device', __name__)


class IdSchema(Schema):
    class Meta:
        strict = True
        ordered = True

    id = fields.Integer(required=True)


@device.route('/associate', methods=['POST'])
class Device(MethodView):
    @device.arguments(IdSchema)
    @login_required
    def post(self, args):
        # Check if the device is already associated
        # If not, associate it to the current user
        device = DeviceModel.query.filter_by(id=args['id']).first()
        # TODO rate limit
        if device is None:
            return "Device not found", 404
        if device.owner == current_user.id:
            return "Device is already yours", 200
        if device.owner is not None:
            return "Device already associated", 409
        device.owner = current_user.id
        db.session.commit()
        # TODO better security.
        # require a token cryptographically signed by the device
        return "Device associated", 200
