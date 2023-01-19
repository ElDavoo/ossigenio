from project import db


class TelegramUser(db.Model):
    __tablename__ = 'telegram_users'
    telegram_id = db.Column(db.Integer, primary_key=True)
    id = db.Column(db.Integer, db.ForeignKey('utente.id'), primary_key=True)
    place = db.Column(db.Integer, db.ForeignKey('place.id'))
    soglia = db.Column(db.Integer, default=800)

    def __repr__(self):
        return f"TelegramUser('{self.telegram_id}', '{self.id}', '{self.place}', '{self.soglia}')"
