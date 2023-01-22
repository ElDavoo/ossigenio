from project import db


class Device(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    model = db.Column(db.SmallInteger, nullable=False)
    revision = db.Column(db.SmallInteger, nullable=False)
    owner = db.Column(db.Integer, db.ForeignKey('utente.id'), nullable=False)
