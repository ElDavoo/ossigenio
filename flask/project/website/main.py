from flask import Blueprint, render_template, request, flash
from flask_login import login_required, current_user
from project import db
from project.models.user import Utente
from project.models.device import Device
# noinspection PyUnresolvedReferences
import project.utils.mqtt_bridge

main = Blueprint('main', __name__)


@main.route('/')
def index():
    return render_template('index.html')


@main.route('/profile')
@login_required
def profile():
    return render_template('profile.html', name=current_user.name, serialnum=current_user.serialnum)
    # if current_user.admin != True: #if user is admin, go to admin page instead to profile page
    #    return render_template('profile.html', name=current_user.name)
    # else:
    #    users = User.query
    #    return render_template('profile_admin.html', name=current_user.name, users=users)


@main.route('/administrator')
@login_required
def profile_admin():
    users = Utente.query
    device = Device.query
    if current_user.admin == True:  # restrict access to admin page only to admins
        return render_template('profile_admin.html', name=current_user.name, users=users, devices=device)
    else:
        return render_template('profile.html', name=current_user.name)


@main.route('/delete', methods=['GET'])
@login_required
def delete():
    if current_user.admin == True:  # restrict access to admin page only to admins
        id = request.args.get('id', type=int)
        try:
            # User.query.filter_by(id=id).delete()
            user = Utente.query.get(id)
            if user.admin != True:
                db.session.delete(user)
                db.session.commit()
            else:
                flash('This user is an administrator; please degrade to standard before delete it!')
        except Exception as e:
            print(e)
        users = Utente.query
        return render_template('profile_admin.html', name=current_user.name, users=users)
    else:
        return render_template('profile.html', name=current_user.name)


@main.route('/toggle', methods=['GET'])
@login_required
def toggle():
    if current_user.admin == True:  # restrict access to admin page only to admins
        id = request.args.get('id', type=int)
        user = Utente.query.filter_by(id=id).first()
        admin = user.admin
        db.session.query(Utente).filter(Utente.id == id).update({'admin': not admin})
        db.session.commit()
        users = Utente.query
        return render_template('profile_admin.html', name=current_user.name, users=users)
    else:
        return render_template('profile.html', name=current_user.name)


@main.route('/devices')
@login_required
def devices():
    devices = Device.query
    if current_user.admin == True:  # restrict access to admin page only to admins
        return render_template('devices.html', name=current_user.name, devices=devices)
    else:
        return render_template('profile.html', name=current_user.name)


@main.route('/devices_delete', methods=['GET'])
@login_required
def devices_delete():
    if current_user.admin:  # restrict access to admin page only to admins
        id = request.args.get('id', type=int)
        try:
            # User.query.filter_by(id=id).delete()
            device = Device.query.get(id)
            user = Utente.query.filter_by(serialnum=id).first()
            if user:
                flash('This device is currently used. Cannot remove it!')
                # return redirect(url_for('auth.login'))
            else:
                db.session.delete(device)
                db.session.commit()
        except Exception as e:
            print(e)
        devices = Device.query
        return render_template('devices.html', name=current_user.name, devices=devices)
    else:
        return render_template('profile.html', name=current_user.name)


@main.route('/add_devices', methods=['POST'])
@login_required
def add_devices():
    if current_user.admin == True:  # restrict access to admin page only to admins
        serialNum = request.form.get('serialNum')
        devices = Device.query
        if serialNum:
            device = Device.query.filter_by(id=serialNum).first()
            if device:
                flash('The Serial number already exists.')
                return render_template('devices.html', name=current_user.name, devices=devices)
            else:
                new_device = Device(id=serialNum)
                db.session.add(new_device)
                db.session.commit()
                return render_template('devices.html', name=current_user.name, devices=devices)
        else:
            flash('Please insert a valid serial number.')
            return render_template('devices.html', name=current_user.name, devices=devices)
    else:
        return render_template('profile.html', name=current_user.name)
