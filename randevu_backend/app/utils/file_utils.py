"""
Utility functions for file operations in the appointment system.
"""
import os
import uuid
import mimetypes
from typing import Optional, Tuple, Dict, Any
from werkzeug.utils import secure_filename
from flask import current_app
from PIL import Image

# Allowed image extensions and MIME types
ALLOWED_IMAGE_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
ALLOWED_IMAGE_MIMETYPES = {'image/png', 'image/jpeg', 'image/gif', 'image/webp'}

def get_file_extension(filename: str) -> str:
    """Get the file extension from a filename."""
    return filename.rsplit('.', 1)[1].lower() if '.' in filename else ''

def is_allowed_image(filename: str, check_mimetype: bool = True) -> Tuple[bool, Optional[str]]:
    """
    Check if a file is an allowed image.
    
    Args:
        filename: The filename to check
        check_mimetype: Whether to also check the MIME type
        
    Returns:
        Tuple of (is_allowed, error_message)
    """
    if not filename:
        return False, "No file provided"
    
    extension = get_file_extension(filename)
    if not extension:
        return False, "File has no extension"
    
    if extension not in ALLOWED_IMAGE_EXTENSIONS:
        return False, f"File extension '{extension}' not allowed. Allowed extensions: {', '.join(ALLOWED_IMAGE_EXTENSIONS)}"
    
    if check_mimetype:
        mimetype = mimetypes.guess_type(filename)[0]
        if not mimetype or mimetype not in ALLOWED_IMAGE_MIMETYPES:
            return False, f"File type '{mimetype}' not allowed"
    
    return True, None

def generate_unique_filename(filename: str) -> str:
    """
    Generate a unique filename by adding a UUID.
    
    Args:
        filename: Original filename
        
    Returns:
        Unique filename
    """
    extension = get_file_extension(filename)
    safe_filename = secure_filename(filename)
    base_name = safe_filename.rsplit('.', 1)[0] if '.' in safe_filename else safe_filename
    
    # Create a unique filename with original name + uuid + extension
    unique_name = f"{base_name}_{uuid.uuid4().hex}.{extension}"
    
    return unique_name

def save_uploaded_file(file, folder: str = None, filename: str = None) -> Dict[str, Any]:
    """
    Save an uploaded file to the specified folder.
    
    Args:
        file: The file object from request.files
        folder: Subfolder within UPLOAD_FOLDER to save to
        filename: Custom filename (will be made secure and unique)
        
    Returns:
        Dict with save status and file info
    """
    result = {
        "success": False,
        "filepath": None,
        "filename": None,
        "error": None
    }
    
    if not file:
        result["error"] = "No file provided"
        return result
    
    try:
        # Get original filename and check if it's allowed
        original_filename = file.filename
        is_allowed, error = is_allowed_image(original_filename)
        
        if not is_allowed:
            result["error"] = error
            return result
        
        # Generate a unique, secure filename
        if not filename:
            secure_name = generate_unique_filename(original_filename)
        else:
            extension = get_file_extension(original_filename)
            secure_name = f"{secure_filename(filename)}.{extension}"
        
        # Set up the destination folder
        upload_folder = current_app.config["UPLOAD_FOLDER"]
        if folder:
            upload_folder = os.path.join(upload_folder, folder)
            os.makedirs(upload_folder, exist_ok=True)
        
        # Save the file
        filepath = os.path.join(upload_folder, secure_name)
        file.save(filepath)
        
        result["success"] = True
        result["filepath"] = filepath
        result["filename"] = secure_name
        
        return result
        
    except Exception as e:
        result["error"] = str(e)
        return result

def resize_image(
    image_path: str, 
    output_path: str = None, 
    max_width: int = 800, 
    max_height: int = 600,
    quality: int = 85
) -> Dict[str, Any]:
    """
    Resize an image while maintaining aspect ratio.
    
    Args:
        image_path: Path to the image file
        output_path: Path to save the resized image (defaults to original path)
        max_width: Maximum width of the resized image
        max_height: Maximum height of the resized image
        quality: JPEG compression quality (1-100)
        
    Returns:
        Dict with resize status and image info
    """
    result = {
        "success": False,
        "path": None,
        "width": None,
        "height": None,
        "error": None
    }
    
    if not output_path:
        output_path = image_path
    
    try:
        with Image.open(image_path) as img:
            # Original dimensions
            orig_width, orig_height = img.size
            
            # Calculate new dimensions while maintaining aspect ratio
            if orig_width > max_width or orig_height > max_height:
                ratio = min(max_width / orig_width, max_height / orig_height)
                new_width = int(orig_width * ratio)
                new_height = int(orig_height * ratio)
                img = img.resize((new_width, new_height), Image.LANCZOS)
            else:
                new_width, new_height = orig_width, orig_height
            
            # Save the resized image
            if img.mode == 'RGBA':
                # If image has alpha channel, convert to RGB with white background
                background = Image.new('RGB', img.size, (255, 255, 255))
                background.paste(img, mask=img.split()[3])
                background.save(output_path, 'JPEG', quality=quality)
            else:
                img.save(output_path, quality=quality)
            
            result["success"] = True
            result["path"] = output_path
            result["width"] = new_width
            result["height"] = new_height
            
            return result
            
    except Exception as e:
        result["error"] = str(e)
        return result

def delete_file(filepath: str) -> Dict[str, Any]:
    """
    Delete a file from the filesystem.
    
    Args:
        filepath: Path to the file to delete
        
    Returns:
        Dict with deletion status
    """
    result = {
        "success": False,
        "error": None
    }
    
    try:
        if not os.path.exists(filepath):
            result["error"] = "File not found"
            return result
        
        os.remove(filepath)
        result["success"] = True
        
        return result
        
    except Exception as e:
        result["error"] = str(e)
        return result