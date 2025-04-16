"""
Data validation utilities for the appointment system.
"""
import re
from typing import Optional, Dict, Any, Union
from datetime import datetime, date, time, timedelta
import phonenumbers
from email_validator import validate_email, EmailNotValidError

def validate_phone_number(phone: str, region: str = "TR") -> Dict[str, Any]:
    """
    Validates and formats a phone number.
    
    Args:
        phone: The phone number to validate
        region: The region code (default: TR for Turkey)
    
    Returns:
        Dict with keys:
        - valid (bool): Whether the phone is valid
        - formatted (str): Formatted phone number (if valid)
        - error (str): Error message (if invalid)
    """
    result = {"valid": False, "formatted": None, "error": None}
    
    if not phone:
        result["error"] = "Phone number is required"
        return result
        
    try:
        # Parse the phone number
        parsed_number = phonenumbers.parse(phone, region)
        
        # Check if it's valid
        if not phonenumbers.is_valid_number(parsed_number):
            result["error"] = "Invalid phone number format"
            return result
            
        # Format in international format
        formatted = phonenumbers.format_number(
            parsed_number, phonenumbers.PhoneNumberFormat.INTERNATIONAL
        )
        
        result["valid"] = True
        result["formatted"] = formatted
        return result
        
    except Exception as e:
        result["error"] = f"Invalid phone number: {str(e)}"
        return result

def validate_email_address(email: str) -> Dict[str, Any]:
    """
    Validates an email address.
    
    Args:
        email: The email address to validate
    
    Returns:
        Dict with keys:
        - valid (bool): Whether the email is valid
        - normalized (str): Normalized email (if valid)
        - error (str): Error message (if invalid)
    """
    result = {"valid": False, "normalized": None, "error": None}
    
    if not email:
        result["error"] = "Email address is required"
        return result
        
    try:
        # Validate and get normalized form
        validation = validate_email(email, check_deliverability=False)
        normalized = validation.normalized
        
        result["valid"] = True
        result["normalized"] = normalized
        return result
        
    except EmailNotValidError as e:
        result["error"] = str(e)
        return result

def validate_password(password: str, min_length: int = 8) -> Dict[str, Any]:
    """
    Validates a password.
    
    Args:
        password: The password to validate
        min_length: Minimum password length
    
    Returns:
        Dict with keys:
        - valid (bool): Whether the password is valid
        - errors (list): List of error messages
    """
    result = {"valid": True, "errors": []}
    
    if not password:
        result["valid"] = False
        result["errors"].append("Password is required")
        return result
    
    if len(password) < min_length:
        result["valid"] = False
        result["errors"].append(f"Password must be at least {min_length} characters long")
    
    if not re.search(r'[A-Z]', password):
        result["valid"] = False
        result["errors"].append("Password must contain at least one uppercase letter")
    
    if not re.search(r'[a-z]', password):
        result["valid"] = False
        result["errors"].append("Password must contain at least one lowercase letter")
    
    if not re.search(r'[0-9]', password):
        result["valid"] = False
        result["errors"].append("Password must contain at least one number")
    
    return result

def validate_required_fields(data: Dict[str, Any], required_fields: list) -> Dict[str, Any]:
    """
    Validates that all required fields are present and not empty.
    
    Args:
        data: Dictionary of field values
        required_fields: List of required field names
    
    Returns:
        Dict with keys:
        - valid (bool): Whether all required fields are valid
        - missing (list): List of missing field names
    """
    result = {"valid": True, "missing": []}
    
    for field in required_fields:
        if field not in data or data[field] is None or data[field] == "":
            result["valid"] = False
            result["missing"].append(field)
    
    return result

def validate_appointment_time(
    appointment_date: Union[str, date],
    start_time: Union[str, time],
    duration_minutes: int,
    working_hours: Dict[str, Any],
    existing_appointments: list = None
) -> Dict[str, Any]:
    """
    Validates an appointment time against working hours and existing appointments.
    
    Args:
        appointment_date: The appointment date
        start_time: The appointment start time
        duration_minutes: Duration of the appointment in minutes
        working_hours: Dict with working hours for each day
        existing_appointments: List of existing appointments
    
    Returns:
        Dict with keys:
        - valid (bool): Whether the appointment time is valid
        - errors (list): List of error messages
    """
    from .date_utils import parse_date, parse_time, add_minutes_to_time
    
    result = {"valid": True, "errors": []}
    
    if existing_appointments is None:
        existing_appointments = []
    
    # Convert string to date/time objects if needed
    if isinstance(appointment_date, str):
        appointment_date = parse_date(appointment_date)
        if not appointment_date:
            result["valid"] = False
            result["errors"].append("Invalid appointment date format")
            return result
    
    if isinstance(start_time, str):
        start_time = parse_time(start_time)
        if not start_time:
            result["valid"] = False
            result["errors"].append("Invalid appointment time format")
            return result
    
    # Calculate end time
    end_time = add_minutes_to_time(start_time, duration_minutes)
    
    # Get day of week
    day_of_week = appointment_date.strftime("%A").lower()
    
    # Check if salon is open on this day
    if day_of_week not in working_hours or not working_hours[day_of_week]["is_open"]:
        result["valid"] = False
        result["errors"].append(f"Salon is not open on {day_of_week}")
        return result
    
    # Check working hours
    day_hours = working_hours[day_of_week]
    opening_time = parse_time(day_hours["opening_time"])
    closing_time = parse_time(day_hours["closing_time"])
    
    if start_time < opening_time:
        result["valid"] = False
        result["errors"].append(f"Appointment starts before opening time ({day_hours['opening_time']})")
    
    if end_time > closing_time:
        result["valid"] = False
        result["errors"].append(f"Appointment ends after closing time ({day_hours['closing_time']})")
    
    # Check for conflicts with existing appointments
    for existing in existing_appointments:
        ex_date = existing.get("appointment_date")
        ex_start = existing.get("start_time")
        ex_end = existing.get("end_time")
        
        if ex_date == appointment_date and (
            (start_time < ex_end and end_time > ex_start)  # Overlapping times
        ):
            result["valid"] = False
            result["errors"].append("Appointment time conflicts with an existing appointment")
            break
    
    return result

def validate_slug(slug: str) -> Dict[str, Any]:
    """
    Validates a slug for use in URLs.
    
    Args:
        slug: The slug to validate
    
    Returns:
        Dict with keys:
        - valid (bool): Whether the slug is valid
        - error (str): Error message if invalid
    """
    result = {"valid": True, "error": None}
    
    if not slug:
        result["valid"] = False
        result["error"] = "Slug cannot be empty"
        return result
    
    # Check for valid slug format: lowercase letters, numbers, and hyphens only
    if not re.match(r'^[a-z0-9-]+$', slug):
        result["valid"] = False
        result["error"] = "Slug can only contain lowercase letters, numbers, and hyphens"
        
    # No consecutive hyphens
    if '--' in slug:
        result["valid"] = False
        result["error"] = "Slug cannot contain consecutive hyphens"
    
    # No starting/ending hyphens
    if slug.startswith('-') or slug.endswith('-'):
        result["valid"] = False
        result["error"] = "Slug cannot start or end with a hyphen"
    
    return result