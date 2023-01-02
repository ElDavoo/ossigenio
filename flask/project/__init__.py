# In Wsl execute before launch:
# export FLASK_APP=project
# export FLASK_DEBUG=1
# and launch with:
# flask run
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
import os
from flask_smorest import Api

from project.config import Config

# init SQLAlchemy so we can use it later in our models
db = SQLAlchemy()

flask_app = Flask(__name__)

flask_app.config['SECRET_KEY'] = os.environ['SECRET_KEY']
# app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////home/antonio/flask_auth_app/flask.db'
flask_app.config['SQLALCHEMY_DATABASE_URI'] = os.environ['SQLALCHEMY_DATABASE_URI']

flask_app.config.from_object(Config)

app = Api(flask_app)

db.init_app(flask_app)

login_manager = LoginManager()
login_manager.login_view = 'auth.login'
login_manager.init_app(flask_app)

from project.models.user import Utente


@login_manager.user_loader
def load_user(user_id):
    # since the user_id is just the primary key of our user table, use it in the query for the user
    return Utente.query.get(int(user_id))


# blueprint for auth routes in our app
from project.website.auth import auth as auth_blueprint

flask_app.register_blueprint(auth_blueprint)

# blueprint for non-auth parts of app
from .main import main as main_blueprint

flask_app.register_blueprint(main_blueprint)

# blueprint for api
from project.api import api as api_blueprint

app.register_blueprint(api_blueprint, url_prefix='/api')
