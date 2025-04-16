from flask_jwt_extended import create_access_token
from datetime import timedelta
from ..models import User, UserRole, Tenant
from ..extensions import db

class AuthService:
    """Service for authentication and authorization."""
    
    @staticmethod
    def register_user(username, email, password, first_name=None, last_name=None, 
                      phone=None, role=UserRole.CUSTOMER, tenant_id=None):
        """Register a new user."""
        # Check if user already exists
        if User.query.filter_by(username=username).first():
            return {'success': False, 'message': 'Kullanıcı adı zaten alınmış'}
            
        if User.query.filter_by(email=email).first():
            return {'success': False, 'message': 'E-posta adresi zaten kullanılıyor'}
            
        # Create new user
        user = User(
            username=username,
            email=email,
            first_name=first_name,
            last_name=last_name,
            phone=phone,
            role=role,
            tenant_id=tenant_id
        )
        user.set_password(password)
        
        try:
            db.session.add(user)
            db.session.commit()
            
            # Generate token
            token = create_access_token(
                identity=user.id,
                additional_claims={
                    'role': user.role.value,
                    'tenant_id': user.tenant_id
                }
            )
            
            return {
                'success': True,
                'user': user.to_dict(),
                'token': token
            }
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def login_user(username_or_email, password):
        """Login a user and return access token."""
        # Check if user exists
        user = User.query.filter((User.username == username_or_email) | 
                                (User.email == username_or_email)).first()
        
        if not user or not user.check_password(password):
            return {'success': False, 'message': 'Geçersiz kullanıcı adı/e-posta veya şifre'}
            
        if not user.is_active:
            return {'success': False, 'message': 'Hesabınız askıya alınmış'}
            
        # Generate token
        token = create_access_token(
            identity=user.id,
            additional_claims={
                'role': user.role.value,
                'tenant_id': user.tenant_id
            }
        )
        
        return {
            'success': True,
            'user': user.to_dict(),
            'token': token
        }
    
    @staticmethod
    def register_salon_owner(name, slug, username, email, password, 
                             first_name=None, last_name=None, phone=None):
        """Register a salon owner with a new tenant."""
        # Check if salon slug already exists
        if Tenant.query.filter_by(slug=slug).first():
            return {'success': False, 'message': 'Salon URL\'si zaten kullanılıyor'}
            
        try:
            # Create user with salon owner role
            user = User(
                username=username,
                email=email,
                first_name=first_name,
                last_name=last_name,
                phone=phone,
                role=UserRole.SALON_OWNER
            )
            user.set_password(password)
            db.session.add(user)
            db.session.flush()  # Get user ID without committing
            
            # Create salon/tenant
            tenant = Tenant(
                name=name,
                slug=slug,
                owner_id=user.id,
                email=email,
                phone=phone,
                settings=Tenant.create_default_settings(),
                sms_settings=Tenant.create_default_sms_settings(),
                working_schedule=Tenant.create_default_schedule()
            )
            db.session.add(tenant)
            
            # Update user with tenant_id
            user.tenant_id = tenant.id
            user.salon_id = tenant.id
            
            db.session.commit()
            
            # Generate token
            token = create_access_token(
                identity=user.id,
                additional_claims={
                    'role': user.role.value,
                    'tenant_id': tenant.id
                }
            )
            
            return {
                'success': True,
                'user': user.to_dict(),
                'salon': tenant.to_dict(),
                'token': token
            }
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}