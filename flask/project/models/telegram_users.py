from project import db


class TelegramUsers(db.Model):
    telegram_id = db.Column(db.Integer, primary_key=True)
    id = db.Column(db.Integer, db.ForeignKey('utente.id'), primary_key=True)
    place = db.Column(db.Integer, db.ForeignKey('place.id'))
    soglia = db.Column(db.Integer, default=800)
