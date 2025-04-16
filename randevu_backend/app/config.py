import os
from datetime import timedelta

class Config:
    """Base configuration for the Randevu app."""
    
    # Database settings
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'postgresql://postgres:3388@localhost:5432/randevu_app')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # JWT settings
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'super-secret-key-change-in-production')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=1)
    
    # App settings
    SECRET_KEY = os.environ.get('SECRET_KEY', 'randevu-app-secret-key-change-in-production')
    DEBUG = os.environ.get('DEBUG', 'True') == 'True'
    
    # File upload settings
    UPLOAD_FOLDER = os.path.join(os.getcwd(), 'uploads')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max upload size

class DevelopmentConfig(Config):
    """Development configuration."""
    DEBUG = True
    
class ProductionConfig(Config):
    """Production configuration."""
    DEBUG = False
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)
    
class TestingConfig(Config):
    """Testing configuration."""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'postgresql://postgres:password@localhost:5432/randevu_test'

# Configuration dictionary for easy access
config_dict = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}

def get_config():
    """Returns the appropriate configuration based on environment."""
    config_name = os.environ.get('FLASK_ENV', 'default')
    return config_dict.get(config_name, config_dict['default'])