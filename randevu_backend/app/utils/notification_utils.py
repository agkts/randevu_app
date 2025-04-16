"""
Notification utilities for the Randevu app.
This module contains functions for sending various types of notifications.
"""
import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Dict, Any, List, Optional

logger = logging.getLogger(__name__)

# Configuration should be loaded from environment variables in production
EMAIL_CONFIG = {
    "smtp_server": "smtp.example.com",
    "port": 587,
    "username": "notifications@example.com",
    "password": "your_password",  # Should be loaded from env vars
    "sender": "Randevu App <notifications@example.com>"
}

# Templates for different notification types
EMAIL_TEMPLATES = {
    "appointment_confirmation": """
        <h2>Appointment Confirmed!</h2>
        <p>Dear {customer_name},</p>
        <p>Your appointment has been confirmed with {salon_name} on {appointment_date} at {appointment_time}.</p>
        <p>Service: {service_name}</p>
        <p>Hairdresser: {hairdresser_name}</p>
        <p>Duration: {duration} minutes</p>
        <p>Thank you for using Randevu App!</p>
    """,
    "appointment_reminder": """
        <h2>Appointment Reminder</h2>
        <p>Dear {customer_name},</p>
        <p>This is a reminder of your upcoming appointment with {salon_name} on {appointment_date} at {appointment_time}.</p>
        <p>Service: {service_name}</p>
        <p>Hairdresser: {hairdresser_name}</p>
        <p>Duration: {duration} minutes</p>
        <p>Thank you for using Randevu App!</p>
    """,
    "appointment_cancellation": """
        <h2>Appointment Cancelled</h2>
        <p>Dear {customer_name},</p>
        <p>Your appointment with {salon_name} on {appointment_date} at {appointment_time} has been cancelled.</p>
        <p>If you did not request this cancellation, please contact us immediately.</p>
        <p>Thank you for using Randevu App!</p>
    """
}

def send_email(to_email: str, subject: str, body: str, is_html: bool = True) -> bool:
    """
    Send an email notification.
    
    Args:
        to_email: Recipient email address
        subject: Email subject
        body: Email body content
        is_html: Whether the email body is HTML format
        
    Returns:
        bool: True if email was sent successfully, False otherwise
    """
    try:
        msg = MIMEMultipart()
        msg['From'] = EMAIL_CONFIG["sender"]
        msg['To'] = to_email
        msg['Subject'] = subject
        
        if is_html:
            msg.attach(MIMEText(body, 'html'))
        else:
            msg.attach(MIMEText(body, 'plain'))
            
        server = smtplib.SMTP(EMAIL_CONFIG["smtp_server"], EMAIL_CONFIG["port"])
        server.starttls()
        server.login(EMAIL_CONFIG["username"], EMAIL_CONFIG["password"])
        server.send_message(msg)
        server.quit()
        
        logger.info(f"Email sent successfully to {to_email}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to send email: {str(e)}")
        return False

def send_sms_notification(phone_number: str, message: str) -> bool:
    """
    Send an SMS notification (implementation would depend on SMS provider).
    
    Args:
        phone_number: Recipient phone number
        message: SMS message content
        
    Returns:
        bool: True if SMS was sent successfully, False otherwise
    """
    # This is a placeholder - you would integrate with an SMS provider like Twilio
    try:
        # Simulating SMS sending
        logger.info(f"SMS would be sent to {phone_number}: {message}")
        return True
    except Exception as e:
        logger.error(f"Failed to send SMS: {str(e)}")
        return False

def send_push_notification(user_id: str, title: str, message: str, data: Optional[Dict[str, Any]] = None) -> bool:
    """
    Send a push notification (implementation would depend on push notification service).
    
    Args:
        user_id: User identifier for the notification recipient
        title: Notification title
        message: Notification message
        data: Additional data payload
        
    Returns:
        bool: True if push notification was sent successfully, False otherwise
    """
    # This is a placeholder - you would integrate with a service like Firebase Cloud Messaging
    try:
        # Simulating push notification
        payload = {
            "title": title,
            "body": message,
            "data": data or {}
        }
        logger.info(f"Push notification would be sent to user {user_id}: {payload}")
        return True
    except Exception as e:
        logger.error(f"Failed to send push notification: {str(e)}")
        return False

