from ..models import Service
from ..extensions import db

class ServiceService:
    """Service for salon service operations."""
    
    @staticmethod
    def get_service_by_id(service_id):
        """Get a service by ID."""
        return Service.query.get(service_id)
    
    @staticmethod
    def get_services_by_salon(salon_id, include_inactive=False):
        """Get all services for a salon."""
        query = Service.query.filter_by(salon_id=salon_id)
        
        if not include_inactive:
            query = query.filter_by(is_active=True)
            
        return query.all()
    
    @staticmethod
    def create_service(data):
        """Create a new service."""
        try:
            service = Service(
                name=data.get('name'),
                price=data.get('price', 0.0),
                duration_minutes=data.get('duration_minutes', 30),
                description=data.get('description'),
                is_active=data.get('is_active', True),
                salon_id=data.get('salon_id')
            )
            
            db.session.add(service)
            db.session.commit()
            
            return {'success': True, 'service': service}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def update_service(service_id, data):
        """Update a service's details."""
        service = Service.query.get(service_id)
        
        if not service:
            return {'success': False, 'message': 'Hizmet bulunamadı'}
            
        try:
            # Update basic fields
            for field in ['name', 'price', 'duration_minutes', 'description', 'is_active']:
                if field in data:
                    setattr(service, field, data[field])
                
            db.session.commit()
            
            return {'success': True, 'service': service}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def delete_service(service_id):
        """Delete a service."""
        service = Service.query.get(service_id)
        
        if not service:
            return {'success': False, 'message': 'Hizmet bulunamadı'}
            
        try:
            db.session.delete(service)
            db.session.commit()
            
            return {'success': True, 'message': 'Hizmet silindi'}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}