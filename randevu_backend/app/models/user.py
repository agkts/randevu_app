import enum
from ..extensions import db, bcrypt
from .base import BaseModel

class UserRole(enum.Enum):
    SUPER_ADMIN = 'super_admin'
    SALON_OWNER = 'salon_owner'
    HAIRDRESSER = 'hairdresser'
    CUSTOMER = 'customer'

class User(db.Model, BaseModel):
    """User model for authentication and authorization."""
    
    __tablename__ = 'users'
    
    username = db.Column(db.String(50), unique=True, nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    first_name = db.Column(db.String(50))
    last_name = db.Column(db.String(50))
    phone = db.Column(db.String(20))
    role = db.Column(db.Enum(UserRole), default=UserRole.CUSTOMER)
    is_active = db.Column(db.Boolean, default=True)
    tenant_id = db.Column(db.String(36), db.ForeignKey('tenants.id'), nullable=True)
    profile_image = db.Column(db.String(255), nullable=True)
    
    # For salon owners and hairdressers
    salon_id = db.Column(db.String(36), db.ForeignKey('tenants.id'), nullable=True)
    
    # Methods for password hashing
    def set_password(self, password):
        self.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')

    def check_password(self, password):
        return bcrypt.check_password_hash(self.password_hash, password)
    
    def to_dict(self):
        """Convert model to dictionary excluding sensitive data."""
        data = super().to_dict()
        data.pop('password_hash', None)
        
        # Convert enum to string
        if self.role:
            data['role'] = self.role.value
            
        return data