def send_appointment_confirmation(appointment_data: Dict[str, Any]) -> None:
    """
    Send appointment confirmation via multiple channels.
    
    Args:
        appointment_data: Dictionary containing appointment details
    """
    # Prepare notification content
    context = {
        "customer_name": appointment_data.get("customer_name", "Customer"),
        "salon_name": appointment_data.get("salon_name", ""),
        "appointment_date": appointment_data.get("date", ""),
        "appointment_time": appointment_data.get("time", ""),
        "service_name": appointment_data.get("service_name", ""),
        "hairdresser_name": appointment_data.get("hairdresser_name", ""),
        "duration": appointment_data.get("duration", "60")
    }
    
    # Format the email template with context
    email_body = EMAIL_TEMPLATES["appointment_confirmation"].format(**context)
    
    # Send notifications through different channels
    if email := appointment_data.get("email"):
        send_email(email, "Your Appointment is Confirmed", email_body)
        
    if phone := appointment_data.get("phone"):
        sms_msg = f"Your appointment with {context['salon_name']} on {context['appointment_date']} at {context['appointment_time']} is confirmed."
        send_sms_notification(phone, sms_msg)
    
    if user_id := appointment_data.get("user_id"):
        send_push_notification(
            user_id,
            "Appointment Confirmed",
            f"Your appointment with {context['salon_name']} is confirmed for {context['appointment_date']} at {context['appointment_time']}",
            {"appointment_id": appointment_data.get("id", "")}
        )

def send_appointment_reminder(appointment_data: Dict[str, Any]) -> None:
    """
    Send appointment reminder via multiple channels.
    
    Args:
        appointment_data: Dictionary containing appointment details
    """
    # Similar implementation to send_appointment_confirmation but with reminder template
    context = {
        "customer_name": appointment_data.get("customer_name", "Customer"),
        "salon_name": appointment_data.get("salon_name", ""),
        "appointment_date": appointment_data.get("date", ""),
        "appointment_time": appointment_data.get("time", ""),
        "service_name": appointment_data.get("service_name", ""),
        "hairdresser_name": appointment_data.get("hairdresser_name", ""),
        "duration": appointment_data.get("duration", "60")
    }
    
    email_body = EMAIL_TEMPLATES["appointment_reminder"].format(**context)
    
    if email := appointment_data.get("email"):
        send_email(email, "Reminder: Your Upcoming Appointment", email_body)
        
    if phone := appointment_data.get("phone"):
        sms_msg = f"Reminder: Your appointment with {context['salon_name']} is tomorrow at {context['appointment_time']}."
        send_sms_notification(phone, sms_msg)
    
    if user_id := appointment_data.get("user_id"):
        send_push_notification(
            user_id,
            "Appointment Reminder",
            f"Don't forget your appointment with {context['salon_name']} tomorrow at {context['appointment_time']}",
            {"appointment_id": appointment_data.get("id", "")}
        )

def send_appointment_cancellation(appointment_data: Dict[str, Any]) -> None:
    """
    Send appointment cancellation notification via multiple channels.
    
    Args:
        appointment_data: Dictionary containing appointment details
    """
    # Similar implementation using cancellation template
    context = {
        "customer_name": appointment_data.get("customer_name", "Customer"),
        "salon_name": appointment_data.get("salon_name", ""),
        "appointment_date": appointment_data.get("date", ""),
        "appointment_time": appointment_data.get("time", ""),
        "service_name": appointment_data.get("service_name", ""),
        "hairdresser_name": appointment_data.get("hairdresser_name", ""),
        "duration": appointment_data.get("duration", "60")
    }
    
    email_body = EMAIL_TEMPLATES["appointment_cancellation"].format(**context)
    
    if email := appointment_data.get("email"):
        send_email(email, "Your Appointment has been Cancelled", email_body)
        
    if phone := appointment_data.get("phone"):
        sms_msg = f"Your appointment with {context['salon_name']} on {context['appointment_date']} at {context['appointment_time']} has been cancelled."
        send_sms_notification(phone, sms_msg)
    
    if user_id := appointment_data.get("user_id"):
        send_push_notification(
            user_id,
            "Appointment Cancelled",
            f"Your appointment with {context['salon_name']} on {context['appointment_date']} has been cancelled",
            {"appointment_id": appointment_data.get("id", "")}
        )