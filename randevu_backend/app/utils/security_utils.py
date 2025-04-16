"""
Security-related utility functions for the appointment system.
"""
import secrets
import string
from typing import Dict, Any, Optional
import re
from datetime import datetime, timedelta
from flask import current_app
from flask_jwt_extended import create_access_token, create_refresh_token

def generate_random_string(length: int = 12, 
                          include_uppercase: bool = True,
                          include_lowercase: bool = True,
                          include_digits: bool = True,
                          include_special: bool = False) -> str:
    """
    Generate a secure random string.
    
    Args:
        length: Length of the string to generate
        include_uppercase: Include uppercase letters
        include_lowercase: Include lowercase letters
        include_digits: Include digits
        include_special: Include special characters
        
    Returns:
        A random string
    """
    character_set = ""
    
    if include_uppercase:
        character_set += string.ascii_uppercase
    if include_lowercase:
        character_set += string.ascii_lowercase
    if include_digits:
        character_set += string.digits
    if include_special:
        character_set += string.punctuation
    
    if not character_set:
        character_set = string.ascii_letters + string.digits
    
    return ''.join(secrets.choice(character_set) for _ in range(length))

def generate_confirmation_token(length: int = 32) -> str:
    """
    Generate a secure confirmation token.
    
    Args:
        length: Length of the token to generate
        
    Returns:
        A secure confirmation token
    """
    return secrets.token_urlsafe(length)

def generate_password_reset_token() -> str:
    """
    Generate a secure password reset token.
    
    Returns:
        A secure password reset token
    """
    return secrets.token_urlsafe(32)

def create_user_tokens(user_id: int, additional_claims: Dict = None) -> Dict[str, str]:
    """
    Create JWT access and refresh tokens for a user.
    
    Args:
        user_id: The user ID to create tokens for
        additional_claims: Additional claims to include in the tokens
        
    Returns:
        Dict containing access_token and refresh_token
    """
    if additional_claims is None:
        additional_claims = {}
        
    # Add user_id to claims
    identity_claim = {"sub": user_id}
    identity_claim.update(additional_claims)
    
    # Create tokens
    access_token = create_access_token(identity=user_id, additional_claims=additional_claims)
    refresh_token = create_refresh_token(identity=user_id, additional_claims=additional_claims)
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token
    }

def sanitize_html(text: str) -> str:
    """
    Remove HTML tags from text.
    
    Args:
        text: The text to sanitize
        
    Returns:
        Sanitized text with HTML removed
    """
    if not text:
        return ""
        
    # Remove HTML tags
    clean_text = re.sub(r'<[^>]*>', '', text)
    
    # Replace multiple whitespace with a single space
    clean_text = re.sub(r'\s+', ' ', clean_text).strip()
    
    return clean_text

def mask_sensitive_data(data: str, show_first: int = 0, show_last: int = 4) -> str:
    """
    Mask sensitive data like phone numbers, credit cards, etc.
    
    Args:
        data: The sensitive data to mask
        show_first: Number of characters to show at the beginning
        show_last: Number of characters to show at the end
        
    Returns:
        Masked string
    """
    if not data:
        return ""
    
    data = str(data)
    data_len = len(data)
    
    if data_len <= show_first + show_last:
        # If the data is too short, just mask the middle part
        return data if data_len <= 4 else data[0] + '*' * (data_len - 2) + data[-1]
    
    visible_first = data[:show_first] if show_first > 0 else ""
    visible_last = data[-show_last:] if show_last > 0 else ""
    mask_length = data_len - show_first - show_last
    
    return visible_first + '*' * mask_length + visible_last

def check_password_strength(password: str) -> Dict[str, Any]:
    """
    Check password strength.
    
    Args:
        password: The password to check
        
    Returns:
        Dict with strength score and feedback
    """
    result = {
        "score": 0,  # 0 (very weak) to 4 (very strong)
        "feedback": []
    }
    
    if not password:
        result["feedback"].append("Password is empty")
        return result
    
    # Check length
    if len(password) < 8:
        result["feedback"].append("Password is too short (less than 8 characters)")
    elif len(password) >= 12:
        result["score"] += 1
    
    # Check for uppercase
    if re.search(r'[A-Z]', password):
        result["score"] += 1
    else:
        result["feedback"].append("Password should include uppercase letters")
    
    # Check for lowercase
    if re.search(r'[a-z]', password):
        result["score"] += 1
    else:
        result["feedback"].append("Password should include lowercase letters")
    
    # Check for digits
    if re.search(r'[0-9]', password):
        result["score"] += 1
    else:
        result["feedback"].append("Password should include numbers")
    
    # Check for special characters
    if re.search(r'[!@#$%^&*()_+\-=\[\]{};:\'",.<>?/\\|`~]', password):
        result["score"] += 1
    else:
        result["feedback"].append("Password should include special characters")
    
    # Check for common patterns
    if re.search(r'123|abc|qwerty|password|admin|welcome', password.lower()):
        result["score"] = max(0, result["score"] - 1)
        result["feedback"].append("Password contains common patterns")
    
    # Cap the score at 4
    result["score"] = min(4, result["score"])
    
    # Add strength description
    strength_descriptions = [
        "Very weak", "Weak", "Medium", "Strong", "Very strong"
    ]
    result["strength"] = strength_descriptions[result["score"]]
    
    return result

def generate_salon_invite_token(salon_id: int, expires_in_days: int = 7) -> Dict[str, Any]:
    """
    Generate a token for inviting staff to join a salon.
    
    Args:
        salon_id: ID of the salon
        expires_in_days: Token expiration in days
        
    Returns:
        Dict with token and expiry info
    """
    # Generate a secure token
    token = secrets.token_urlsafe(32)
    
    # Set expiration date
    expiry = datetime.utcnow() + timedelta(days=expires_in_days)
    
    return {
        "token": token,
        "expires_at": expiry,
        "salon_id": salon_id
    }