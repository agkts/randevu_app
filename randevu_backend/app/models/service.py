from ..extensions import db
from .base import BaseModel

class Service(db.Model, BaseModel):
    """Service model representing salon services."""
    
    __tablename__ = 'services'
    
    # Basic information
    name = db.Column(db.String(100), nullable=False)
    price = db.Column(db.Float, nullable=False)
    duration_minutes = db.Column(db.Integer, nullable=False, default=30)  # Default 30 minutes
    description = db.Column(db.String(500), nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    
    # Foreign key
    salon_id = db.Column(db.String(36), db.ForeignKey('tenants.id'), nullable=False)
    
    # Relationships
    salon = db.relationship('Tenant', backref='services')
    
    def to_dict(self):
        """Convert model to dictionary with additional fields."""
        data = super().to_dict()
        
        # Add formatted fields
        data['formatted_price'] = f"₺{self.price:.2f}"
        
        hours = self.duration_minutes // 60
        minutes = self.duration_minutes % 60
        
        if hours > 0:
            data['formatted_duration'] = f"{hours} saat {minutes > 0 and f'{minutes} dk' or ''}"
        else:
            data['formatted_duration'] = f"{minutes} dk"
            
        return data