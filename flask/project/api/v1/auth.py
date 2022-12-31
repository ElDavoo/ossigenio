from flask import Blueprint, request, flash, redirect, url_for
from werkzeug.security import check_password_hash

from project.models import Utente

auth = Blueprint('auth', __name__)

@auth.route('/login', methods=['POST'])
def login_post():
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