import 'package:intl/intl.dart';

enum AppointmentStatus {
  pending, // Onay Bekliyor
  confirmed, // Onaylandı
  cancelled, // İptal Edildi
  completed, // Tamamlandı
  rejected, // Reddedildi
}

class Appointment {
  final String? id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String? customerNote;
  final String hairdresserId;
  final String hairdresserName;
  final DateTime dateTime;
  final List<String>? serviceIds;
  final List<String>? serviceNames;
  final double? totalPrice;
  final AppointmentStatus status;
  final String appointmentCode;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? salonId;

  Appointment({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    this.customerNote,
    required this.hairdresserId,
    required this.hairdresserName,
    required this.dateTime,
    this.serviceIds,
    this.serviceNames,
    this.totalPrice,
    required this.status,
    required this.appointmentCode,
    required this.createdAt,
    this.updatedAt,
    this.salonId,
  });

  // JSON'dan model oluşturma
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      customerId: json['customer_id'] ?? '',
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      customerEmail: json['customer_email'],
      customerNote: json['customer_note'],
      hairdresserId: json['hairdresser_id'],
      hairdresserName: json['hairdresser_name'],
      dateTime: DateTime.parse(json['date_time']),
      serviceIds:
          json['service_ids'] != null
              ? List<String>.from(json['service_ids'])
              : null,
      serviceNames:
          json['service_names'] != null
              ? List<String>.from(json['service_names'])
              : null,
      totalPrice: json['total_price']?.toDouble(),
      status: _statusFromString(json['status']),
      appointmentCode: json['appointment_code'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      salonId: json['salon_id'],
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'customer_note': customerNote,
      'hairdresser_id': hairdresserId,
      'hairdresser_name': hairdresserName,
      'date_time': dateTime.toIso8601String(),
      'service_ids': serviceIds,
      'service_names': serviceNames,
      'total_price': totalPrice,
      'status': _statusToString(status),
      'appointment_code': appointmentCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'salon_id': salonId,
    };
  }

  // Status string'inden enum oluşturma
  static AppointmentStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'completed':
        return AppointmentStatus.completed;
      case 'rejected':
        return AppointmentStatus.rejected;
      default:
        return AppointmentStatus.pending;
    }
  }

  // Status enum'undan string oluşturma
  static String _statusToString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.rejected:
        return 'rejected';
    }
  }

  // Status'a göre Türkçe durum metni
  String get statusText {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Onay Bekliyor';
      case AppointmentStatus.confirmed:
        return 'Onaylandı';
      case AppointmentStatus.cancelled:
        return 'İptal Edildi';
      case AppointmentStatus.completed:
        return 'Tamamlandı';
      case AppointmentStatus.rejected:
        return 'Reddedildi';
    }
  }

  // Tarih formatı
  String get formattedDate => DateFormat('dd.MM.yyyy').format(dateTime);

  // Saat formatı
  String get formattedTime => DateFormat('HH:mm').format(dateTime);

  // Hizmet adları için formatlı metin
  String get servicesText {
    if (serviceNames == null || serviceNames!.isEmpty) {
      return '-';
    }
    return serviceNames!.join(', ');
  }

  // Kopyalama ile yeni nesne oluşturma
  Appointment copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerNote,
    String? hairdresserId,
    String? hairdresserName,
    DateTime? dateTime,
    List<String>? serviceIds,
    List<String>? serviceNames,
    double? totalPrice,
    AppointmentStatus? status,
    String? appointmentCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? salonId,
  }) {
    return Appointment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      customerNote: customerNote ?? this.customerNote,
      hairdresserId: hairdresserId ?? this.hairdresserId,
      hairdresserName: hairdresserName ?? this.hairdresserName,
      dateTime: dateTime ?? this.dateTime,
      serviceIds: serviceIds ?? this.serviceIds,
      serviceNames: serviceNames ?? this.serviceNames,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      appointmentCode: appointmentCode ?? this.appointmentCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      salonId: salonId ?? this.salonId,
    );
  }
}
