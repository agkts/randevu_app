// This is a temporary code runner file for testing Randevu App functionality
// You can use this to test specific parts of your code without running the entire app

// import 'dart:convert'; unused

void main() {
  // Test Appointment data structure
  testAppointmentModel();

  // Test working hours functionality
  testWorkingHours();

  // Test appointment filtering
  testAppointmentFiltering();

  // Test date formatting
  testDateFormatting();
}

void testAppointmentModel() {
  print('\n===== Testing Appointment Model =====');

  // Create a sample appointment JSON
  final Map<String, dynamic> appointmentJson = {
    'id': 'appt123',
    'customer_id': 'cust456',
    'customer_name': 'Ali Yılmaz',
    'customer_phone': '05551234567',
    'customer_email': 'ali@example.com',
    'customer_note': 'Saçlarım çabuk uzuyor',
    'hairdresser_id': 'hair789',
    'hairdresser_name': 'Mehmet Kuaför',
    'date_time': '2025-04-15T14:30:00.000Z',
    'service_ids': ['srv1', 'srv2'],
    'service_names': ['Saç Kesimi', 'Sakal Tıraşı'],
    'total_price': 250.0,
    'status': 'confirmed',
    'appointment_code': 'ABC123',
    'created_at': '2025-04-01T10:00:00.000Z',
    'salon_id': 'salon456',
  };

  // Parse the appointment (simulating the fromJson method)
  print('Created appointment from JSON:');
  print('Customer: ${appointmentJson['customer_name']}');
  print('Date: ${_formatDateTime(appointmentJson['date_time'])}');
  print('Services: ${appointmentJson['service_names'].join(', ')}');
  print('Status: ${_getStatusText(appointmentJson['status'])}');
}

void testWorkingHours() {
  print('\n===== Testing Working Hours =====');

  // Create default working schedule (simulating the createDefaultSchedule method)
  final Map<String, Map<String, dynamic>> workingSchedule = {
    'monday': {'is_active': true, 'open_time': '09:00', 'close_time': '18:00'},
    'tuesday': {'is_active': true, 'open_time': '09:00', 'close_time': '18:00'},
    'wednesday': {
      'is_active': true,
      'open_time': '09:00',
      'close_time': '18:00',
    },
    'thursday': {
      'is_active': true,
      'open_time': '09:00',
      'close_time': '18:00',
    },
    'friday': {'is_active': true, 'open_time': '09:00', 'close_time': '18:00'},
    'saturday': {
      'is_active': true,
      'open_time': '09:00',
      'close_time': '16:00',
    },
    'sunday': {'is_active': false, 'open_time': '09:00', 'close_time': '18:00'},
  };

  // Print working hours
  workingSchedule.forEach((day, hours) {
    if (hours['is_active']) {
      print('$day: ${hours['open_time']} - ${hours['close_time']}');
    } else {
      print('$day: Kapalı');
    }
  });

  // Test updating working hours
  workingSchedule['monday']!['open_time'] = '10:00';
  print('\nAfter update:');
  print(
    'monday: ${workingSchedule['monday']!['open_time']} - ${workingSchedule['monday']!['close_time']}',
  );
}

void testAppointmentFiltering() {
  print('\n===== Testing Appointment Filtering =====');

  // Sample appointments
  final List<Map<String, dynamic>> appointments = [
    {
      'id': 'appt1',
      'customer_name': 'Ali Yılmaz',
      'date_time': '2025-04-03T10:00:00.000Z', // Today
      'status': 'confirmed',
    },
    {
      'id': 'appt2',
      'customer_name': 'Ayşe Kaya',
      'date_time': '2025-04-03T14:00:00.000Z', // Today
      'status': 'pending',
    },
    {
      'id': 'appt3',
      'customer_name': 'Mehmet Demir',
      'date_time': '2025-04-04T11:00:00.000Z', // Tomorrow
      'status': 'confirmed',
    },
    {
      'id': 'appt4',
      'customer_name': 'Zeynep Acar',
      'date_time': '2025-04-02T15:00:00.000Z', // Yesterday
      'status': 'completed',
    },
  ];

  // Filter for today's appointments
  final DateTime today = DateTime(
    2025,
    4,
    3,
  ); // Using hardcoded date for the test
  final List<Map<String, dynamic>> todayAppointments =
      appointments.where((appt) {
        final appointmentDate = DateTime.parse(appt['date_time']);
        return _isSameDay(appointmentDate, today);
      }).toList();

  print('Today\'s appointments (${todayAppointments.length}):');
  for (final appt in todayAppointments) {
    print('- ${appt['customer_name']} at ${_formatTime(appt['date_time'])}');
  }

  // Filter by status
  final List<Map<String, dynamic>> pendingAppointments =
      appointments.where((appt) {
        return appt['status'] == 'pending';
      }).toList();

  print('\nPending appointments (${pendingAppointments.length}):');
  for (final appt in pendingAppointments) {
    print('- ${appt['customer_name']} on ${_formatDate(appt['date_time'])}');
  }
}

void testDateFormatting() {
  print('\n===== Testing Date Formatting =====');

  final String dateTimeString = '2025-04-03T14:30:00.000Z';
  final DateTime dateTime = DateTime.parse(dateTimeString);

  print('Original: $dateTimeString');
  print('Formatted date: ${_formatDate(dateTimeString)}');
  print('Formatted time: ${_formatTime(dateTimeString)}');
  print('Formatted date and time: ${_formatDateTime(dateTimeString)}');

  // Test the working schedule time slots
  final List<String> timeSlots = [];
  for (int hour = 9; hour < 18; hour++) {
    timeSlots.add('${hour.toString().padLeft(2, '0')}:00');
    timeSlots.add('${hour.toString().padLeft(2, '0')}:30');
  }

  print('\nAvailable time slots:');
  for (int i = 0; i < timeSlots.length; i += 4) {
    final end = (i + 4 < timeSlots.length) ? i + 4 : timeSlots.length;
    print(timeSlots.sublist(i, end).join('  '));
  }
}

// Helper functions

String _formatDate(String dateTimeString) {
  final DateTime dateTime = DateTime.parse(dateTimeString);
  return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
}

String _formatTime(String dateTimeString) {
  final DateTime dateTime = DateTime.parse(dateTimeString);
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

String _formatDateTime(String dateTimeString) {
  return '${_formatDate(dateTimeString)} ${_formatTime(dateTimeString)}';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _getStatusText(String status) {
  switch (status) {
    case 'pending':
      return 'Onay Bekliyor';
    case 'confirmed':
      return 'Onaylandı';
    case 'cancelled':
      return 'İptal Edildi';
    case 'completed':
      return 'Tamamlandı';
    case 'rejected':
      return 'Reddedildi';
    default:
      return status;
  }
}
