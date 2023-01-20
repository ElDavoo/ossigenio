from project import db


class Co2History(db.Model):
    place_id = db.Column(db.Integer, db.ForeignKey('place.id'), primary_key=True, nullable=False)
    timestamp = db.Column(db.DateTime, primary_key=True, nullable=False)
    co2 = db.Column(db.Integer, nullable=False)
