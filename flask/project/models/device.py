from project import db


# table model for db
class Device(db.Model):
    id = db.Column(db.Integer, primary_key=True)  # primary keys are required by SQLAlchemy
    # model is a smallint
    model = db.Column(db.SmallInteger, nullable=False)
    # revision is a smallint
    revision = db.Column(db.SmallInteger, nullable=False)
    # owner is a foreign key
    owner = db.Column(db.Integer, db.ForeignKey('utente.id'), nullable=False)
