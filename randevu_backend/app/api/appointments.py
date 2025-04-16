from flask import request, jsonify
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity
from . import api_bp
from ..services.appointment_service import AppointmentService
from ..models import AppointmentStatus, UserRole

@api_bp.route('/appointments', methods=['GET'])
@jwt_required()
def get_appointments():
    """Get all appointments for a salon with optional filtering."""
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # Get salon_id from query params or token
    salon_id = request.args.get('salon_id', tenant_id)
    
    # If not super admin, ensure user only accesses their own salon
    if user_role != UserRole.SUPER_ADMIN.value and salon_id != tenant_id:
        return jsonify({'success': False, 'message': 'Bu salona erişim izniniz yok'}), 403
    
    # Extract filters from request args
    filters = {}
    for key in ['date', 'hairdresser_id', 'status', 'customer_phone', 'future_only']:
        if key in request.args:
            filters[key] = request.args.get(key)
    
    appointments = AppointmentService.get_appointments_by_salon(salon_id, filters)
    
    return jsonify({
        'success': True, 
        'appointments': [appt.to_dict() for appt in appointments]
    })

@api_bp.route('/appointments/<appointment_id>', methods=['GET'])
@jwt_required()
def get_appointment(appointment_id):
    """Get an appointment by ID."""
    # Get the appointment
    appointment = AppointmentService.get_appointment_by_id(appointment_id)
    
    if not appointment:
        return jsonify({'success': False, 'message': 'Randevu bulunamadı'}), 404
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # If not super admin, ensure user only accesses their own salon's appointments
    if user_role != UserRole.SUPER_ADMIN.value and appointment.salon_id != tenant_id:
        return jsonify({'success': False, 'message': 'Bu randevuya erişim izniniz yok'}), 403
    
    return jsonify({
        'success': True, 
        'appointment': appointment.to_dict()
    })

@api_bp.route('/appointments/code/<access_code>', methods=['GET'])
def get_appointment_by_code(access_code):
    """Get an appointment by access code - public endpoint for customers."""
    # This endpoint is public so customers can check their appointment status
    appointment = AppointmentService.get_appointment_by_code(access_code)
    
    if not appointment:
        return jsonify({'success': False, 'message': 'Randevu bulunamadı'}), 404
    
    return jsonify({
        'success': True, 
        'appointment': appointment.to_dict()
    })

@api_bp.route('/appointments/slots', methods=['GET'])
def get_available_slots():
    """Get available appointment slots for a hairdresser on a date."""
    # Required query parameters
    salon_id = request.args.get('salon_id')
    hairdresser_id = request.args.get('hairdresser_id')
    date = request.args.get('date')
    
    if not salon_id or not hairdresser_id or not date:
        return jsonify({'success': False, 'message': 'Salon ID, kuaför ID ve tarih zorunludur'}), 400
    
    result = AppointmentService.get_available_slots(salon_id, hairdresser_id, date)
    
    if result['success']:
        return jsonify(result)
    else:
        return jsonify(result), 400

@api_bp.route('/appointments', methods=['POST'])
def create_appointment():
    """Create a new appointment - can be used by both authenticated users and public."""
    data = request.get_json()
    
    # Required fields
    required_fields = ['salon_id', 'hairdresser_id', 'service_id', 'date', 'start_time', 'customer_name', 'customer_phone']
    for field in required_fields:
        if field not in data:
            return jsonify({'success': False, 'message': f'{field} zorunludur'}), 400
    
    result = AppointmentService.create_appointment(data)
    
    if result['success']:
        return jsonify({
            'success': True, 
            'appointment': result['appointment'].to_dict(),
            'message': 'Randevu başarıyla oluşturuldu'
        }), 201
    else:
        return jsonify({'success': False, 'message': result['message']}), 400

@api_bp.route('/appointments/<appointment_id>/status', methods=['PATCH'])
@jwt_required()
def update_appointment_status(appointment_id):
    """Update an appointment's status - requires authentication."""
    # Get the appointment
    appointment = AppointmentService.get_appointment_by_id(appointment_id)
    
    if not appointment:
        return jsonify({'success': False, 'message': 'Randevu bulunamadı'}), 404
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # If not super admin or salon staff, ensure user only accesses their own salon's appointments
    if user_role not in [UserRole.SUPER_ADMIN.value, UserRole.SALON_OWNER.value, UserRole.HAIRDRESSER.value]:
        return jsonify({'success': False, 'message': 'Bu işlemi gerçekleştirmek için yetkiniz yok'}), 403
        
    if user_role != UserRole.SUPER_ADMIN.value and appointment.salon_id != tenant_id:
        return jsonify({'success': False, 'message': 'Bu randevuyu düzenleme izniniz yok'}), 403
    
    data = request.get_json()
    if 'status' not in data:
        return jsonify({'success': False, 'message': 'Durum belirtilmelidir'}), 400
    
    try:
        status = AppointmentStatus(data['status'])
        result = AppointmentService.update_appointment_status(appointment_id, status)
        
        if result['success']:
            return jsonify({
                'success': True, 
                'appointment': result['appointment'].to_dict(),
                'message': 'Randevu durumu güncellendi'
            })
        else:
            return jsonify({'success': False, 'message': result['message']}), 400
    except ValueError:
        return jsonify({'success': False, 'message': 'Geçersiz durum değeri'}), 400

@api_bp.route('/appointments/<appointment_id>', methods=['DELETE'])
@jwt_required()
def delete_appointment(appointment_id):
    """Delete an appointment - requires authentication."""
    # Get the appointment
    appointment = AppointmentService.get_appointment_by_id(appointment_id)
    
    if not appointment:
        return jsonify({'success': False, 'message': 'Randevu bulunamadı'}), 404
    
    # Check user permission
    claims = get_jwt()
    user_role = claims.get('role')
    tenant_id = claims.get('tenant_id')
    
    # If not super admin or salon owner, ensure user only accesses their own salon's appointments
    if user_role not in [UserRole.SUPER_ADMIN.value, UserRole.SALON_OWNER.value]:
        return jsonify({'success': False, 'message': 'Bu işlemi gerçekleştirmek için yetkiniz yok'}), 403
        
    if user_role != UserRole.SUPER_ADMIN.value and appointment.salon_id != tenant_id:
        return jsonify({'success': False, 'message': 'Bu randevuyu silme izniniz yok'}), 403
    
    result = AppointmentService.delete_appointment(appointment_id)
    
    if result['success']:
        return jsonify({
            'success': True, 
            'message': 'Randevu silindi'
        })
    else:
        return jsonify({'success': False, 'message': result['message']}), 400