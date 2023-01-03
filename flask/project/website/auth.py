from flask import Blueprint, render_template, redirect, url_for, request, flash
from werkzeug.security import generate_password_hash, check_password_hash
from project.models.user import Utente
from project import db
from flask_login import login_user, login_required, logout_user

auth = Blueprint('auth', __name__)


@auth.route('/login')
def login():
    return render_template('login.html')


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
        flash('Please check your login details and try again.')
        return redirect(url_for('auth.login'))  # if the user doesn't exist or password is wrong, reload the page

    # if user.admin == True:
    # admin stuff
    # return render_template('login.html')
    # login_user(user, remember=remember)
    # return redirect(url_for('main.profile_admin'))

    # if the above check passes, then we know the user has the right credentials
    login_user(user, remember=remember)
    return redirect(url_for('main.profile'))


@auth.route('/signup')
def signup():
    return render_template('signup.html')


@auth.route('/signup', methods=['POST'])
def signup_post():
    email = request.form.get('email')
    name = request.form.get('name')
    password = request.form.get('password')
    serialNum = request.form.get('serialNum')

    user = Utente.query.filter_by(email=email).first()  # if this returns a user, then the email already exists in database

    if serialNum:
        serial_usage_check = Device.query.filter_by(id=serialNum).first()  # check if serial is already used
    else:
        flash('Please check data inserted')
        return redirect(url_for('auth.signup'))

    if user:  # if a user is found, we want to redirect back to signup page so user can try again
        flash('Email address already exists')
        return redirect(url_for('auth.signup'))

    if serial_usage_check.owner:
        flash('This serial number is already used')
        return redirect(url_for('auth.signup'))
    serial_exists = Device.query.filter_by(id=serialNum).first() # check if serial exists

    if serial_exists:
        new_user = Utente(email=email, name=name, password=generate_password_hash(password, method='sha256'),
                          admin=False)

        # add the new user to the database
        # db.session.execute('PRAGMA foreign_keys = ON;')
        db.session.add(new_user)
        db.session.commit()
        # return render_template('signup.html')
        return redirect(url_for('auth.login'))
    else:
        flash('This serial number doesn\'t exist')
        return redirect(url_for('auth.signup'))


@auth.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('main.index'))
