from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from ..services.auth_service import AuthService
from . import api_bp

@api_bp.route('/auth/register', methods=['POST'])
def register():
    """Register a new user."""
    data = request.get_json()
    
    # Required fields
    required_fields = ['username', 'email', 'password']
    for field in required_fields:
        if field not in data:
            return jsonify({'success': False, 'message': f'Missing required field: {field}'}), 400
    
    # Register the user
    result = AuthService.register_user(
        username=data['username'],
        email=data['email'],
        password=data['password'],
        first_name=data.get('first_name'),
        last_name=data.get('last_name'),
        phone=data.get('phone')
    )
    
    if result['success']:
        return jsonify(result), 201
    else:
        return jsonify(result), 400

@api_bp.route('/auth/login', methods=['POST'])
def login():
    """Login a user."""
    data = request.get_json()
    
    # Required fields
    if 'username' not in data or 'password' not in data:
        return jsonify({'success': False, 'message': 'Username/email and password required'}), 400
    
    # Login the user
    result = AuthService.login_user(
        username_or_email=data['username'],
        password=data['password']
    )
    
    if result['success']:
        return jsonify(result), 200
    else:
        return jsonify(result), 401

@api_bp.route('/auth/register-salon', methods=['POST'])
def register_salon():
    """Register a new salon owner with a tenant/salon."""
    data = request.get_json()
    
    # Required fields
    required_fields = ['name', 'slug', 'username', 'email', 'password']
    for field in required_fields:
        if field not in data:
            return jsonify({'success': False, 'message': f'Missing required field: {field}'}), 400
    
    # Register the salon owner
    result = AuthService.register_salon_owner(
        name=data['name'],
        slug=data['slug'],
        username=data['username'],
        email=data['email'],
        password=data['password'],
        first_name=data.get('first_name'),
        last_name=data.get('last_name'),
        phone=data.get('phone')
    )
    
    if result['success']:
        return jsonify(result), 201
    else:
        return jsonify(result), 400

@api_bp.route('/auth/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """Get the current authenticated user's information."""
    from ..models import User
    
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    if user:
        return jsonify({'success': True, 'user': user.to_dict()}), 200
    else:
        return jsonify({'success': False, 'message': 'User not found'}), 404