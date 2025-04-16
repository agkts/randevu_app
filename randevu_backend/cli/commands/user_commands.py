import click
from app import db
from app.models import User, UserRole, Tenant

@click.group()
def user():
    """User management commands."""
    pass

@user.command('create')
@click.argument('username')
@click.argument('email')
@click.argument('password')
@click.option('--role', default='customer', type=click.Choice(['customer', 'hairdresser', 'salon_owner', 'super_admin']), help='User role')
@click.option('--first-name', default=None, help='First name of the user')
@click.option('--last-name', default=None, help='Last name of the user')
@click.option('--phone', default=None, help='Phone number')
@click.option('--tenant-id', default=None, help='Tenant ID if user belongs to a salon')
def create_user(username, email, password, role, first_name, last_name, phone, tenant_id):
    """Create a new user."""
    try:
        # Check if username or email already exists
        if User.query.filter_by(username=username).first():
            click.echo('Error: Username already exists')
            return
            
        if User.query.filter_by(email=email).first():
            click.echo('Error: Email already exists')
            return
            
        # Check if tenant exists if tenant_id provided
        if tenant_id:
            tenant = Tenant.query.get(tenant_id)
            if not tenant:
                click.echo('Error: Tenant not found')
                return
        
        # Create user
        user = User(
            username=username,
            email=email,
            first_name=first_name,
            last_name=last_name,
            phone=phone,
            role=UserRole(role),
            tenant_id=tenant_id,
            salon_id=tenant_id,
            is_active=True
        )
        user.set_password(password)
        
        db.session.add(user)
        db.session.commit()
        
        click.echo(f'User created successfully with ID: {user.id}')
    except Exception as e:
        db.session.rollback()
        click.echo(f'Error creating user: {str(e)}')

@user.command('list')
@click.option('--role', default=None, help='Filter by role (customer, hairdresser, salon_owner, super_admin)')
@click.option('--tenant-id', default=None, help='Filter by tenant ID')
@click.option('--active-only/--all', default=True, help='Show only active users')
def list_users(role, tenant_id, active_only):
    """List users with optional filtering."""
    query = User.query
    
    # Apply filters
    if role:
        try:
            role_enum = UserRole(role)
            query = query.filter_by(role=role_enum)
        except ValueError:
            click.echo(f'Error: Invalid role: {role}')
            return
    
    if tenant_id:
        query = query.filter_by(tenant_id=tenant_id)
        
    if active_only:
        query = query.filter_by(is_active=True)
    
    users = query.all()
    
    if not users:
        click.echo('No users found matching the criteria')
        return
    
    click.echo(f"Total users: {len(users)}")
    click.echo("--------------------------------------------------")
    for user in users:
        tenant = Tenant.query.get(user.tenant_id) if user.tenant_id else None
        click.echo(f"ID: {user.id}")
        click.echo(f"Username: {user.username}")
        click.echo(f"Email: {user.email}")
        click.echo(f"Name: {user.first_name or ''} {user.last_name or ''}")
        click.echo(f"Role: {user.role.value}")
        click.echo(f"Tenant: {tenant.name if tenant else 'None'}")
        click.echo(f"Active: {'Yes' if user.is_active else 'No'}")
        click.echo(f"Created: {user.created_at}")
        click.echo("--------------------------------------------------")

@user.command('show')
@click.argument('user_id')
def show_user(user_id):
    """Show detailed information about a user."""
    user = User.query.get(user_id)
    
    if not user:
        click.echo('User not found')
        return
    
    tenant = Tenant.query.get(user.tenant_id) if user.tenant_id else None
    
    click.echo("--------------------------------------------------")
    click.echo(f"ID: {user.id}")
    click.echo(f"Username: {user.username}")
    click.echo(f"Email: {user.email}")
    click.echo(f"First Name: {user.first_name or 'Not set'}")
    click.echo(f"Last Name: {user.last_name or 'Not set'}")
    click.echo(f"Phone: {user.phone or 'Not set'}")
    click.echo(f"Role: {user.role.value}")
    click.echo(f"Tenant ID: {user.tenant_id or 'Not set'}")
    click.echo(f"Tenant Name: {tenant.name if tenant else 'Not set'}")
    click.echo(f"Active: {'Yes' if user.is_active else 'No'}")
    click.echo(f"Created: {user.created_at}")
    click.echo(f"Updated: {user.updated_at}")
    click.echo("--------------------------------------------------")

@user.command('update')
@click.argument('user_id')
@click.option('--username', default=None, help='New username')
@click.option('--email', default=None, help='New email')
@click.option('--password', default=None, help='New password')
@click.option('--first-name', default=None, help='New first name')
@click.option('--last-name', default=None, help='New last name')
@click.option('--phone', default=None, help='New phone number')
@click.option('--role', default=None, type=click.Choice(['customer', 'hairdresser', 'salon_owner', 'super_admin']), help='New role')
@click.option('--tenant-id', default=None, help='New tenant ID')
@click.option('--active/--inactive', default=None, help='Set user active status')
def update_user(user_id, username, email, password, first_name, last_name, phone, role, tenant_id, active):
    """Update a user's information."""
    user = User.query.get(user_id)
    
    if not user:
        click.echo('User not found')
        return
    
    try:
        # Update fields if provided
        if username and username != user.username:
            # Check if username already exists
            if User.query.filter_by(username=username).first():
                click.echo('Error: Username already exists')
                return
            user.username = username
            
        if email and email != user.email:
            # Check if email already exists
            if User.query.filter_by(email=email).first():
                click.echo('Error: Email already exists')
                return
            user.email = email
            
        if password:
            user.set_password(password)
            
        if first_name:
            user.first_name = first_name
            
        if last_name:
            user.last_name = last_name
            
        if phone:
            user.phone = phone
            
        if role:
            user.role = UserRole(role)
            
        if tenant_id:
            # Check if tenant exists
            tenant = Tenant.query.get(tenant_id)
            if not tenant:
                click.echo('Error: Tenant not found')
                return
            user.tenant_id = tenant_id
            user.salon_id = tenant_id
            
        if active is not None:
            user.is_active = active
        
        db.session.commit()
        click.echo(f'User {user.username} updated successfully')
    except Exception as e:
        db.session.rollback()
        click.echo(f'Error updating user: {str(e)}')

@user.command('delete')
@click.argument('user_id')
@click.confirmation_option(prompt='Are you sure you want to delete this user?')
def delete_user(user_id):
    """Delete a user."""
    user = User.query.get(user_id)
    
    if not user:
        click.echo('User not found')
        return
    
    # Prevent deleting the last super admin
    if user.role == UserRole.SUPER_ADMIN:
        super_admins = User.query.filter_by(role=UserRole.SUPER_ADMIN).all()
        if len(super_admins) <= 1:
            click.echo('Error: Cannot delete the last super admin')
            return
    
    try:
        # Get the username for confirmation message
        username = user.username
        
        # Delete the user
        db.session.delete(user)
        db.session.commit()
        
        click.echo(f'User {username} deleted successfully')
    except Exception as e:
        db.session.rollback()
        click.echo(f'Error deleting user: {str(e)}')

@user.command('reset-password')
@click.argument('user_id')
@click.argument('new_password')
def reset_password(user_id, new_password):
    """Reset a user's password."""
    user = User.query.get(user_id)
    
    if not user:
        click.echo('User not found')
        return
    
    try:
        user.set_password(new_password)
        db.session.commit()
        click.echo(f'Password reset successfully for user: {user.username}')
    except Exception as e:
        db.session.rollback()
        click.echo(f'Error resetting password: {str(e)}')