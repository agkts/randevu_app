from flask import Blueprint

api_bp = Blueprint('api', __name__)

# Import routes to register with blueprint
from . import auth, users, tenants, hairdressers, services, appointments