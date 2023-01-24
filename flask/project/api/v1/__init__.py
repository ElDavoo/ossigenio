from .users import *
from .device import *
from .places import *
from .predictions import *

# Creiamo un blueprint di nome "api", che verrà poi inglobato nel blueprint generico delle api
api = Blueprint('api_v1', __name__)

# Registriamo tutte le componenti delle API
api.register_blueprint(users)
places.register_blueprint(predictions)
api.register_blueprint(places)
api.register_blueprint(device)

