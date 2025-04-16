from ..models import Tenant
from ..extensions import db

class TenantService:
    """Service for tenant (salon) operations."""
    
    @staticmethod
    def get_tenant_by_id(tenant_id):
        """Get a tenant by ID."""
        return Tenant.query.get(tenant_id)
        
    @staticmethod
    def get_tenant_by_slug(slug):
        """Get a tenant by slug."""
        return Tenant.query.filter_by(slug=slug, is_active=True).first()
    
    @staticmethod
    def update_tenant(tenant_id, data):
        """Update a tenant's details."""
        tenant = Tenant.query.get(tenant_id)
        if not tenant:
            return {'success': False, 'message': 'Salon bulunamadı'}
        
        try:
            # Update basic fields
            for field in ['name', 'email', 'phone', 'address', 'website']:
                if field in data:
                    setattr(tenant, field, data[field])
            
            # Update logo
            if 'logo_url' in data:
                tenant.logo_url = data['logo_url']
                
            # Update settings
            if 'settings' in data:
                tenant.settings.update(data['settings'])
                
            # Update SMS settings
            if 'sms_settings' in data:
                tenant.sms_settings.update(data['sms_settings'])
                
            # Update working schedule
            if 'working_schedule' in data:
                tenant.working_schedule.update(data['working_schedule'])
                
            db.session.commit()
            return {'success': True, 'tenant': tenant}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def get_all_tenants(active_only=True):
        """Get all tenants."""
        query = Tenant.query
        if active_only:
            query = query.filter_by(is_active=True)
        return query.all()
    
    @staticmethod
    def toggle_tenant_status(tenant_id, is_active):
        """Enable or disable a tenant."""
        tenant = Tenant.query.get(tenant_id)
        if not tenant:
            return {'success': False, 'message': 'Salon bulunamadı'}
            
        try:
            tenant.is_active = is_active
            db.session.commit()
            return {'success': True, 'tenant': tenant}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def update_subscription(tenant_id, plan, start_date, end_date):
        """Update a tenant's subscription details."""
        tenant = Tenant.query.get(tenant_id)
        if not tenant:
            return {'success': False, 'message': 'Salon bulunamadı'}
            
        try:
            tenant.subscription_plan = plan
            tenant.subscription_start_date = start_date
            tenant.subscription_end_date = end_date
            db.session.commit()
            return {'success': True, 'tenant': tenant}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}