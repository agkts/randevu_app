"""
Date and time utility functions for the appointment system.
"""
from datetime import datetime, timedelta, date, time
from typing import Optional, List, Dict, Any, Union
import calendar
from dateutil import parser
from dateutil.relativedelta import relativedelta
import pytz

# Default timezone - change to your local timezone if needed
DEFAULT_TIMEZONE = 'Europe/Istanbul'

def get_current_time(timezone: str = DEFAULT_TIMEZONE) -> datetime:
    """Get current time in the specified timezone."""
    tz = pytz.timezone(timezone)
    return datetime.now(tz)

def format_datetime(dt: datetime, format_str: str = "%Y-%m-%d %H:%M:%S") -> str:
    """Format a datetime object to string."""
    if not dt:
        return ""
    return dt.strftime(format_str)

def format_date(dt: Union[datetime, date], format_str: str = '%Y-%m-%d') -> str:
    """
    Format a date or datetime object to string.
    
    Args:
        dt: Date or datetime object
        format_str: Format string
    
    Returns:
        Formatted date string
    """
    if not dt:
        return ""
    
    if isinstance(dt, datetime):
        return dt.strftime(format_str)
    elif isinstance(dt, date):
        return dt.strftime(format_str)
    else:
        return str(dt)

def format_time(t: Union[datetime, time], format_str: str = '%H:%M') -> str:
    """
    Format a time or datetime object to string.
    
    Args:
        t: Time or datetime object
        format_str: Format string
    
    Returns:
        Formatted time string
    """
    if not t:
        return ""
    
    if isinstance(t, datetime):
        return t.strftime(format_str)
    elif isinstance(t, time):
        return t.strftime(format_str)
    else:
        return str(t)

def parse_date(date_str: str, formats: List[str] = None) -> Optional[date]:
    """
    Parse a string into a date object.
    
    Args:
        date_str: String representation of a date
        formats: List of formats to try (e.g., ['%Y-%m-%d', '%d/%m/%Y'])
    
    Returns:
        date object or None if parsing fails
    """
    if not date_str:
        return None
        
    # Try dateutil parser first (flexible format detection)
    try:
        return parser.parse(date_str).date()
    except (ValueError, TypeError):
        pass
    
    # Try specified formats
    if formats:
        for fmt in formats:
            try:
                return datetime.strptime(date_str, fmt).date()
            except (ValueError, TypeError):
                continue
    
    # Default formats to try
    default_formats = ['%Y-%m-%d', '%d/%m/%Y', '%d.%m.%Y', '%m/%d/%Y', '%d-%m-%Y']
    for fmt in default_formats:
        try:
            return datetime.strptime(date_str, fmt).date()
        except (ValueError, TypeError):
            continue
    
    return None

def parse_time(time_str: str, formats: List[str] = None) -> Optional[time]:
    """
    Parse a string into a time object.
    
    Args:
        time_str: String representation of a time
        formats: List of formats to try (e.g., ['%H:%M', '%I:%M %p'])
    
    Returns:
        time object or None if parsing fails
    """
    if not time_str:
        return None
    
    # Try dateutil parser first
    try:
        return parser.parse(time_str).time()
    except (ValueError, TypeError):
        pass
    
    # Try specified formats
    if formats:
        for fmt in formats:
            try:
                return datetime.strptime(time_str, fmt).time()
            except (ValueError, TypeError):
                continue
    
    # Default formats to try
    default_formats = ['%H:%M', '%H:%M:%S', '%I:%M %p', '%I:%M%p']
    for fmt in default_formats:
        try:
            return datetime.strptime(time_str, fmt).time()
        except (ValueError, TypeError):
            continue
    
    return None

def add_days(dt: Union[datetime, date], days: int) -> Union[datetime, date]:
    """
    Add days to a date or datetime.
    
    Args:
        dt: Date or datetime object
        days: Number of days to add (can be negative)
    
    Returns:
        New date or datetime with days added
    """
    if not dt:
        return None
    
    return dt + timedelta(days=days)

def add_months(dt: Union[datetime, date], months: int) -> Union[datetime, date]:
    """
    Add months to a date or datetime.
    
    Args:
        dt: Date or datetime object
        months: Number of months to add (can be negative)
    
    Returns:
        New date or datetime with months added
    """
    if not dt:
        return None
    
    return dt + relativedelta(months=months)

