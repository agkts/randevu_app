import click
import csv
import json
import os
from datetime import datetime, timedelta
from app import db
from app.models import User, Tenant, Appointment, Service, Hairdresser, AppointmentStatus

@click.group()
def report():
    """Reporting and statistics commands."""
    pass

@report.command('tenant-stats')
@click.option('--output', '-o', default=None, help='Output file path (CSV format)')
def tenant_stats(output):
    """Generate statistics about tenants/salons."""
    tenants = Tenant.query.all()
    
    if not tenants:
        click.echo('No tenants found')
        return
    
    stats = []
    for tenant in tenants:
        # Count users
        users = User.query.filter_by(tenant_id=tenant.id).count()
        customers = User.query.filter_by(tenant_id=tenant.id, role='customer').count()
        hairdressers_count = Hairdresser.query.filter_by(salon_id=tenant.id).count()
        services_count = Service.query.filter_by(salon_id=tenant.id).count()
        
        # Count appointments
        total_appointments = Appointment.query.filter_by(salon_id=tenant.id).count()
        completed_appointments = Appointment.query.filter_by(
            salon_id=tenant.id, 
            status=AppointmentStatus.COMPLETED
        ).count()
        
        # Calculate completion rate
        completion_rate = (completed_appointments / total_appointments * 100) if total_appointments > 0 else 0
        
        # Get creation date
        created_date = tenant.created_at.strftime('%Y-%m-%d') if tenant.created_at else 'Unknown'
        
        # Calculate age in days
        age_days = (datetime.utcnow() - tenant.created_at).days if tenant.created_at else 0
        
        stats.append({
            'id': tenant.id,
            'name': tenant.name,
            'slug': tenant.slug,
            'is_active': tenant.is_active,
            'plan': tenant.subscription_plan,
            'created_date': created_date,
            'age_days': age_days,
            'users': users,
            'customers': customers,
            'hairdressers': hairdressers_count,
            'services': services_count,
            'total_appointments': total_appointments,
            'completed_appointments': completed_appointments,
            'completion_rate': round(completion_rate, 2)
        })
    
    # Display stats
    click.echo(f"Total tenants: {len(stats)}")
    click.echo("--------------------------------------------------")
    for tenant in stats:
        click.echo(f"Name: {tenant['name']}")
        click.echo(f"Slug: {tenant['slug']}")
        click.echo(f"Status: {'Active' if tenant['is_active'] else 'Inactive'}")
        click.echo(f"Plan: {tenant['plan']}")
        click.echo(f"Created: {tenant['created_date']} ({tenant['age_days']} days ago)")
        click.echo(f"Users: {tenant['users']} (Customers: {tenant['customers']})")
        click.echo(f"Hairdressers: {tenant['hairdressers']}")
        click.echo(f"Services: {tenant['services']}")
        click.echo(f"Appointments: {tenant['total_appointments']} (Completed: {tenant['completed_appointments']})")
        click.echo(f"Completion Rate: {tenant['completion_rate']}%")
        click.echo("--------------------------------------------------")
    
    # Export to CSV if output path is provided
    if output:
        try:
            with open(output, 'w', newline='') as csvfile:
                fieldnames = stats[0].keys() if stats else []
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                
                writer.writeheader()
                writer.writerows(stats)
                
                click.echo(f"Report exported to {output}")
        except Exception as e:
            click.echo(f"Error exporting report: {str(e)}")

