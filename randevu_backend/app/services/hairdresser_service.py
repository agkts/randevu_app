from ..models import Hairdresser, User, UserRole
from ..extensions import db

class HairdresserService:
    """Service for hairdresser operations."""
    
    @staticmethod
    def get_hairdresser_by_id(hairdresser_id):
        """Get a hairdresser by ID."""
        return Hairdresser.query.get(hairdresser_id)
    
    @staticmethod
    def get_hairdressers_by_salon(salon_id, include_inactive=False):
        """Get all hairdressers for a salon."""
        query = Hairdresser.query.filter_by(salon_id=salon_id)
        
        if not include_inactive:
            query = query.filter_by(is_active=True)
            
        return query.all()
    
    @staticmethod
    def create_hairdresser(data, create_user=False):
        """Create a new hairdresser."""
        try:
            # Create hairdresser
            hairdresser = Hairdresser(
                name=data.get('name'),
                email=data.get('email'),
                phone=data.get('phone'),
                profile_image=data.get('profile_image'),
                working_schedule=data.get('working_schedule', Hairdresser.create_default_schedule()),
                service_ids=data.get('service_ids', []),
                is_active=data.get('is_active', True),
                salon_id=data.get('salon_id'),
            )
            
            # If we need to create a user account for the hairdresser
            if create_user and data.get('username') and data.get('password'):
                user = User(
                    username=data.get('username'),
                    email=data.get('email'),
                    first_name=data.get('name').split(' ')[0] if data.get('name') else None,
                    last_name=' '.join(data.get('name').split(' ')[1:]) if data.get('name') and len(data.get('name').split(' ')) > 1 else None,
                    phone=data.get('phone'),
                    role=UserRole.HAIRDRESSER,
                    tenant_id=data.get('salon_id'),
                    salon_id=data.get('salon_id')
                )
                user.set_password(data.get('password'))
                
                db.session.add(user)
                db.session.flush()  # Get user_id without committing
                
                hairdresser.user_id = user.id
            
            db.session.add(hairdresser)
            db.session.commit()
            
            return {'success': True, 'hairdresser': hairdresser}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def update_hairdresser(hairdresser_id, data):
        """Update a hairdresser's details."""
        hairdresser = Hairdresser.query.get(hairdresser_id)
        
        if not hairdresser:
            return {'success': False, 'message': 'Kuaför bulunamadı'}
            
        try:
            # Update basic fields
            for field in ['name', 'email', 'phone', 'profile_image', 'is_active']:
                if field in data:
                    setattr(hairdresser, field, data[field])
            
            # Update service IDs
            if 'service_ids' in data:
                hairdresser.service_ids = data['service_ids']
            
            # Update working schedule
            if 'working_schedule' in data:
                hairdresser.working_schedule.update(data['working_schedule'])
            
            # Update holiday dates
            if 'holiday_dates' in data:
                hairdresser.holiday_dates = data['holiday_dates']
                
            db.session.commit()
            
            return {'success': True, 'hairdresser': hairdresser}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def delete_hairdresser(hairdresser_id):
        """Delete a hairdresser."""
        hairdresser = Hairdresser.query.get(hairdresser_id)
        
        if not hairdresser:
            return {'success': False, 'message': 'Kuaför bulunamadı'}
            
        try:
            # If there's an associated user, deactivate it but don't delete
            if hairdresser.user_id:
                user = User.query.get(hairdresser.user_id)
                if user:
                    user.is_active = False
                    
            db.session.delete(hairdresser)
            db.session.commit()
            
            return {'success': True, 'message': 'Kuaför silindi'}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}