def add_minutes_to_time(t: time, minutes: int) -> time:
    """
    Add minutes to a time object.
    
    Args:
        t: Time object
        minutes: Number of minutes to add (can be negative)
    
    Returns:
        New time with minutes added
    """
    if not t:
        return None
    
    # Convert time to datetime to use timedelta, then convert back
    dt = datetime.combine(date.today(), t)
    dt = dt + timedelta(minutes=minutes)
    return dt.time()

def get_day_of_week(dt: Union[datetime, date]) -> int:
    """
    Get day of week as an integer (0=Monday, 6=Sunday).
    
    Args:
        dt: Date or datetime object
    
    Returns:
        Day of week integer
    """
    if not dt:
        return None
    
    # The datetime.weekday() returns 0 for Monday through 6 for Sunday
    return dt.weekday()

def get_day_name(dt: Union[datetime, date], short: bool = False) -> str:
    """
    Get day name for a date or datetime.
    
    Args:
        dt: Date or datetime object
        short: Whether to return short name (e.g., "Mon" vs "Monday")
    
    Returns:
        Day name string
    """
    if not dt:
        return ""
    
    day_idx = get_day_of_week(dt)
    day_names = calendar.day_name if not short else calendar.day_abbr
    return day_names[day_idx]

def get_month_name(dt: Union[datetime, date], short: bool = False) -> str:
    """
    Get month name for a date or datetime.
    
    Args:
        dt: Date or datetime object
        short: Whether to return short name (e.g., "Jan" vs "January")
    
    Returns:
        Month name string
    """
    if not dt:
        return ""
    
    month_idx = dt.month - 1  # zero-based index
    month_names = calendar.month_name if not short else calendar.month_abbr
    return month_names[month_idx + 1]  # month_name has empty string at index 0

def get_week_start(dt: Union[datetime, date], start_day_idx: int = 0) -> date:
    """
    Get the first day of the week containing the given date.
    
    Args:
        dt: Date or datetime object
        start_day_idx: Day of week to consider as first day (0=Monday, 6=Sunday)
    
    Returns:
        Date object representing first day of week
    """
    if not dt:
        return None
    
    if isinstance(dt, datetime):
        dt = dt.date()
    
    days_to_sub = (dt.weekday() - start_day_idx) % 7
    return dt - timedelta(days=days_to_sub)

def get_week_end(dt: Union[datetime, date], start_day_idx: int = 0) -> date:
    """
    Get the last day of the week containing the given date.
    
    Args:
        dt: Date or datetime object
        start_day_idx: Day of week to consider as first day (0=Monday, 6=Sunday)
    
    Returns:
        Date object representing last day of week
    """
    start_date = get_week_start(dt, start_day_idx)
    return start_date + timedelta(days=6)

def get_month_start(dt: Union[datetime, date]) -> date:
    """
    Get the first day of the month containing the given date.
    
    Args:
        dt: Date or datetime object
    
    Returns:
        Date object representing first day of month
    """
    if not dt:
        return None
    
    if isinstance(dt, datetime):
        return date(dt.year, dt.month, 1)
    else:
        return date(dt.year, dt.month, 1)

def get_month_end(dt: Union[datetime, date]) -> date:
    """
    Get the last day of the month containing the given date.
    
    Args:
        dt: Date or datetime object
    
    Returns:
        Date object representing last day of month
    """
    if not dt:
        return None
    
    # Get first day of next month and subtract one day
    if dt.month == 12:
        next_month = date(dt.year + 1, 1, 1)
    else:
        next_month = date(dt.year, dt.month + 1, 1)
    
    return next_month - timedelta(days=1)

