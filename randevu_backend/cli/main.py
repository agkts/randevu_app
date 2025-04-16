import click
import os
import sys

# Add the parent directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import create_app, db
from app.models import User, UserRole, Tenant
from datetime import datetime

# Create app context
app = create_app()
app.app_context().push()

@click.group()
def cli():
    """Randevu Super Admin CLI tool for managing the application."""
    pass

# Import commands from submodules
from cli.commands.tenant_commands import tenant
from cli.commands.user_commands import user
from cli.commands.report_commands import report

# Register command groups
cli.add_command(tenant)
cli.add_command(user)
cli.add_command(report)

@cli.command('setup-superadmin')
@click.argument('username')
@click.argument('email')
@click.argument('password')
@click.option('--first-name', default=None, help='First name of the super admin')
@click.option('--last-name', default=None, help='Last name of the super admin')
def setup_superadmin(username, email, password, first_name, last_name):
    """Set up a new super admin user."""
    try:
        existing_user = User.query.filter((User.username == username) | 
                                          (User.email == email)).first()
        
        if existing_user:
            click.echo('Error: Username or email already exists')
            return
            
        admin = User(
            username=username,
            email=email,
            first_name=first_name,
            last_name=last_name,
            role=UserRole.SUPER_ADMIN,
            is_active=True
        )
        admin.set_password(password)
        
        db.session.add(admin)
        db.session.commit()
        click.echo(f'Super admin created successfully with ID: {admin.id}')
    except Exception as e:
        db.session.rollback()
        click.echo(f'Error creating super admin: {str(e)}')

@cli.command('db-init')
def db_init():
    """Initialize the database tables."""
    try:
        db.create_all()
        click.echo('Database tables created successfully')
    except Exception as e:
        click.echo(f'Error initializing database: {str(e)}')

@cli.command('db-reset')
@click.confirmation_option(prompt='Are you sure you want to reset the database? This will delete all data!')
def db_reset():
    """Reset the database by dropping all tables and recreating them."""
    try:
        db.drop_all()
        db.create_all()
        click.echo('Database reset successfully')
    except Exception as e:
        click.echo(f'Error resetting database: {str(e)}')

if __name__ == '__main__':
    cli()