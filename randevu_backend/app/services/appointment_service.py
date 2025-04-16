import string
import random
from datetime import datetime, time, timedelta
from ..models import Appointment, AppointmentStatus, Hairdresser, Service, Tenant
from ..extensions import db

class AppointmentService:
    """Service for appointment operations."""
    
    @staticmethod
    def get_appointment_by_id(appointment_id):
        """Get an appointment by ID."""
        return Appointment.query.get(appointment_id)
    
    @staticmethod
    def get_appointment_by_code(access_code):
        """Get an appointment by access code."""
        return Appointment.query.filter_by(access_code=access_code).first()
    
    @staticmethod
    def get_appointments_by_salon(salon_id, filters=None):
        """Get all appointments for a salon with optional filters."""
        query = Appointment.query.filter_by(salon_id=salon_id)
        
        if filters:
            # Filter by date
            if 'date' in filters:
                try:
                    date = datetime.fromisoformat(filters['date']).date()
                    query = query.filter(Appointment.appointment_date == date)
                except ValueError:
                    pass
            
            # Filter by hairdresser
            if 'hairdresser_id' in filters:
                query = query.filter_by(hairdresser_id=filters['hairdresser_id'])
            
            # Filter by status
            if 'status' in filters:
                query = query.filter_by(status=AppointmentStatus(filters['status']))
            
            # Filter by customer
            if 'customer_phone' in filters:
                query = query.filter_by(customer_phone=filters['customer_phone'])
            
            # Filter by future appointments
            if filters.get('future_only') == 'true':
                today = datetime.now().date()
                query = query.filter(Appointment.appointment_date >= today)
        
        return query.order_by(Appointment.appointment_date, Appointment.start_time).all()
    
    @staticmethod
    def get_appointments_by_hairdresser(hairdresser_id, start_date=None, end_date=None):
        """Get appointments for a hairdresser in a date range."""
        query = Appointment.query.filter_by(hairdresser_id=hairdresser_id)
        
        if start_date:
            query = query.filter(Appointment.appointment_date >= start_date)
            
        if end_date:
            query = query.filter(Appointment.appointment_date <= end_date)
            
        return query.order_by(Appointment.appointment_date, Appointment.start_time).all()
    
    @staticmethod
    def get_available_slots(salon_id, hairdresser_id, date_str):
        """Get available appointment slots for a hairdresser on a given date."""
        try:
            # Parse date
            selected_date = datetime.fromisoformat(date_str).date()
        except ValueError:
            return {'success': False, 'message': 'Geçersiz tarih formatı'}
        
        # Get hairdresser and check if exists
        hairdresser = Hairdresser.query.get(hairdresser_id)
        if not hairdresser:
            return {'success': False, 'message': 'Kuaför bulunamadı'}
            
        # Check if hairdresser works at this salon
        if hairdresser.salon_id != salon_id:
            return {'success': False, 'message': 'Kuaför bu salonda çalışmıyor'}
        
        # Check if hairdresser is active
        if not hairdresser.is_active:
            return {'success': False, 'message': 'Kuaför aktif değil'}
        
        # Get the day of week
        day_of_week = selected_date.strftime('%A').lower()
        
        # Get working hours for the selected day
        working_hours = hairdresser.working_schedule.get(day_of_week)
        if not working_hours or not working_hours.get('is_active'):
            return {'success': False, 'message': 'Kuaför bu günde çalışmıyor'}
            
        # Check if date is in holiday dates
        if hairdresser.holiday_dates and selected_date.isoformat() in hairdresser.holiday_dates:
            return {'success': False, 'message': 'Kuaför bu tarihte izinli'}
        
        # Get salon settings for default appointment duration
        salon = Tenant.query.get(salon_id)
        if not salon:
            return {'success': False, 'message': 'Salon bulunamadı'}
            
        default_duration = salon.settings.get('default_appointment_duration', 30)
        
        # Get start and end times
        open_time = datetime.strptime(working_hours.get('open_time', '09:00'), '%H:%M').time()
        close_time = datetime.strptime(working_hours.get('close_time', '18:00'), '%H:%M').time()
        
        # Get existing appointments for the selected date
        appointments = Appointment.query.filter(
            Appointment.hairdresser_id == hairdresser_id,
            Appointment.appointment_date == selected_date,
            Appointment.status != AppointmentStatus.CANCELED
        ).all()
        
        # Create list of busy slots
        busy_slots = []
        for appointment in appointments:
            busy_slots.append((appointment.start_time, appointment.end_time))
        
        # Generate available slots
        slots = []
        current_time = datetime.combine(selected_date, open_time)
        end_time = datetime.combine(selected_date, close_time)
        
        while current_time + timedelta(minutes=default_duration) <= end_time:
            slot_start = current_time.time()
            slot_end = (current_time + timedelta(minutes=default_duration)).time()
            
            # Check if slot overlaps with any busy slot
            is_busy = False
            for busy_start, busy_end in busy_slots:
                if not (slot_end <= busy_start or slot_start >= busy_end):
                    is_busy = True
                    break
            
            if not is_busy:
                slots.append({
                    'start_time': slot_start.strftime('%H:%M'),
                    'end_time': slot_end.strftime('%H:%M')
                })
            
            current_time += timedelta(minutes=default_duration)
        
        return {
            'success': True,
            'date': selected_date.isoformat(),
            'slots': slots,
            'hairdresser_id': hairdresser_id,
            'hairdresser_name': hairdresser.name
        }
    
    @staticmethod
    def create_appointment(data):
        """Create a new appointment."""
        try:
            # Check if hairdresser exists
            hairdresser = Hairdresser.query.get(data.get('hairdresser_id'))
            if not hairdresser:
                return {'success': False, 'message': 'Kuaför bulunamadı'}
            
            # Check if service exists
            service = Service.query.get(data.get('service_id'))
            if not service:
                return {'success': False, 'message': 'Hizmet bulunamadı'}
                
            # Parse date and times
            try:
                appointment_date = datetime.fromisoformat(data.get('date')).date()
                start_time = datetime.strptime(data.get('start_time'), '%H:%M').time()
                
                # Calculate end time based on service duration
                start_datetime = datetime.combine(appointment_date, start_time)
                end_datetime = start_datetime + timedelta(minutes=service.duration_minutes)
                end_time = end_datetime.time()
            except (ValueError, TypeError):
                return {'success': False, 'message': 'Geçersiz tarih veya saat formatı'}
            
            # Check for appointment conflicts
            conflicts = Appointment.query.filter(
                Appointment.hairdresser_id == data.get('hairdresser_id'),
                Appointment.appointment_date == appointment_date,
                Appointment.status != AppointmentStatus.CANCELED
            ).all()
            
            for appointment in conflicts:
                # Check for time overlap
                if not (end_time <= appointment.start_time or start_time >= appointment.end_time):
                    return {'success': False, 'message': 'Bu zaman diliminde başka bir randevu var'}
            
            # Generate access code
            access_code = AppointmentService._generate_access_code()
            
            # Create appointment
            appointment = Appointment(
                customer_name=data.get('customer_name'),
                customer_phone=data.get('customer_phone'),
                customer_email=data.get('customer_email', None),
                appointment_date=appointment_date,
                start_time=start_time,
                end_time=end_time,
                notes=data.get('notes'),
                status=AppointmentStatus.PENDING,
                access_code=access_code,
                salon_id=data.get('salon_id'),
                hairdresser_id=data.get('hairdresser_id'),
                service_id=data.get('service_id'),
                customer_id=data.get('customer_id')
            )
            
            db.session.add(appointment)
            db.session.commit()
            
            return {'success': True, 'appointment': appointment}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def update_appointment_status(appointment_id, status):
        """Update an appointment's status."""
        appointment = Appointment.query.get(appointment_id)
        
        if not appointment:
            return {'success': False, 'message': 'Randevu bulunamadı'}
            
        try:
            appointment.status = status
            appointment.updated_at = datetime.utcnow()
            db.session.commit()
            
            return {'success': True, 'appointment': appointment}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def delete_appointment(appointment_id):
        """Delete an appointment."""
        appointment = Appointment.query.get(appointment_id)
        
        if not appointment:
            return {'success': False, 'message': 'Randevu bulunamadı'}
            
        try:
            db.session.delete(appointment)
            db.session.commit()
            
            return {'success': True, 'message': 'Randevu silindi'}
        except Exception as e:
            db.session.rollback()
            return {'success': False, 'message': str(e)}
    
    @staticmethod
    def _generate_access_code(length=8):
        """Generate a unique access code for appointments."""
        chars = string.ascii_uppercase + string.digits
        code = ''.join(random.choices(chars, k=length))
        
        # Ensure uniqueness by checking database
        while Appointment.query.filter_by(access_code=code).first():
            code = ''.join(random.choices(chars, k=length))
            
        return code