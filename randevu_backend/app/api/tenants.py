from flask import request, jsonify, g
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity
from . import api_bp
from ..services.tenant_service import TenantService
from ..models import UserRole

@api_bp.route('/tenants/<tenant_id>', methods=['GET'])
@jwt_required()
def get_tenant(tenant_id):
    """Get a tenant by ID."""
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    
    # If not super admin, check if user belongs to the tenant
    if user_role != UserRole.SUPER_ADMIN.value:
        tenant_id_from_token = claims.get('tenant_id')
        if tenant_id != tenant_id_from_token:
            return jsonify({'success': False, 'message': 'Bu salona erişim izniniz yok'}), 403
    
    tenant = TenantService.get_tenant_by_id(tenant_id)
    if tenant:
        return jsonify({'success': True, 'tenant': tenant.to_dict()})
    else:
        return jsonify({'success': False, 'message': 'Salon bulunamadı'}), 404

@api_bp.route('/tenants/<tenant_id>', methods=['PUT'])
@jwt_required()
def update_tenant(tenant_id):
    """Update a tenant."""
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    
    # If not super admin, check if user belongs to the tenant
    if user_role != UserRole.SUPER_ADMIN.value:
        tenant_id_from_token = claims.get('tenant_id')
        if tenant_id != tenant_id_from_token:
            return jsonify({'success': False, 'message': 'Bu salonu düzenleme izniniz yok'}), 403
    
    data = request.get_json()
    result = TenantService.update_tenant(tenant_id, data)
    
    if result['success']:
        return jsonify({'success': True, 'tenant': result['tenant'].to_dict()})
    else:
        return jsonify({'success': False, 'message': result['message']}), 400

@api_bp.route('/tenants', methods=['GET'])
@jwt_required()
def get_tenants():
    """Get all tenants. Only for super admins."""
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    
    if user_role != UserRole.SUPER_ADMIN.value:
        return jsonify({'success': False, 'message': 'Bu işlemi gerçekleştirmek için yetkiniz yok'}), 403
    
    active_only = request.args.get('active_only', 'true').lower() == 'true'
    tenants = TenantService.get_all_tenants(active_only=active_only)
    
    return jsonify({
        'success': True,
        'tenants': [tenant.to_dict() for tenant in tenants]
    })

@api_bp.route('/tenants/<tenant_id>/status', methods=['PATCH'])
@jwt_required()
def toggle_tenant_status(tenant_id):
    """Enable or disable a tenant. Only for super admins."""
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    
    if user_role != UserRole.SUPER_ADMIN.value:
        return jsonify({'success': False, 'message': 'Bu işlemi gerçekleştirmek için yetkiniz yok'}), 403
    
    data = request.get_json()
    is_active = data.get('is_active', True)
    
    result = TenantService.toggle_tenant_status(tenant_id, is_active)
    
    if result['success']:
        return jsonify({'success': True, 'tenant': result['tenant'].to_dict()})
    else:
        return jsonify({'success': False, 'message': result['message']}), 400

@api_bp.route('/tenants/<tenant_id>/subscription', methods=['PATCH'])
@jwt_required()
def update_tenant_subscription(tenant_id):
    """Update a tenant's subscription. Only for super admins."""
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    
    if user_role != UserRole.SUPER_ADMIN.value:
        return jsonify({'success': False, 'message': 'Bu işlemi gerçekleştirmek için yetkiniz yok'}), 403
    
    data = request.get_json()
    
    # Parse dates from string to datetime objects
    from datetime import datetime
    start_date = datetime.fromisoformat(data['start_date']) if 'start_date' in data else None
    end_date = datetime.fromisoformat(data['end_date']) if 'end_date' in data else None
    
    result = TenantService.update_subscription(
        tenant_id, 
        data.get('plan'), 
        start_date, 
        end_date
    )
    
    if result['success']:
        return jsonify({'success': True, 'tenant': result['tenant'].to_dict()})
    else:
        return jsonify({'success': False, 'message': result['message']}), 400