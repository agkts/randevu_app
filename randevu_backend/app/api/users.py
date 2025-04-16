from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity
from . import api_bp
from ..services.user_service import UserService
from ..models import UserRole

@api_bp.route('/users', methods=['GET'])
@jwt_required()
def get_users():
    """Get all users with optional filtering."""
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # If super admin, can get all users or filter by tenant_id from query params
    if user_role == UserRole.SUPER_ADMIN.value:
        query_tenant_id = request.args.get('tenant_id')
        role = request.args.get('role')
        
        if query_tenant_id:
            users = UserService.get_users_by_tenant(query_tenant_id, role=role if role else None)
        else:
            users = UserService.get_all_users(role=role if role else None)
    # If salon owner or hairdresser, can only get users from their own tenant
    elif user_role in [UserRole.SALON_OWNER.value, UserRole.HAIRDRESSER.value]:
        role = request.args.get('role')
        users = UserService.get_users_by_tenant(tenant_id, role=role if role else None)
    else:
        return jsonify({'success': False, 'message': 'Bu işlemi gerçekleştirmek için yetkiniz yok'}), 403
    
    return jsonify({
        'success': True,
        'users': [user.to_dict() for user in users]
    })

@api_bp.route('/users/<user_id>', methods=['GET'])
@jwt_required()
def get_user(user_id):
    """Get a user by ID."""
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    current_user_id = get_jwt_identity()
    
    # Users can always view their own profile
    if user_id == current_user_id:
        user = UserService.get_user_by_id(user_id)
        if user:
            return jsonify({'success': True, 'user': user.to_dict()})
        else:
            return jsonify({'success': False, 'message': 'Kullanıcı bulunamadı'}), 404
    
    # Super admin can view any user
    if user_role == UserRole.SUPER_ADMIN.value:
        user = UserService.get_user_by_id(user_id)
        if user:
            return jsonify({'success': True, 'user': user.to_dict()})
        else:
            return jsonify({'success': False, 'message': 'Kullanıcı bulunamadı'}), 404
    
    # Salon owner can view users in their tenant
    if user_role == UserRole.SALON_OWNER.value:
        user = UserService.get_user_by_id(user_id)
        if user and user.tenant_id == tenant_id:
            return jsonify({'success': True, 'user': user.to_dict()})
        else:
            return jsonify({'success': False, 'message': 'Kullanıcı bulunamadı veya erişim izniniz yok'}), 404
    
    # Other users can't view other profiles
    return jsonify({'success': False, 'message': 'Bu kullanıcıya erişim izniniz yok'}), 403

@api_bp.route('/users', methods=['POST'])
@jwt_required()
def create_user():
    """Create a new user."""
    data = request.get_json()
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # Only super admin or salon owner can create users
    if user_role not in [UserRole.SUPER_ADMIN.value, UserRole.SALON_OWNER.value]:
        return jsonify({'success': False, 'message': 'Bu işlemi gerçekleştirmek için yetkiniz yok'}), 403
    
    # If not super admin, ensure tenant_id matches user's tenant_id
    if user_role != UserRole.SUPER_ADMIN.value:
        data['tenant_id'] = tenant_id
        data['salon_id'] = tenant_id
        
        # Salon owners can only create hairdressers or customers
        if data.get('role') not in [UserRole.HAIRDRESSER.value, UserRole.CUSTOMER.value]:
            data['role'] = UserRole.CUSTOMER.value
    
    # Required fields
    required_fields = ['username', 'email', 'password']
    for field in required_fields:
        if field not in data:
            return jsonify({'success': False, 'message': f'{field} zorunludur'}), 400
    
    result = UserService.create_user(data)
    
    if result['success']:
        return jsonify({
            'success': True,
            'user': result['user'].to_dict(),
            'message': 'Kullanıcı başarıyla oluşturuldu'
        }), 201
    else:
        return jsonify({'success': False, 'message': result['message']}), 400