def get_time_slots(
    start_time: time,
    end_time: time,
    duration_minutes: int,
    buffer_minutes: int = 0
) -> List[Dict[str, time]]:
    """
    Generate time slots between start and end times.
    
    Args:
        start_time: Start time
        end_time: End time
        duration_minutes: Duration of each slot in minutes
        buffer_minutes: Buffer time between slots in minutes
    
    Returns:
        List of dicts with start and end times for each slot
    """
    if not start_time or not end_time or duration_minutes <= 0:
        return []
    
    slots = []
    slot_start = start_time
    
    # Use a reference date for calculations
    ref_date = date.today()
    dt_start = datetime.combine(ref_date, start_time)
    dt_end = datetime.combine(ref_date, end_time)
    
    # Generate slots
    while True:
        dt_slot_start = datetime.combine(ref_date, slot_start)
        dt_slot_end = dt_slot_start + timedelta(minutes=duration_minutes)
        
        # If the end time exceeds the overall end time, we're done
        if dt_slot_end > dt_end:
            break
        
        slots.append({
            "start": dt_slot_start.time(),
            "end": dt_slot_end.time()
        })
        
        # Move to next slot start time
        dt_slot_start = dt_slot_end + timedelta(minutes=buffer_minutes)
        slot_start = dt_slot_start.time()
    
    return slots

def is_time_overlapping(
    start1: time,
    end1: time,
    start2: time,
    end2: time
) -> bool:
    """
    Check if two time ranges overlap.
    
    Args:
        start1: Start time of first range
        end1: End time of first range
        start2: Start time of second range
        end2: End time of second range
    
    Returns:
        True if time ranges overlap, False otherwise
    """
    return start1 < end2 and start2 < end1

def calculate_duration_minutes(start_time: time, end_time: time) -> int:
    """
    Calculate duration in minutes between two time objects.
    
    Args:
        start_time: Start time
        end_time: End time
    
    Returns:
        Duration in minutes (negative if end_time is before start_time)
    """
    if not start_time or not end_time:
        return 0
    
    # Convert to datetime using the same date for calculation
    ref_date = date.today()
    dt_start = datetime.combine(ref_date, start_time)
    dt_end = datetime.combine(ref_date, end_time)
    
    # If end time is earlier than start time, assume it's the next day
    if dt_end < dt_start:
        dt_end += timedelta(days=1)
    
    # Calculate difference in minutes
    diff = dt_end - dt_start
    return int(diff.total_seconds() / 60)

def get_date_range(
    start_date: date,
    end_date: date
) -> List[date]:
    """
    Generate a list of dates between start_date and end_date (inclusive).
    
    Args:
        start_date: Start date
        end_date: End date
    
    Returns:
        List of dates
    """
    if not start_date or not end_date or start_date > end_date:
        return []
    
    num_days = (end_date - start_date).days + 1
    return [start_date + timedelta(days=i) for i in range(num_days)]

def is_time_slot_available(
    start_time: time, 
    duration_minutes: int,
    existing_appointments: List[Dict[str, time]]
) -> bool:
    """Check if a time slot is available based on existing appointments."""
    end_time = add_minutes_to_time(start_time, duration_minutes)
    
    for appt in existing_appointments:
        appt_start = appt.get('start_time')
        appt_end = appt.get('end_time')
        
        # Check for overlap
        if (start_time < appt_end and end_time > appt_start):
            return False
    
    return True

def generate_available_slots(
    start_time: time,
    end_time: time, 
    duration_minutes: int, 
    buffer_minutes: int = 0,
    existing_appointments: List[Dict[str, time]] = None
) -> List[Dict[str, time]]:
    """
    Generate available time slots for bookings.
    
    Args:
        start_time: Start of working hours
        end_time: End of working hours
        duration_minutes: Duration of each appointment in minutes
        buffer_minutes: Buffer time between appointments in minutes
        existing_appointments: List of existing appointments with start_time and end_time
    
    Returns:
        List of available time slots with start_time and end_time
    """
    if existing_appointments is None:
        existing_appointments = []
        
    available_slots = []
    current = start_time
    total_slot_minutes = duration_minutes + buffer_minutes
    
    # Convert to datetime for easier calculation
    dummy_date = date(1, 1, 1)
    dt_start = datetime.combine(dummy_date, start_time)
    dt_end = datetime.combine(dummy_date, end_time)
    dt_current = dt_start
    
    while dt_current + timedelta(minutes=duration_minutes) <= dt_end:
        slot_start_time = dt_current.time()
        slot_end_time = (dt_current + timedelta(minutes=duration_minutes)).time()
        
        if is_time_slot_available(slot_start_time, duration_minutes, existing_appointments):
            available_slots.append({
                'start_time': slot_start_time,
                'end_time': slot_end_time
            })
        
        dt_current += timedelta(minutes=total_slot_minutes)
    
    return available_slots