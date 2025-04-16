import click
import json
from datetime import datetime
from app import db
from app.models import Tenant, User, UserRole

@click.group()
def tenant():
    """Tenant (salon) management commands."""
    pass

@tenant.command('create')
@click.argument('name')
@click.argument('slug')
@click.argument('owner_email')
@click.option('--plan', default='standard', help='Subscription plan: standard, premium, or enterprise')
@click.option('--start-date', default=None, help='Subscription start date (YYYY-MM-DD)')
@click.option('--end-date', default=None, help='Subscription end date (YYYY-MM-DD)')
@click.option('--phone', default=None, help='Salon phone number')
@click.option('--address', default=None, help='Salon address')
@click.option('--website', default=None, help='Salon website')
def create_tenant(name, slug, owner_email, plan, start_date, end_date, phone, address, website):
    """Create a new tenant (salon)."""
    # Check if owner exists
    owner = User.query.filter_by(email=owner_email).first()
    if not owner:
        click.echo('Error: Owner with this email not found')
        return
    
    # Check if slug already exists
    if Tenant.query.filter_by(slug=slug).first():
        click.echo('Error: Salon slug already exists')
        return
    
    # Parse dates if provided
    start_date_obj = None
    end_date_obj = None
    
    if start_date:
        try:
            start_date_obj = datetime.strptime(start_date, '%Y-%m-%d')
        except ValueError:
            click.echo('Error: Invalid start date format. Use YYYY-MM-DD')
            return
            
    if end_date:
        try:
            end_date_obj = datetime.strptime(end_date, '%Y-%m-%d')
        except ValueError:
            click.echo('Error: Invalid end date format. Use YYYY-MM-DD')
            return
    
    # Create tenant
    try:
        new_tenant = Tenant(
            name=name,
            slug=slug,
            owner_id=owner.id,
            subscription_plan=plan,
            subscription_start_date=start_date_obj,
            subscription_end_date=end_date_obj,
            phone=phone,
            address=address,
            website=website,
            email=owner.email,
            settings=Tenant.create_default_settings(),
            sms_settings=Tenant.create_default_sms_settings(),
            working_schedule=Tenant.create_default_schedule()
        )
        
        # Update owner with tenant_id and role
        owner.tenant_id = new_tenant.id
        owner.salon_id = new_tenant.id
        owner.role = UserRole.SALON_OWNER
        
        db.session.add(new_tenant)
        db.session.commit()
        click.echo(f'Tenant created successfully with ID: {new_tenant.id}')
    except Exception as e:
        db.session.rollback()
        click.echo(f'Error creating tenant: {str(e)}')

@tenant.command('list')
@click.option('--active-only/--all', default=True, help='Show only active tenants or all')
@click.option('--plan', default=None, help='Filter by subscription plan')
def list_tenants(active_only, plan):
    """List all tenants with optional filtering."""
    query = Tenant.query
    
    if active_only:
        query = query.filter_by(is_active=True)
        
    if plan:
        query = query.filter_by(subscription_plan=plan)
    
    tenants = query.all()
    
    if not tenants:
        click.echo('No tenants found matching the criteria')
        return
        
    click.echo(f"Total tenants: {len(tenants)}")
    click.echo("--------------------------------------------------")
    for tenant in tenants:
        owner = User.query.get(tenant.owner_id) if tenant.owner_id else None
        owner_name = f"{owner.first_name} {owner.last_name}" if owner else "No owner"
        click.echo(f"ID: {tenant.id}")
        click.echo(f"Name: {tenant.name}")
        click.echo(f"Slug: {tenant.slug}")
        click.echo(f"Owner: {owner_name}")
        click.echo(f"Plan: {tenant.subscription_plan}")
        click.echo(f"Active: {'Yes' if tenant.is_active else 'No'}")
        click.echo(f"Created: {tenant.created_at}")
        click.echo("--------------------------------------------------")

