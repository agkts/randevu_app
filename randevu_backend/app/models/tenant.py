from ..extensions import db
from .base import BaseModel

class Tenant(db.Model, BaseModel):
    """Tenant model representing a salon in the multi-tenant architecture."""
    
    __tablename__ = 'tenants'
    
    # Basic info
    name = db.Column(db.String(100), nullable=False)
    slug = db.Column(db.String(100), unique=True, nullable=False)  # URL path: randevu.app/salon-name
    owner_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    email = db.Column(db.String(100), nullable=True)
    phone = db.Column(db.String(20), nullable=True)
    address = db.Column(db.String(255), nullable=True)
    website = db.Column(db.String(100), nullable=True)
    logo_url = db.Column(db.String(255), nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    
    # Subscription details
    subscription_plan = db.Column(db.String(20), default="standard")
    subscription_start_date = db.Column(db.DateTime, nullable=True)
    subscription_end_date = db.Column(db.DateTime, nullable=True)
    
    # Settings as JSON for salon customization
    settings = db.Column(db.JSON, default={})
    sms_settings = db.Column(db.JSON, default={})
    working_schedule = db.Column(db.JSON, default={})
    
    # Relationships
    owner = db.relationship('User', foreign_keys=[owner_id], backref='owned_salons')
    
    def to_dict(self):
        """Convert model to dictionary with additional fields."""
        data = super().to_dict()
        
        # Add owner details if available
        if hasattr(self, 'owner') and self.owner:
            data['owner_name'] = f"{self.owner.first_name} {self.owner.last_name}"
            data['owner_email'] = self.owner.email
            
        return data
        
    @staticmethod
    def create_default_settings():
        """Create default salon settings."""
        return {
            'allow_online_booking': True,
            'default_appointment_duration': 30, # minutes
            'minimum_notice_time': 60, # minutes
            'cancelation_time_limit': 24, # hours
            'send_sms_reminders': True,
            'reminder_time_before_appointment': 24, # hours
            'require_customer_email': True,
        }
        
    @staticmethod
    def create_default_sms_settings():
        """Create default SMS settings."""
        return {
            'is_active': False,
            'api_key': None,
            'sender_id': None,
            'appointment_confirmation_template': None,
            'appointment_reminder_template': None,
            'appointment_cancel_template': None,
        }
        
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