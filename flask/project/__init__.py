# In Wsl execute before launch:
# export FLASK_APP=project
# export FLASK_DEBUG=1
# and launch with:
# flask run

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
import psycopg2
import os
from api import common

# init SQLAlchemy so we can use it later in our models
db = SQLAlchemy()

def create_app():
    app = Flask(__name__)

    #app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////home/antonio/flask_auth_app/flask.db'
    app.config['SQLALCHEMY_DATABASE_URI'] = os.environ['SQLALCHEMY_DATABASE_URI']

    db.init_app(app)

    login_manager = LoginManager()
    login_manager.login_view = 'auth.login'
    login_manager.init_app(app)

    from models import Utente

    @login_manager.user_loader
    def load_user(user_id):
        # since the user_id is just the primary key of our user table, use it in the query for the user
        return Utente.query.get(int(user_id))

    # blueprint for auth routes in our app
    from .auth import auth as auth_blueprint
    app.register_blueprint(auth_blueprint)

    # blueprint for non-auth parts of app
    from .main import main as main_blueprint
    app.register_blueprint(main_blueprint)

    from api.v1 import api as api_v1
    app.register_blueprint(api_v1, name='api_v1', url_prefix="/api/v1")
    app.register_blueprint(api_v1, name='api_latest', url_prefix="/api")

    return app
