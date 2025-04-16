from flask import request, jsonify, g
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity
from . import api_bp
from ..services.hairdresser_service import HairdresserService
from ..models import UserRole

@api_bp.route('/hairdressers', methods=['GET'])
@jwt_required()
def get_hairdressers():
    """Get all hairdressers for a salon."""
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # Get salon_id from query params or token
    salon_id = request.args.get('salon_id', tenant_id)
    
    # If not super admin or salon owner, check if user belongs to the salon
    if user_role not in [UserRole.SUPER_ADMIN.value, UserRole.SALON_OWNER.value]:
        if salon_id != tenant_id:
            return jsonify({'success': False, 'message': 'Bu salona erişim izniniz yok'}), 403
    
    include_inactive = request.args.get('include_inactive', 'false').lower() == 'true'
    
    hairdressers = HairdresserService.get_hairdressers_by_salon(
        salon_id, include_inactive=include_inactive
    )
    
    return jsonify({
        'success': True, 
        'hairdressers': [h.to_dict() for h in hairdressers]
    })

@api_bp.route('/hairdressers/<hairdresser_id>', methods=['GET'])
@jwt_required()
def get_hairdresser(hairdresser_id):
    """Get a hairdresser by ID."""
    # Get the hairdresser
    hairdresser = HairdresserService.get_hairdresser_by_id(hairdresser_id)
    
    if not hairdresser:
        return jsonify({'success': False, 'message': 'Kuaför bulunamadı'}), 404
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # If not super admin or salon owner, check if user belongs to the salon
    if user_role not in [UserRole.SUPER_ADMIN.value, UserRole.SALON_OWNER.value]:
        if hairdresser.salon_id != tenant_id:
            return jsonify({'success': False, 'message': 'Bu kuaföre erişim izniniz yok'}), 403
    
    return jsonify({
        'success': True, 
        'hairdresser': hairdresser.to_dict()
    })

@api_bp.route('/hairdressers', methods=['POST'])
@jwt_required()
def create_hairdresser():
    """Create a new hairdresser."""
    data = request.get_json()
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # Only super admin or salon owner can create hairdressers
    if user_role not in [UserRole.SUPER_ADMIN.value, UserRole.SALON_OWNER.value]:
        return jsonify({'success': False, 'message': 'Bu işlemi gerçekleştirmek için yetkiniz yok'}), 403
    
    # If not super admin, ensure salon_id matches user's tenant_id
    salon_id = data.get('salon_id')
    if user_role != UserRole.SUPER_ADMIN.value and salon_id != tenant_id:
        return jsonify({'success': False, 'message': 'Sadece kendi salonunuza kuaför ekleyebilirsiniz'}), 403
    
    # Required fields
    if not data.get('name') or not data.get('salon_id'):
        return jsonify({'success': False, 'message': 'İsim ve salon ID zorunludur'}), 400
    
    # Create user account if username and password provided
    create_user = bool(data.get('username') and data.get('password'))
    
    result = HairdresserService.create_hairdresser(data, create_user=create_user)
    
    if result['success']:
        return jsonify({
            'success': True, 
            'hairdresser': result['hairdresser'].to_dict(),
            'message': 'Kuaför başarıyla oluşturuldu'
        }), 201
    else:
        return jsonify({'success': False, 'message': result['message']}), 400

@api_bp.route('/hairdressers/<hairdresser_id>', methods=['PUT'])
@jwt_required()
def update_hairdresser(hairdresser_id):
    """Update a hairdresser."""
    # Get the hairdresser first to check permissions
    hairdresser = HairdresserService.get_hairdresser_by_id(hairdresser_id)
    
    if not hairdresser:
        return jsonify({'success': False, 'message': 'Kuaför bulunamadı'}), 404
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # If not super admin or salon owner, check if user belongs to the salon
    if user_role not in [UserRole.SUPER_ADMIN.value, UserRole.SALON_OWNER.value]:
        if hairdresser.salon_id != tenant_id:
            return jsonify({'success': False, 'message': 'Bu kuaförü düzenleme izniniz yok'}), 403
    
    data = request.get_json()
    result = HairdresserService.update_hairdresser(hairdresser_id, data)
    
    if result['success']:
        return jsonify({
            'success': True, 
            'hairdresser': result['hairdresser'].to_dict(),
            'message': 'Kuaför başarıyla güncellendi'
        })
    else:
        return jsonify({'success': False, 'message': result['message']}), 400

@api_bp.route('/hairdressers/<hairdresser_id>', methods=['DELETE'])
@jwt_required()
def delete_hairdresser(hairdresser_id):
    """Delete a hairdresser."""
    # Get the hairdresser first to check permissions
    hairdresser = HairdresserService.get_hairdresser_by_id(hairdresser_id)
    
    if not hairdresser:
        return jsonify({'success': False, 'message': 'Kuaför bulunamadı'}), 404
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # If not super admin or salon owner, check if user belongs to the salon
    if user_role not in [UserRole.SUPER_ADMIN.value, UserRole.SALON_OWNER.value]:
        if hairdresser.salon_id != tenant_id:
            return jsonify({'success': False, 'message': 'Bu kuaförü silme izniniz yok'}), 403
    
    result = HairdresserService.delete_hairdresser(hairdresser_id)
    
    if result['success']:
        return jsonify({
            'success': True, 
            'message': 'Kuaför başarıyla silindi'
        })
    else:
        return jsonify({'success': False, 'message': result['message']}), 400