@api_bp.route('/users/<user_id>', methods=['PUT'])
@jwt_required()
def update_user(user_id):
    """Update a user."""
    data = request.get_json()
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    current_user_id = get_jwt_identity()
    
    # Users can update their own profile
    if user_id == current_user_id:
        # But can't change role or tenant
        if 'role' in data:
            del data['role']
        if 'tenant_id' in data:
            del data['tenant_id']
        if 'salon_id' in data:
            del data['salon_id']
    # Super admin can update any user
    elif user_role == UserRole.SUPER_ADMIN.value:
        pass  # Full access
    # Salon owner can update users in their tenant
    elif user_role == UserRole.SALON_OWNER.value:
        user = UserService.get_user_by_id(user_id)
        if not user or user.tenant_id != tenant_id:
            return jsonify({'success': False, 'message': 'Bu kullanıcıyı güncelleme izniniz yok'}), 403
        
        # Can't change tenant_id
        if 'tenant_id' in data:
            del data['tenant_id']
        if 'salon_id' in data:
            data['salon_id'] = tenant_id
        
        # Can't promote to salon owner or super admin
        if 'role' in data and data['role'] in [UserRole.SUPER_ADMIN.value, UserRole.SALON_OWNER.value]:
            del data['role']
    else:
        return jsonify({'success': False, 'message': 'Bu kullanıcıyı güncelleme izniniz yok'}), 403
    
    result = UserService.update_user(user_id, data)
    
    if result['success']:
        return jsonify({
            'success': True,
            'user': result['user'].to_dict(),
            'message': 'Kullanıcı başarıyla güncellendi'
        })
    else:
        return jsonify({'success': False, 'message': result['message']}), 400

@api_bp.route('/users/<user_id>', methods=['DELETE'])
@jwt_required()
def delete_user(user_id):
    """Delete a user."""
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    current_user_id = get_jwt_identity()
    
    # Can't delete yourself
    if user_id == current_user_id:
        return jsonify({'success': False, 'message': 'Kendinizi silemezsiniz'}), 400
    
    # Super admin can delete any user
    if user_role == UserRole.SUPER_ADMIN.value:
        pass  # Full access
    # Salon owner can delete users in their tenant except other salon owners
    elif user_role == UserRole.SALON_OWNER.value:
        user = UserService.get_user_by_id(user_id)
        if not user or user.tenant_id != tenant_id:
            return jsonify({'success': False, 'message': 'Bu kullanıcıyı silme izniniz yok'}), 403
        
        # Can't delete other salon owners
        if user.role == UserRole.SALON_OWNER:
            return jsonify({'success': False, 'message': 'Salon sahibini silemezsiniz'}), 403
    else:
        return jsonify({'success': False, 'message': 'Bu işlemi gerçekleştirmek için yetkiniz yok'}), 403
    
    result = UserService.delete_user(user_id)
    
    if result['success']:
        return jsonify({
            'success': True,
            'message': 'Kullanıcı başarıyla silindi'
        })
    else:
        return jsonify({'success': False, 'message': result['message']}), 400

@api_bp.route('/users/<user_id>/status', methods=['PATCH'])
@jwt_required()
def toggle_user_status(user_id):
    """Enable or disable a user."""
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    current_user_id = get_jwt_identity()
    
    # Can't disable yourself
    if user_id == current_user_id:
        return jsonify({'success': False, 'message': 'Kendi durumunuzu değiştiremezsiniz'}), 400
    
    data = request.get_json()
    is_active = data.get('is_active', True)
    
    # Super admin can toggle any user
    if user_role == UserRole.SUPER_ADMIN.value:
        pass  # Full access
    # Salon owner can toggle users in their tenant except other salon owners
    elif user_role == UserRole.SALON_OWNER.value:
        user = UserService.get_user_by_id(user_id)
        if not user or user.tenant_id != tenant_id:
            return jsonify({'success': False, 'message': 'Bu kullanıcıyı güncelleme izniniz yok'}), 403
        
        # Can't toggle other salon owners
        if user.role == UserRole.SALON_OWNER:
            return jsonify({'success': False, 'message': 'Salon sahibinin durumunu değiştiremezsiniz'}), 403
    else:
        return jsonify({'success': False, 'message': 'Bu işlemi gerçekleştirmek için yetkiniz yok'}), 403
    
    result = UserService.toggle_user_status(user_id, is_active)
    
    if result['success']:
        return jsonify({
            'success': True,
            'user': result['user'].to_dict(),
            'message': f'Kullanıcı durumu {"aktif" if is_active else "pasif"} olarak güncellendi'
        })
    else:
        return jsonify({'success': False, 'message': result['message']}), 400