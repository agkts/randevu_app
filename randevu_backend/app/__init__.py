import os
from flask import Flask, g, request
from .extensions import db, migrate, jwt, cors, bcrypt
from .config import get_config

def create_app(config_override=None):
    """Create and configure the Flask application."""
    app = Flask(__name__)
    
    # Load configuration
    app.config.from_object(get_config())
    
    
    # Override config if provided
    if config_override:
        app.config.update(config_override)
    
    # Initialize extensions with app
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    cors.init_app(app)
    bcrypt.init_app(app)
    
    # Ensure upload folder exists
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    
    # Import and register blueprints
    from .api import api_bp
    app.register_blueprint(api_bp, url_prefix='/api')
    
    # Tenant middleware
    @app.before_request
    def get_tenant():
        """Extract tenant info from path or subdomain."""
        tenant_slug = None
        path_parts = request.path.split('/')
        
        # Check if using path-based routing (e.g., randevu.app/salon-name/...)
        if len(path_parts) > 1 and path_parts[1] != 'api' and path_parts[1]:
            tenant_slug = path_parts[1]
            
        # You could also check for subdomain logic here if needed
        # e.g., salon-name.randevu.app
        
        if tenant_slug:
            # Import here to avoid circular imports
            from .models.tenant import Tenant
            # Load tenant into request context
            tenant = Tenant.query.filter_by(slug=tenant_slug, is_active=True).first()
            g.tenant = tenant
        else:
            g.tenant = None
    
    # Health check endpoint
    @app.route('/health')
    def health():
        return {'status': 'ok'}, 200
    
    return app