from flask_smorest import Blueprint
from project.api.v1 import api as api_v1

# Creiamo e registriamo un blueprint contenente tutti i blueprint di tutte le versioni delle API
# Questo blueprint verrà poi inglobato nel blueprint globale dell'applicazione
api = Blueprint('api', __name__)
api.register_blueprint(api_v1, url_prefix="/v1")

# Versione predefinita delle API che verrà usata quando si usa l'URL /api
#api.register_blueprint(api_v1, name="api_latest", url_prefix="/")
