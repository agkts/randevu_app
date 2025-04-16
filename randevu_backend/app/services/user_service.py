from ..models import User, UserRole
from ..extensions import db

class UserService:
    """Service for user management operations."""
    
    @staticmethod
    def get_user_by_id(user_id):
        """Get a user by ID."""
        return User.query.get(user_id)
    
    @staticmethod
    def get_users_by_tenant(tenant_id, role=None):
        """Get all users for a tenant with optional role filtering."""
        query = User.query.filter_by(tenant_id=tenant_id)
        
        if role:
            query = query.filter_by(role=role)
            
        return query.all()
    
    @staticmethod
    def get_all_users(role=None):
        """Get all users with optional role filtering."""
        query = User.query
        
        if role:
            query = query.filter_by(role=role)
            
        return query.all()
    
    @staticmethod
    def create_user(data):
        """Create a new user."""
        # Check if username or email already exists
        if User.query.filter_by(username=data.get('username')).first():
            return {'success': False, 'message': 'Bu kullanıcı adı zaten alınmış'}
            
        if User.query.filter_by(email=data.get('email')).first():
            return {'success': False, 'message': 'Bu e-posta adresi zaten kullanılıyor'}
        
        try:
            user = User(
                username=data.get('username'),
                email=data.get('email'),
                first_name=data.get('first_name'),
                last_name=data.get('last_name'),
                phone=data.get('phone'),
                role=UserRole(data.get('role', 'customer')),
                is_active=data.get('is_active', True),
                tenant_id=data.get('tenant_id'),
                salon_id=data.get('salon_id'),
                profile_image=data.get('profile_image')
            )
            
            # Set password
            if data.get('password'):
                user.set_password(data.get('password'))
            else:
                return {'success': False, 'message': 'Şifre zorunludur'}
            
            db.session.add(user)
            db.session.commit()
            
            return {'success': True, 'user': user}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def update_user(user_id, data):
        """Update a user's details."""
        user = User.query.get(user_id)
        
        if not user:
            return {'success': False, 'message': 'Kullanıcı bulunamadı'}
        
        try:
            # Update basic fields
            for field in ['first_name', 'last_name', 'phone', 'is_active', 'profile_image']:
                if field in data:
                    setattr(user, field, data[field])
            
            # Update email if provided and not already used by another user
            if 'email' in data and data['email'] != user.email:
                if User.query.filter_by(email=data['email']).first():
                    return {'success': False, 'message': 'Bu e-posta adresi zaten kullanılıyor'}
                user.email = data['email']
            
            # Update username if provided and not already used by another user
            if 'username' in data and data['username'] != user.username:
                if User.query.filter_by(username=data['username']).first():
                    return {'success': False, 'message': 'Bu kullanıcı adı zaten alınmış'}
                user.username = data['username']
            
            # Update password if provided
            if 'password' in data and data['password']:
                user.set_password(data['password'])
            
            # Update role if provided (only by super admin)
            if 'role' in data:
                user.role = UserRole(data['role'])
            
            # Update tenant_id if provided (only by super admin)
            if 'tenant_id' in data:
                user.tenant_id = data['tenant_id']
                
            if 'salon_id' in data:
                user.salon_id = data['salon_id']
            
            db.session.commit()
            
            return {'success': True, 'user': user}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def delete_user(user_id):
        """Delete a user."""
        user = User.query.get(user_id)
        
        if not user:
            return {'success': False, 'message': 'Kullanıcı bulunamadı'}
        
        try:
            db.session.delete(user)
            db.session.commit()
            
            return {'success': True, 'message': 'Kullanıcı silindi'}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def toggle_user_status(user_id, is_active):
        """Enable or disable a user."""
        user = User.query.get(user_id)
        
        if not user:
            return {'success': False, 'message': 'Kullanıcı bulunamadı'}
        
        try:
            user.is_active = is_active
            db.session.commit()
            
            return {'success': True, 'user': user}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}