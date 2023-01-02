from flask.views import MethodView
from flask_smorest import Blueprint, abort
from werkzeug.security import check_password_hash

from project.models import Utente
from marshmallow import Schema

auth = Blueprint('auth', __name__)


class LoginSchema(Schema):
    fields = ('email', 'password')


@auth.route('/login', methods=['POST'])
class Login(MethodView):
    @auth.arguments(LoginSchema, location='json')
    @auth.response(200, None)
    def post(self, args):
        """Login"""
        user = Utente.query.filter_by(email=args['email']).first()
        if not user or not check_password_hash(user.password, args['password']):
            abort(401, message='Invalid email or password')
        return "ao"


"""
@auth.route('/login', methods=['POST'])
@use_kwargs({'email': fields.Str(required=True), 'password': fields.Str(required=True)})
@marshal_with(schema=LoginSchema, code=200, description='all good here')
@auth.arguments({'email': fields.Str(required=True), 'password': fields.Str(required=True)})
def login_post(**kwargs):
    # login code goes here
    email = request.form.get('email')
    password = request.form.get('password')
    remember = True if request.form.get('remember') else False

    user = Utente.query.filter_by(email=email).first()

    # check if the user actually exists
    # take the user-supplied password, hash it, and compare it to the hashed password in the database
    if not user or not check_password_hash(user.password, password):
        # Return 403
        return 'Forbidden', 403
    else:
        # Return 200
        return 'OK', 200
*/
"""
# docs.register(login_post, blueprint='auth')
