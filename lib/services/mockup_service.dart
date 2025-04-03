import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/service.dart';
import '../models/hairdresser.dart';
import '../models/salon.dart';
import '../models/appointment.dart';

class MockupService {
  // Mock Services
  static final List<Service> _mockServices = [
    Service(
      id: '1',
      name: 'Erkek Saç Kesimi',
      price: 100.0,
      durationMinutes: 30,
      description: 'Modern ve şık erkek saç kesimi',
      isActive: true,
      salonId: 'salon_1',
    ),
    Service(
      id: '2',
      name: 'Kadın Saç Kesimi',
      price: 150.0,
      durationMinutes: 45,
      description: 'Profesyonel kadın saç kesimi ve şekillendirme',
      isActive: true,
      salonId: 'salon_1',
    ),
    Service(
      id: '3',
      name: 'Saç Boyama',
      price: 200.0,
      durationMinutes: 60,
      description: 'Profesyonel saç boyama hizmeti',
      isActive: true,
      salonId: 'salon_1',
    ),
    Service(
      id: '4',
      name: 'Manikür',
      price: 80.0,
      durationMinutes: 30,
      description: 'Profesyonel manikür hizmeti',
      isActive: true,
      salonId: 'salon_1',
    ),
    Service(
      id: '5',
      name: 'Saç Bakımı',
      price: 120.0,
      durationMinutes: 45,
      description: 'Derinlemesine saç bakımı ve onarımı',
      isActive: true,
      salonId: 'salon_1',
    ),
  ];

  // Mock Hairdressers
  static final List<Hairdresser> _mockHairdressers = [
    Hairdresser(
      id: 'hairdresser_1',
      name: 'Ahmet Yılmaz',
      email: 'ahmet@randevuapp.com',
      phone: '05XX XXX XX XX',
      profileImage: null,
      workingSchedule: Hairdresser.createDefaultSchedule(),
      serviceIds: ['1', '2', '3'],
      isActive: true,
      salonId: 'salon_1',
      username: 'ahmet_y',
      holidayDates: null,
    ),
    Hairdresser(
      id: 'hairdresser_2',
      name: 'Elif Demir',
      email: 'elif@randevuapp.com',
      phone: '05XX XXX XX XX',
      profileImage: null,
      workingSchedule: Hairdresser.createDefaultSchedule(),
      serviceIds: ['2', '3', '4', '5'],
      isActive: true,
      salonId: 'salon_1',
      username: 'elif_d',
      holidayDates: null,
    ),
    Hairdresser(
      id: 'hairdresser_3',
      name: 'Mehmet Kaya',
      email: 'mehmet@randevuapp.com',
      phone: '05XX XXX XX XX',
      profileImage: null,
      workingSchedule: Hairdresser.createDefaultSchedule(),
      serviceIds: ['1', '4', '5'],
      isActive: true,
      salonId: 'salon_1',
      username: 'mehmet_k',
      holidayDates: null,
    ),
  ];

  // Mock Salon
  static final Salon _mockSalon = Salon(
    id: 'salon_1',
    name: 'Güzellik Salonu',
    address: 'Örnek Mahallesi, No: 123, İstanbul',
    phone: '0212 XXX XX XX',
    email: 'info@randevuapp.com',
    website: 'www.randevuapp.com',
    logoUrl: null,
    settings: SalonSettings(
      allowOnlineBooking: true,
      defaultAppointmentDuration: 30,
      minimumNoticeTime: 60,
      cancelationTimeLimit: 24,
      sendSmsReminders: true,
      reminderTimeBeforeAppointment: 24,
      requireCustomerEmail: true,
    ),
    smsSettings: SmsSettings(
      isActive: true,
      apiKey: 'mock_api_key',
      senderId: 'RANDEVU',
      appointmentConfirmationTemplate: 'Randevunuz onaylandı!',
      appointmentReminderTemplate: 'Randevunuz yaklaşıyor!',
      appointmentCancelTemplate: 'Randevunuz iptal edildi.',
    ),
    workingSchedule: Hairdresser.createDefaultSchedule(),
    ownerId: 'owner_1',
  );

