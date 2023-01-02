from flask.views import MethodView
from flask_smorest import Blueprint, abort
from werkzeug.security import check_password_hash, generate_password_hash
from flask_login import login_user, login_required, logout_user
from project.models.user import Utente
from marshmallow import Schema, fields
from project import db

auth = Blueprint('auth', __name__)


class LoginSchema(Schema):
    class Meta:
        strict = True
        ordered = True

    email = fields.String(required=True)
    password = fields.String(required=True)
    remember = fields.Boolean(required=False, load_default=False)


@auth.route('/login', methods=['POST'])
class Login(MethodView):
    @auth.arguments(LoginSchema)
    @auth.response(200, None, headers={
        'Set-Cookie': {
            'description': 'The session cookie',
            'type': 'string',
        }
    })
    @auth.alt_response(401, None)
    def post(self, args):
        """Esegue il login

        Descrizione dell'api
        ---
        Internal comment not meant to be exposed.
        """
        user = Utente.query.filter_by(email=args['email']).first()
        if not user or not check_password_hash(user.password, args['password']):
            abort(401, message='Invalid email or password')
        remember = args['remember'] if 'remember' in args else False
        if login_user(user, remember=args['remember']):
            return None
        else:
            abort(401, message='Invalid email or password')


class SignupSchema(Schema):
    class Meta:
        strict = True
        ordered = True

    email = fields.String(required=True)
    password = fields.String(required=True)
    name = fields.String(required=True)


@auth.route('/signup', methods=['POST'])
class Signup(MethodView):
    @auth.arguments(SignupSchema)
    @auth.response(200, None)
    @auth.alt_response(401, None)
    def post(self, args):
        """Esegue la registrazione

        Descrizione dell'api
        ---
        Internal comment not meant to be exposed.
        """
        user = Utente.query.filter_by(email=args['email']).first()
        if user:
            abort(401, message='Email already exists')
        # TODO password salting
        # TODO email confirmation

        new_user = Utente(email=args['email'], name=args['name'],
                          password=generate_password_hash(args['password'], method='sha256'),
                          admin=False)

        # add the new user to the database
        # db.session.execute('PRAGMA foreign_keys = ON;')
        db.session.add(new_user)
        db.session.commit()
        if login_user(user):
            return 200
        else:
            abort(401, message='Invalid email or password')
