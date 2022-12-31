from flask import Blueprint
from .auth import auth

api = Blueprint('api', __name__)
api.register_blueprint(auth)