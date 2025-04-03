import 'package:randevu_app/models/hairdresser.dart';

class SalonSettings {
  final bool allowOnlineBooking;
  final int defaultAppointmentDuration; // Dakika cinsinden
  final int
  minimumNoticeTime; // Minimum randevu öncesi bildirim süresi (dakika cinsinden)
  final int?
  cancelationTimeLimit; // İptal için son süre sınırı (saat cinsinden)
  final bool sendSmsReminders;
  final int
  reminderTimeBeforeAppointment; // Saat cinsinden, randevudan kaç saat önce
  final bool requireCustomerEmail;

  SalonSettings({
    required this.allowOnlineBooking,
    required this.defaultAppointmentDuration,
    required this.minimumNoticeTime,
    this.cancelationTimeLimit,
    required this.sendSmsReminders,
    required this.reminderTimeBeforeAppointment,
    required this.requireCustomerEmail,
  });

  factory SalonSettings.fromJson(Map<String, dynamic> json) {
    return SalonSettings(
      allowOnlineBooking: json['allow_online_booking'] ?? true,
      defaultAppointmentDuration: json['default_appointment_duration'] ?? 30,
      minimumNoticeTime: json['minimum_notice_time'] ?? 60,
      cancelationTimeLimit: json['cancelation_time_limit'],
      sendSmsReminders: json['send_sms_reminders'] ?? true,
      reminderTimeBeforeAppointment:
          json['reminder_time_before_appointment'] ?? 24,
      requireCustomerEmail: json['require_customer_email'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allow_online_booking': allowOnlineBooking,
      'default_appointment_duration': defaultAppointmentDuration,
      'minimum_notice_time': minimumNoticeTime,
      'cancelation_time_limit': cancelationTimeLimit,
      'send_sms_reminders': sendSmsReminders,
      'reminder_time_before_appointment': reminderTimeBeforeAppointment,
      'require_customer_email': requireCustomerEmail,
    };
  }

  // Kopyalama ile yeni nesne oluşturma
  SalonSettings copyWith({
    bool? allowOnlineBooking,
    int? defaultAppointmentDuration,
    int? minimumNoticeTime,
    int? cancelationTimeLimit,
    bool? sendSmsReminders,
    int? reminderTimeBeforeAppointment,
    bool? requireCustomerEmail,
  }) {
    return SalonSettings(
      allowOnlineBooking: allowOnlineBooking ?? this.allowOnlineBooking,
      defaultAppointmentDuration:
          defaultAppointmentDuration ?? this.defaultAppointmentDuration,
      minimumNoticeTime: minimumNoticeTime ?? this.minimumNoticeTime,
      cancelationTimeLimit: cancelationTimeLimit ?? this.cancelationTimeLimit,
      sendSmsReminders: sendSmsReminders ?? this.sendSmsReminders,
      reminderTimeBeforeAppointment:
          reminderTimeBeforeAppointment ?? this.reminderTimeBeforeAppointment,
      requireCustomerEmail: requireCustomerEmail ?? this.requireCustomerEmail,
    );
  }
}

class SmsSettings {
  final bool isActive;
  final String? apiKey;
  final String? senderId;
  final String? appointmentConfirmationTemplate;
  final String? appointmentReminderTemplate;
  final String? appointmentCancelTemplate;

  SmsSettings({
    required this.isActive,
    this.apiKey,
    this.senderId,
    this.appointmentConfirmationTemplate,
    this.appointmentReminderTemplate,
    this.appointmentCancelTemplate,
  });

  factory SmsSettings.fromJson(Map<String, dynamic> json) {
    return SmsSettings(
      isActive: json['is_active'] ?? false,
      apiKey: json['api_key'],
      senderId: json['sender_id'],
      appointmentConfirmationTemplate:
          json['appointment_confirmation_template'],
      appointmentReminderTemplate: json['appointment_reminder_template'],
      appointmentCancelTemplate: json['appointment_cancel_template'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_active': isActive,
      'api_key': apiKey,
      'sender_id': senderId,
      'appointment_confirmation_template': appointmentConfirmationTemplate,
      'appointment_reminder_template': appointmentReminderTemplate,
      'appointment_cancel_template': appointmentCancelTemplate,
    };
  }

  // Kopyalama ile yeni nesne oluşturma
  SmsSettings copyWith({
    bool? isActive,
    String? apiKey,
    String? senderId,
    String? appointmentConfirmationTemplate,
    String? appointmentReminderTemplate,
    String? appointmentCancelTemplate,
  }) {
    return SmsSettings(
      isActive: isActive ?? this.isActive,
      apiKey: apiKey ?? this.apiKey,
      senderId: senderId ?? this.senderId,
      appointmentConfirmationTemplate:
          appointmentConfirmationTemplate ??
          this.appointmentConfirmationTemplate,
      appointmentReminderTemplate:
          appointmentReminderTemplate ?? this.appointmentReminderTemplate,
      appointmentCancelTemplate:
          appointmentCancelTemplate ?? this.appointmentCancelTemplate,
    );
  }
}

class Salon {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? logoUrl;
  final SalonSettings settings;
  final SmsSettings smsSettings;
  final Map<String, WorkingHours> workingSchedule; // Salonun çalışma saatleri
  final String ownerId; // Salon sahibinin ID'si

  Salon({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.logoUrl,
    required this.settings,
    required this.smsSettings,
    required this.workingSchedule,
    required this.ownerId,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    Map<String, WorkingHours> workingHoursMap = {};
    Map<String, dynamic> schedule = json['working_schedule'] ?? {};

    schedule.forEach((key, value) {
      workingHoursMap[key] = WorkingHours.fromJson(value);
    });

    return Salon(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      logoUrl: json['logo_url'],
      settings: SalonSettings.fromJson(json['settings'] ?? {}),
      smsSettings: SmsSettings.fromJson(json['sms_settings'] ?? {}),
      workingSchedule: workingHoursMap,
      ownerId: json['owner_id'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> workingHoursJson = {};
    workingSchedule.forEach((key, value) {
      workingHoursJson[key] = value.toJson();
    });

    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'logo_url': logoUrl,
      'settings': settings.toJson(),
      'sms_settings': smsSettings.toJson(),
      'working_schedule': workingHoursJson,
      'owner_id': ownerId,
    };
  }

  // Kopyalama ile yeni nesne oluşturma
  Salon copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? logoUrl,
    SalonSettings? settings,
    SmsSettings? smsSettings,
    Map<String, WorkingHours>? workingSchedule,
    String? ownerId,
  }) {
    return Salon(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      settings: settings ?? this.settings,
      smsSettings: smsSettings ?? this.smsSettings,
      workingSchedule: workingSchedule ?? this.workingSchedule,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}

// WorkingHours sınıfı daha önce Hairdresser modelinde tanımlandı,
// burada aynı modeli kullanıyoruz.
