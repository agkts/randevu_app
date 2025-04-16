import uuid
from datetime import datetime
from ..extensions import db

class BaseModel:
    """Base model with common attributes and methods."""
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def save(self):
        """Save the model to the database."""
        db.session.add(self)
        db.session.commit()
        return self
        
    def delete(self):
        """Delete the model from the database."""
        db.session.delete(self)
        db.session.commit()
        
    def to_dict(self):
        """Convert model to dictionary."""
        result = {}
        for column in self.__table__.columns:
            value = getattr(self, column.name)
            if isinstance(value, datetime):
                value = value.isoformat()
            result[column.name] = value
        return result