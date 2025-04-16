from ..extensions import db
from .base import BaseModel

class Hairdresser(db.Model, BaseModel):
    """Hairdresser model for salon staff."""
    
    __tablename__ = 'hairdressers'
    
    # Personal information
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), nullable=True)
    phone = db.Column(db.String(20), nullable=True)
    profile_image = db.Column(db.String(255), nullable=True)
    
    # Work details
    working_schedule = db.Column(db.JSON, default={})  # Schedule for each day
    service_ids = db.Column(db.JSON, default=[])  # List of services this hairdresser provides
    is_active = db.Column(db.Boolean, default=True)
    holiday_dates = db.Column(db.JSON, default=[])  # List of dates for holidays/time off
    
    # Foreign keys
    salon_id = db.Column(db.String(36), db.ForeignKey('tenants.id'), nullable=False)
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=True)  # If hairdresser has login access
    
    # Relationships
    salon = db.relationship('Tenant', backref='hairdressers')
    user = db.relationship('User', backref='hairdresser_profile')
    
    def to_dict(self):
        """Convert model to dictionary."""
        data = super().to_dict()
        
        # Add associated user data if available
        if self.user:
            data['username'] = self.user.username
            
        return data
    
    @staticmethod
    def create_default_schedule():
        """Create default working schedule."""
        return {
            'monday': {'is_active': True, 'open_time': "09:00", 'close_time': "18:00"},
            'tuesday': {'is_active': True, 'open_time': "09:00", 'close_time': "18:00"},
            'wednesday': {'is_active': True, 'open_time': "09:00", 'close_time': "18:00"},
            'thursday': {'is_active': True, 'open_time': "09:00", 'close_time': "18:00"},
            'friday': {'is_active': True, 'open_time': "09:00", 'close_time': "18:00"},
            'saturday': {'is_active': True, 'open_time': "09:00", 'close_time': "16:00"},
            'sunday': {'is_active': False, 'open_time': "09:00", 'close_time': "18:00"},
        }