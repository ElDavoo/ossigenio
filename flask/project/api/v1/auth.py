from flask import jsonify
from flask.views import MethodView
from flask_login import login_user, login_required, current_user
from flask_smorest import Blueprint, abort
from marshmallow import Schema, fields
from werkzeug.security import check_password_hash, generate_password_hash

from project import db
from project.models.user import Utente, UserResponseSchema, LoginSchema, SignupSchema

auth = Blueprint('auth', __name__)


class ResponseSchema(Schema):
    """
    Schema di risposta per il login
    """

    class Meta:
        strict = True
        ordered = True

    code = fields.Integer(required=True)
    status = fields.String(required=True)


ResponseDict = {'description': 'Risposta per segnalare la non autenticazione dell\'utente',
                'schema': ResponseSchema,
                'content_type': 'application/json',
                'example': {
                    'code': 401,
                    'status': 'Unauthorized'
                }
                }


@auth.route('/login', methods=['POST'])
class Login(MethodView):
    @auth.arguments(LoginSchema)
    @auth.response(200, None, headers={
        'Set-Cookie': {
            'description': 'Il cookie di sessione',
            'type': 'string',
        }
    })
    @auth.alt_response(401, ResponseDict)
    def post(self, args):
        """Esegue il login dell'utente

        Importante: La password dell'utente deve essere hashata 1001
        volte con l'algoritmo sha256 prima di essere inviata al server.
        ---

        """
        user = Utente.query.filter_by(email=args['email']).first()
        if not user:
            abort(401)
        if not check_password_hash(user.password, args['password']):
            abort(401)
        if login_user(user, remember=args['remember']):
            return None
        abort(401)


@auth.route('/signup', methods=['POST'])
class Signup(MethodView):
    @auth.arguments(SignupSchema)
    @auth.response(200, headers={
        'Set-Cookie': {
            'description': 'Il cookie di sessione',
            'type': 'string',
        }
    })
    @auth.alt_response(401, ResponseDict)
    def post(self, args):
        """Esegue la registrazione dell'utente

        Importante: La password dell'utente deve essere hashata 1001
        volte con l'algoritmo sha256 prima di essere inviata al server.
        ---

        """
        user = Utente.query.filter_by(email=args['email']).first()
        if user:
            abort(401)
        # TODO email confirmation
        # TODO controllare che la password sia sicura
        new_user = Utente(email=args['email'], name=args['name'],
                          password=generate_password_hash(args['password'], method='sha256'),
                          admin=False)

        db.session.add(new_user)
        db.session.commit()
        if login_user(new_user):
            return 200
        abort(401)


@auth.route('/profile', methods=['GET'])
class User(MethodView):
    @auth.response(200, UserResponseSchema)
    @auth.alt_response(401, ResponseDict)
    @login_required
    @auth.doc(security=[{'Cookie': []}])
    def get(self):
        """Restituisce i dati dell'utente collegato

        Restituisce i dettagli dell'utente collegato.
        ---
        Usare per controllare se il cookie è valido
        e se c'è connessione
        """
        user = Utente.query.filter_by(email=current_user.email).first().serialize_partial()
        if not user:
            abort(401)
        return jsonify(user)