@tenant.command('show')
@click.argument('tenant_id')
def show_tenant(tenant_id):
    """Show detailed information about a tenant."""
    tenant = Tenant.query.get(tenant_id)
    
    if not tenant:
        click.echo('Tenant not found')
        return
        
    owner = User.query.get(tenant.owner_id)
    owner_name = f"{owner.first_name} {owner.last_name}" if owner else "No owner"
    
    click.echo("--------------------------------------------------")
    click.echo(f"ID: {tenant.id}")
    click.echo(f"Name: {tenant.name}")
    click.echo(f"Slug: {tenant.slug}")
    click.echo(f"Owner: {owner_name} ({owner.email if owner else 'N/A'})")
    click.echo(f"Email: {tenant.email}")
    click.echo(f"Phone: {tenant.phone}")
    click.echo(f"Address: {tenant.address}")
    click.echo(f"Website: {tenant.website}")
    click.echo(f"Logo URL: {tenant.logo_url}")
    click.echo(f"Active: {'Yes' if tenant.is_active else 'No'}")
    click.echo(f"Plan: {tenant.subscription_plan}")
    
    if tenant.subscription_start_date:
        click.echo(f"Subscription Start: {tenant.subscription_start_date}")
    
    if tenant.subscription_end_date:
        click.echo(f"Subscription End: {tenant.subscription_end_date}")
    
    click.echo(f"Created At: {tenant.created_at}")
    click.echo(f"Updated At: {tenant.updated_at}")
    
    click.echo("\nSettings:")
    click.echo(json.dumps(tenant.settings, indent=2))
    
    click.echo("\nSMS Settings:")
    click.echo(json.dumps(tenant.sms_settings, indent=2))
    
    click.echo("\nWorking Schedule:")
    click.echo(json.dumps(tenant.working_schedule, indent=2))
    click.echo("--------------------------------------------------")

@tenant.command('update')
@click.argument('tenant_id')
@click.option('--name', default=None, help='New tenant name')
@click.option('--plan', default=None, help='New subscription plan')
@click.option('--start-date', default=None, help='New subscription start date (YYYY-MM-DD)')
@click.option('--end-date', default=None, help='New subscription end date (YYYY-MM-DD)')
@click.option('--active/--inactive', default=None, help='Set tenant active status')
@click.option('--phone', default=None, help='New phone number')
@click.option('--email', default=None, help='New email address')
@click.option('--address', default=None, help='New address')
@click.option('--website', default=None, help='New website')
def update_tenant(tenant_id, name, plan, start_date, end_date, active, phone, email, address, website):
    """Update a tenant's information."""
    tenant = Tenant.query.get(tenant_id)
    
    if not tenant:
        click.echo('Tenant not found')
        return
    
    # Parse dates if provided
    start_date_obj = None
    end_date_obj = None
    
    if start_date:
        try:
            start_date_obj = datetime.strptime(start_date, '%Y-%m-%d')
        except ValueError:
            click.echo('Error: Invalid start date format. Use YYYY-MM-DD')
            return
            
    if end_date:
        try:
            end_date_obj = datetime.strptime(end_date, '%Y-%m-%d')
        except ValueError:
            click.echo('Error: Invalid end date format. Use YYYY-MM-DD')
            return
    
    # Update fields if provided
    try:
        if name:
            tenant.name = name
        if plan:
            tenant.subscription_plan = plan
        if start_date_obj:
            tenant.subscription_start_date = start_date_obj
        if end_date_obj:
            tenant.subscription_end_date = end_date_obj
        if active is not None:
            tenant.is_active = active
        if phone:
            tenant.phone = phone
        if email:
            tenant.email = email
        if address:
            tenant.address = address
        if website:
            tenant.website = website
        
        db.session.commit()
        click.echo(f'Tenant {tenant.name} updated successfully')
    except Exception as e:
        db.session.rollback()
        click.echo(f'Error updating tenant: {str(e)}')

@tenant.command('delete')
@click.argument('tenant_id')
@click.confirmation_option(prompt='Are you sure you want to delete this tenant? This will delete all related data!')
def delete_tenant(tenant_id):
    """Delete a tenant and all its related data."""
    tenant = Tenant.query.get(tenant_id)
    
    if not tenant:
        click.echo('Tenant not found')
        return
    
    try:
        # Get the name for confirmation message
        tenant_name = tenant.name
        
        # Delete the tenant
        db.session.delete(tenant)
        db.session.commit()
        
        click.echo(f'Tenant {tenant_name} deleted successfully')
    except Exception as e:
        db.session.rollback()
        click.echo(f'Error deleting tenant: {str(e)}')