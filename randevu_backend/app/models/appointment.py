import enum
import string
import random
from datetime import datetime
from ..extensions import db
from .base import BaseModel

class AppointmentStatus(enum.Enum):
    PENDING = 'pending'
    CONFIRMED = 'confirmed'
    COMPLETED = 'completed'
    CANCELED = 'canceled'
    NO_SHOW = 'no_show'

class Appointment(db.Model, BaseModel):
    """Appointment model for salon bookings."""
    
    __tablename__ = 'appointments'
    
    # Customer information
    customer_name = db.Column(db.String(100), nullable=False)
    customer_phone = db.Column(db.String(20), nullable=False)
    customer_email = db.Column(db.String(100), nullable=True)
    
    # Appointment details
    appointment_date = db.Column(db.Date, nullable=False)
    start_time = db.Column(db.Time, nullable=False)
    end_time = db.Column(db.Time, nullable=False)
    status = db.Column(db.Enum(AppointmentStatus), default=AppointmentStatus.PENDING)
    
    # Access code for public checking (e.g., ABCD1234)
    access_code = db.Column(db.String(8), unique=True, nullable=False)
    
    # Optional note
    notes = db.Column(db.String(500), nullable=True)
    
    # SMS notification status
    confirmation_sent = db.Column(db.Boolean, default=False)
    reminder_sent = db.Column(db.Boolean, default=False)
    
    # Foreign keys
    salon_id = db.Column(db.String(36), db.ForeignKey('tenants.id'), nullable=False)
    hairdresser_id = db.Column(db.String(36), db.ForeignKey('hairdressers.id'), nullable=False)
    service_id = db.Column(db.String(36), db.ForeignKey('services.id'), nullable=False)
    customer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=True)  # Optional for registered users
    
    # Relationships
    salon = db.relationship('Tenant', backref='appointments')
    hairdresser = db.relationship('Hairdresser', backref='appointments')
    service = db.relationship('Service', backref='appointments')
    customer = db.relationship('User', backref='appointments')
    
    def __init__(self, *args, **kwargs):
        # Generate access code if not provided
        if 'access_code' not in kwargs:
            kwargs['access_code'] = self.generate_access_code()
        super().__init__(*args, **kwargs)
    
    @staticmethod
    def generate_access_code():
        """Generate a random access code for appointments."""
        chars = string.ascii_uppercase + string.digits
        code = ''.join(random.choices(chars, k=8))
        
        # Ensure uniqueness by checking database
        while Appointment.query.filter_by(access_code=code).first():
            code = ''.join(random.choices(chars, k=8))
            
        return code
    
    def to_dict(self):
        """Convert model to dictionary with additional fields."""
        data = super().to_dict()
        
        # Add related entity data
        if self.hairdresser:
            data['hairdresser_name'] = self.hairdresser.name
            
        if self.service:
            data['service_name'] = self.service.name
            data['service_price'] = self.service.price
            data['service_duration'] = self.service.duration_minutes
        
        # Format date and times
        if isinstance(self.appointment_date, datetime):
            data['formatted_date'] = self.appointment_date.strftime('%d.%m.%Y')
            
        if isinstance(self.start_time, datetime):
            data['formatted_start_time'] = self.start_time.strftime('%H:%M')
            
        if isinstance(self.end_time, datetime):
            data['formatted_end_time'] = self.end_time.strftime('%H:%M')
        
        # Convert enum to string
        if self.status:
            data['status'] = self.status.value
            
        return data