@report.command('appointment-stats')
@click.option('--tenant-id', default=None, help='Filter by tenant ID')
@click.option('--days', default=30, help='Number of days to include in the report')
@click.option('--output', '-o', default=None, help='Output file path (CSV format)')
def appointment_stats(tenant_id, days, output):
    """Generate statistics about appointments."""
    # Calculate date range
    end_date = datetime.utcnow().date()
    start_date = end_date - timedelta(days=days)
    
    # Build query
    query = Appointment.query.filter(Appointment.appointment_date >= start_date)
    
    if tenant_id:
        query = query.filter_by(salon_id=tenant_id)
        tenant_name = Tenant.query.get(tenant_id).name if Tenant.query.get(tenant_id) else "Unknown"
        click.echo(f"Generating appointment stats for tenant: {tenant_name} ({tenant_id})")
    else:
        click.echo(f"Generating appointment stats for all tenants")
    
    appointments = query.all()
    
    if not appointments:
        click.echo('No appointments found for the specified criteria')
        return
    
    # Count by status
    status_counts = {
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'canceled': 0,
        'no_show': 0
    }
    
    # Count by date
    date_counts = {}
    
    # Count by tenant
    tenant_counts = {}
    
    # Iterate through appointments
    for appointment in appointments:
        # Status counts
        status = appointment.status.value
        if status in status_counts:
            status_counts[status] += 1
        
        # Date counts
        date_str = appointment.appointment_date.strftime('%Y-%m-%d')
        if date_str not in date_counts:
            date_counts[date_str] = 0
        date_counts[date_str] += 1
        
        # Tenant counts
        if appointment.salon_id not in tenant_counts:
            salon = Tenant.query.get(appointment.salon_id)
            tenant_counts[appointment.salon_id] = {
                'name': salon.name if salon else "Unknown",
                'count': 0
            }
        tenant_counts[appointment.salon_id]['count'] += 1
    
    # Calculate completion rate
    total = len(appointments)
    completion_rate = status_counts['completed'] / total * 100 if total > 0 else 0
    cancellation_rate = status_counts['canceled'] / total * 100 if total > 0 else 0
    
    # Display stats
    click.echo(f"Time period: {start_date} to {end_date} ({days} days)")
    click.echo(f"Total appointments: {total}")
    click.echo("--------------------------------------------------")
    click.echo("Status breakdown:")
    for status, count in status_counts.items():
        percentage = count / total * 100 if total > 0 else 0
        click.echo(f"  {status.capitalize()}: {count} ({percentage:.1f}%)")
    click.echo("--------------------------------------------------")
    click.echo(f"Completion rate: {completion_rate:.1f}%")
    click.echo(f"Cancellation rate: {cancellation_rate:.1f}%")
    
    click.echo("--------------------------------------------------")
    click.echo("Appointments by tenant:")
    sorted_tenants = sorted(tenant_counts.items(), key=lambda x: x[1]['count'], reverse=True)
    for tenant_id, data in sorted_tenants:
        percentage = data['count'] / total * 100
        click.echo(f"  {data['name']}: {data['count']} ({percentage:.1f}%)")
    
    # Export to CSV if output path is provided
    if output:
        try:
            with open(output, 'w', newline='') as csvfile:
                writer = csv.writer(csvfile)
                
                # Write header
                writer.writerow(['Metric', 'Value'])
                
                # Write summary stats
                writer.writerow(['Total Appointments', total])
                writer.writerow(['Time Period', f"{start_date} to {end_date}"])
                writer.writerow(['Completion Rate', f"{completion_rate:.1f}%"])
                writer.writerow(['Cancellation Rate', f"{cancellation_rate:.1f}%"])
                
                # Write status breakdown
                writer.writerow([])
                writer.writerow(['Status', 'Count', 'Percentage'])
                for status, count in status_counts.items():
                    percentage = count / total * 100 if total > 0 else 0
                    writer.writerow([status.capitalize(), count, f"{percentage:.1f}%"])
                
                # Write tenant breakdown
                writer.writerow([])
                writer.writerow(['Tenant', 'Count', 'Percentage'])
                for tenant_id, data in sorted_tenants:
                    percentage = data['count'] / total * 100
                    writer.writerow([data['name'], data['count'], f"{percentage:.1f}%"])
                
                # Write date breakdown
                writer.writerow([])
                writer.writerow(['Date', 'Count'])
                for date_str, count in sorted(date_counts.items()):
                    writer.writerow([date_str, count])
                
                click.echo(f"Report exported to {output}")
        except Exception as e:
            click.echo(f"Error exporting report: {str(e)}")