  // Mock Appointments
  static final List<Appointment> _mockAppointments = [
    Appointment(
      id: 'appointment_1',
      customerId: 'customer_1',
      customerName: 'Test Müşteri 1',
      customerPhone: '05XX XXX XX XX',
      customerEmail: 'musteri1@test.com',
      customerNote: 'İlk randevum, heyecanlıyım!',
      hairdresserId: _mockHairdressers[0].id,
      hairdresserName: _mockHairdressers[0].name,
      dateTime: DateTime.now().add(Duration(days: 3, hours: 10)),
      serviceIds: [_mockServices[0].id, _mockServices[1].id],
      serviceNames: [_mockServices[0].name, _mockServices[1].name],
      totalPrice: _mockServices[0].price + _mockServices[1].price,
      status: AppointmentStatus.pending,
      appointmentCode: 'ABC123',
      createdAt: DateTime.now(),
    ),
    Appointment(
      id: 'appointment_2',
      customerId: 'customer_2',
      customerName: 'Test Müşteri 2',
      customerPhone: '05XX XXX XX XX',
      customerEmail: 'musteri2@test.com',
      customerNote: 'Saçlarımı çok özledim!',
      hairdresserId: _mockHairdressers[1].id,
      hairdresserName: _mockHairdressers[1].name,
      dateTime: DateTime.now().add(Duration(days: 5, hours: 14)),
      serviceIds: [_mockServices[2].id, _mockServices[4].id],
      serviceNames: [_mockServices[2].name, _mockServices[4].name],
      totalPrice: _mockServices[2].price + _mockServices[4].price,
      status: AppointmentStatus.confirmed,
      appointmentCode: 'DEF456',
      createdAt: DateTime.now(),
    ),
  ];

  // Services Methods
  Future<Map<String, dynamic>> getServices(Map<String, dynamic>? params) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    return {
      'success': true,
      'data': _mockServices.map((service) => service.toJson()).toList(),
    };
  }

  Future<Map<String, dynamic>> getService(String serviceId) async {
    await Future.delayed(Duration(milliseconds: 500));
    final service = _mockServices.firstWhere((s) => s.id == serviceId);
    return {'success': true, 'data': service.toJson()};
  }

  // Hairdressers Methods
  Future<Map<String, dynamic>> getHairdressers(
    Map<String, dynamic>? params,
  ) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'success': true,
      'data': _mockHairdressers.map((h) => h.toJson()).toList(),
    };
  }

  Future<Map<String, dynamic>> getHairdresser(String hairdresserId) async {
    await Future.delayed(Duration(milliseconds: 500));
    final hairdresser = _mockHairdressers.firstWhere(
      (h) => h.id == hairdresserId,
    );
    return {'success': true, 'data': hairdresser.toJson()};
  }

  // Salon Methods
  Future<Map<String, dynamic>> getSalon(String salonId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {'success': true, 'data': _mockSalon.toJson()};
  }

  // Appointments Methods
  Future<Map<String, dynamic>> getAppointments(
    Map<String, dynamic>? params,
  ) async {
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'success': true,
      'data': _mockAppointments.map((a) => a.toJson()).toList(),
    };
  }

  Future<Map<String, dynamic>> getAppointmentByCode(String code) async {
    await Future.delayed(Duration(milliseconds: 500));
    final appointment = _mockAppointments.firstWhere(
      (a) => a.appointmentCode == code,
    );
    return {'success': true, 'data': appointment.toJson()};
  }

  // Authentication Method
  Future<Map<String, dynamic>> login(String username, String password) async {
    await Future.delayed(Duration(milliseconds: 500));

    // Mock login for testing
    if (username == 'ahmet_y' && password == 'password') {
      return {
        'success': true,
        'data': {
          'user_id': 'hairdresser_1',
          'user_name': 'Ahmet Yılmaz',
          'user_role': 'hairdresser',
          'token': 'mock_hairdresser_token',
          'salon_id': 'salon_1',
        },
      };
    } else if (username == 'salon_admin' && password == 'password') {
      return {
        'success': true,
        'data': {
          'user_id': 'owner_1',
          'user_name': 'Salon Sahibi',
          'user_role': 'salonOwner',
          'token': 'mock_salon_owner_token',
          'salon_id': 'salon_1',
        },
      };
    }

    return {'success': false, 'message': 'Kullanıcı adı veya şifre hatalı'};
  }

  // Mock Methods for Creating/Updating/Deleting (you can expand these)
  Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(Duration(milliseconds: 500));

    final newAppointment = Appointment(
      id: 'new_appointment_${_mockAppointments.length + 1}',
      customerId: data['customer_name'],
      customerName: data['customer_name'],
      customerPhone: data['customer_phone'],
      customerEmail: data['customer_email'],
      customerNote: data['customer_note'] ?? '',
      hairdresserId: data['hairdresser_id'],
      hairdresserName:
          _mockHairdressers
              .firstWhere((h) => h.id == data['hairdresser_id'])
              .name,
      dateTime: DateTime.parse(data['date_time']),
      serviceIds: List<String>.from(data['service_ids']),
      serviceNames:
          _mockServices
              .where((s) => data['service_ids'].contains(s.id))
              .map((s) => s.name)
              .toList(),
      totalPrice: _mockServices
          .where((s) => data['service_ids'].contains(s.id))
          .map((s) => s.price)
          .reduce((a, b) => a + b),
      status: AppointmentStatus.pending,
      appointmentCode: 'NEW${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    _mockAppointments.add(newAppointment);

    return {'success': true, 'data': newAppointment.toJson()};
  }
}
