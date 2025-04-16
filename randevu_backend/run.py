from app import create_app
from app.models import User, UserRole

app = create_app()

@app.before_first_request
def create_super_admin():
    """Create a super admin user if none exists."""
    from app.extensions import db
    
    # Check if there's at least one super admin
    super_admin = User.query.filter_by(role=UserRole.SUPER_ADMIN).first()
    
    if not super_admin:
        # Create default super admin
        admin = User(
            username='admin',
            email='admin@example.com',
            first_name='Admin',
            last_name='User',
            role=UserRole.SUPER_ADMIN,
            is_active=True
        )
        admin.set_password('admin123')  # Default password, change immediately!
        
        db.session.add(admin)
        db.session.commit()
        print('Default super admin created. Please change the password immediately!')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)