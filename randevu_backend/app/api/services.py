from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from . import api_bp
from ..services.service_service import ServiceService
from ..models import UserRole

@api_bp.route('/services', methods=['GET'])
@jwt_required()
def get_services():
    """Get all services for a salon."""
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # Get salon_id from query params or token
    salon_id = request.args.get('salon_id', tenant_id)
    
    # If not super admin, check if user belongs to the salon
    if user_role != UserRole.SUPER_ADMIN.value:
        if salon_id != tenant_id:
            return jsonify({'success': False, 'message': 'Bu salona erişim izniniz yok'}), 403
    
    include_inactive = request.args.get('include_inactive', 'false').lower() == 'true'
    
    services = ServiceService.get_services_by_salon(
        salon_id, include_inactive=include_inactive
    )
    
    return jsonify({
        'success': True, 
        'services': [s.to_dict() for s in services]
    })

@api_bp.route('/services/<service_id>', methods=['GET'])
@jwt_required()
def get_service(service_id):
    """Get a service by ID."""
    # Get the service
    service = ServiceService.get_service_by_id(service_id)
    
    if not service:
        return jsonify({'success': False, 'message': 'Hizmet bulunamadı'}), 404
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # If not super admin, check if user belongs to the salon
    if user_role != UserRole.SUPER_ADMIN.value:
        if service.salon_id != tenant_id:
            return jsonify({'success': False, 'message': 'Bu hizmete erişim izniniz yok'}), 403
    
    return jsonify({
        'success': True, 
        'service': service.to_dict()
    })

@api_bp.route('/services', methods=['POST'])
@jwt_required()
def create_service():
    """Create a new service."""
    data = request.get_json()
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # Only super admin or salon owner can create services
    if user_role not in [UserRole.SUPER_ADMIN.value, UserRole.SALON_OWNER.value]:
        return jsonify({'success': False, 'message': 'Bu işlemi gerçekleştirmek için yetkiniz yok'}), 403
    
    # If not super admin, ensure salon_id matches user's tenant_id
    salon_id = data.get('salon_id')
    if user_role != UserRole.SUPER_ADMIN.value and salon_id != tenant_id:
        return jsonify({'success': False, 'message': 'Sadece kendi salonunuza hizmet ekleyebilirsiniz'}), 403
    
    # Required fields
    if not data.get('name') or not data.get('salon_id'):
        return jsonify({'success': False, 'message': 'İsim ve salon ID zorunludur'}), 400
    
    result = ServiceService.create_service(data)
    
    if result['success']:
        return jsonify({
            'success': True, 
            'service': result['service'].to_dict(),
            'message': 'Hizmet başarıyla oluşturuldu'
        }), 201
    else:
        return jsonify({'success': False, 'message': result['message']}), 400

@api_bp.route('/services/<service_id>', methods=['PUT'])
@jwt_required()
def update_service(service_id):
    """Update a service."""
    # Get the service first to check permissions
    service = ServiceService.get_service_by_id(service_id)
    
    if not service:
        return jsonify({'success': False, 'message': 'Hizmet bulunamadı'}), 404
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # If not super admin or salon owner, check if user belongs to the salon
    if user_role not in [UserRole.SUPER_ADMIN.value, UserRole.SALON_OWNER.value]:
        if service.salon_id != tenant_id:
            return jsonify({'success': False, 'message': 'Bu hizmeti düzenleme izniniz yok'}), 403
    
    data = request.get_json()
    result = ServiceService.update_service(service_id, data)
    
    if result['success']:
        return jsonify({
            'success': True, 
            'service': result['service'].to_dict(),
            'message': 'Hizmet başarıyla güncellendi'
        })
    else:
        return jsonify({'success': False, 'message': result['message']}), 400

@api_bp.route('/services/<service_id>', methods=['DELETE'])
@jwt_required()
def delete_service(service_id):
    """Delete a service."""
    # Get the service first to check permissions
    service = ServiceService.get_service_by_id(service_id)
    
    if not service:
        return jsonify({'success': False, 'message': 'Hizmet bulunamadı'}), 404
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # If not super admin or salon owner, check if user belongs to the salon
    if user_role not in [UserRole.SUPER_ADMIN.value, UserRole.SALON_OWNER.value]:
        if service.salon_id != tenant_id:
            return jsonify({'success': False, 'message': 'Bu hizmeti silme izniniz yok'}), 403
    
    result = ServiceService.delete_service(service_id)
    
    if result['success']:
        return jsonify({
            'success': True, 
            'message': 'Hizmet başarıyla silindi'
        })
    else:
        return jsonify({'success': False, 'message': result['message']}), 400