@report.command('user-stats')
@click.option('--tenant-id', default=None, help='Filter by tenant ID')
@click.option('--output', '-o', default=None, help='Output file path (CSV format)')
def user_stats(tenant_id, output):
    """Generate statistics about users."""
    # Build query
    query = User.query
    
    if tenant_id:
        query = query.filter_by(tenant_id=tenant_id)
        tenant_name = Tenant.query.get(tenant_id).name if Tenant.query.get(tenant_id) else "Unknown"
        click.echo(f"Generating user stats for tenant: {tenant_name} ({tenant_id})")
    else:
        click.echo(f"Generating user stats for all users")
    
    users = query.all()
    
    if not users:
        click.echo('No users found for the specified criteria')
        return
    
    # Count by role
    role_counts = {
        'customer': 0,
        'hairdresser': 0,
        'salon_owner': 0,
        'super_admin': 0
    }
    
    # Count active/inactive
    active_count = 0
    inactive_count = 0
    
    # Count by tenant
    tenant_counts = {}
    
    # Count by creation date (by month)
    date_counts = {}
    
    # Iterate through users
    for user in users:
        # Role counts
        role = user.role.value
        if role in role_counts:
            role_counts[role] += 1
        
        # Active/inactive
        if user.is_active:
            active_count += 1
        else:
            inactive_count += 1
        
        # Tenant counts
        if user.tenant_id:
            if user.tenant_id not in tenant_counts:
                salon = Tenant.query.get(user.tenant_id)
                tenant_counts[user.tenant_id] = {
                    'name': salon.name if salon else "Unknown",
                    'count': 0
                }
            tenant_counts[user.tenant_id]['count'] += 1
        
        # Date counts (by month)
        if user.created_at:
            date_str = user.created_at.strftime('%Y-%m')
            if date_str not in date_counts:
                date_counts[date_str] = 0
            date_counts[date_str] += 1
    
    total = len(users)
    active_percentage = active_count / total * 100 if total > 0 else 0
    
    # Display stats
    click.echo(f"Total users: {total}")
    click.echo(f"Active users: {active_count} ({active_percentage:.1f}%)")
    click.echo(f"Inactive users: {inactive_count} ({100-active_percentage:.1f}%)")
    click.echo("--------------------------------------------------")
    click.echo("Role breakdown:")
    for role, count in role_counts.items():
        percentage = count / total * 100 if total > 0 else 0
        click.echo(f"  {role.capitalize()}: {count} ({percentage:.1f}%)")
    
    if tenant_counts:
        click.echo("--------------------------------------------------")
        click.echo("Users by tenant:")
        sorted_tenants = sorted(tenant_counts.items(), key=lambda x: x[1]['count'], reverse=True)
        for tenant_id, data in sorted_tenants[:10]:  # Show top 10
            percentage = data['count'] / total * 100
            click.echo(f"  {data['name']}: {data['count']} ({percentage:.1f}%)")
        
        if len(tenant_counts) > 10:
            click.echo(f"  ... and {len(tenant_counts) - 10} more")
    
    # Export to CSV if output path is provided
    if output:
        try:
            with open(output, 'w', newline='') as csvfile:
                writer = csv.writer(csvfile)
                
                # Write header
                writer.writerow(['Metric', 'Value'])
                
                # Write summary stats
                writer.writerow(['Total Users', total])
                writer.writerow(['Active Users', active_count])
                writer.writerow(['Active Percentage', f"{active_percentage:.1f}%"])
                writer.writerow(['Inactive Users', inactive_count])
                
                # Write role breakdown
                writer.writerow([])
                writer.writerow(['Role', 'Count', 'Percentage'])
                for role, count in role_counts.items():
                    percentage = count / total * 100 if total > 0 else 0
                    writer.writerow([role.capitalize(), count, f"{percentage:.1f}%"])
                
                # Write tenant breakdown
                if tenant_counts:
                    writer.writerow([])
                    writer.writerow(['Tenant', 'Count', 'Percentage'])
                    sorted_tenants = sorted(tenant_counts.items(), key=lambda x: x[1]['count'], reverse=True)
                    for tenant_id, data in sorted_tenants:
                        percentage = data['count'] / total * 100
                        writer.writerow([data['name'], data['count'], f"{percentage:.1f}%"])
                
                # Write date breakdown
                writer.writerow([])
                writer.writerow(['Month', 'New Users'])
                for date_str, count in sorted(date_counts.items()):
                    writer.writerow([date_str, count])
                
                click.echo(f"Report exported to {output}")
        except Exception as e:
            click.echo(f"Error exporting report: {str(e)}")

@report.command('export-data')
@click.argument('entity', type=click.Choice(['tenants', 'users', 'hairdressers', 'services', 'appointments']))
@click.option('--tenant-id', default=None, help='Filter by tenant ID')
@click.option('--output', '-o', default='data_export.json', help='Output file path (JSON format)')
@click.option('--pretty/--compact', default=True, help='Pretty print JSON output')
def export_data(entity, tenant_id, output, pretty):
    """Export data to JSON format."""
    click.echo(f"Exporting {entity} data...")
    
    # Select the appropriate model based on entity
    if entity == 'tenants':
        model = Tenant
        query = model.query
    elif entity == 'users':
        model = User
        query = model.query
        if tenant_id:
            query = query.filter_by(tenant_id=tenant_id)
    elif entity == 'hairdressers':
        model = Hairdresser
        query = model.query
        if tenant_id:
            query = query.filter_by(salon_id=tenant_id)
    elif entity == 'services':
        model = Service
        query = model.query
        if tenant_id:
            query = query.filter_by(salon_id=tenant_id)
    elif entity == 'appointments':
        model = Appointment
        query = model.query
        if tenant_id:
            query = query.filter_by(salon_id=tenant_id)
    
    # Get all records
    records = query.all()
    
    if not records:
        click.echo(f'No {entity} found')
        return
    
    click.echo(f"Found {len(records)} {entity}")
    
    # Convert to dictionary
    data = [record.to_dict() for record in records]
    
    # Export to JSON
    try:
        indent = 2 if pretty else None
        with open(output, 'w') as f:
            json.dump(data, f, indent=indent, default=str)
            
        click.echo(f"Data exported to {output}")
    except Exception as e:
        click.echo(f"Error exporting data: {str(e)}")