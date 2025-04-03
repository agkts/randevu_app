class WorkingHours {
  final bool isActive;
  final String openTime; // Format: "09:00"
  final String closeTime; // Format: "18:00"

  WorkingHours({
    required this.isActive,
    required this.openTime,
    required this.closeTime,
  });

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      isActive: json['is_active'] ?? false,
      openTime: json['open_time'] ?? "09:00",
      closeTime: json['close_time'] ?? "18:00",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_active': isActive,
      'open_time': openTime,
      'close_time': closeTime,
    };
  }

  // Kopyalama ile yeni nesne oluşturma
  WorkingHours copyWith({bool? isActive, String? openTime, String? closeTime}) {
    return WorkingHours(
      isActive: isActive ?? this.isActive,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}

class Hairdresser {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? profileImage;
  final Map<String, WorkingHours>
  workingSchedule; // Haftanın günleri için çalışma saatleri
  final List<String>? serviceIds; // Sunduğu hizmetler
  final bool isActive;
  final String? salonId;
  final String? username; // Kullanıcı adı
  final List<DateTime>? holidayDates; // Tatil günleri

  Hairdresser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.profileImage,
    required this.workingSchedule,
    this.serviceIds,
    required this.isActive,
    this.salonId,
    this.username,
    this.holidayDates,
  });

  // JSON'dan model oluşturma
  factory Hairdresser.fromJson(Map<String, dynamic> json) {
    Map<String, WorkingHours> workingHoursMap = {};
    Map<String, dynamic> schedule = json['working_schedule'] ?? {};

    schedule.forEach((key, value) {
      workingHoursMap[key] = WorkingHours.fromJson(value);
    });

    List<DateTime>? holidayList;
    if (json['holiday_dates'] != null) {
      holidayList =
          (json['holiday_dates'] as List)
              .map((date) => DateTime.parse(date))
              .toList();
    }

    return Hairdresser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profile_image'],
      workingSchedule: workingHoursMap,
      serviceIds:
          json['service_ids'] != null
              ? List<String>.from(json['service_ids'])
              : null,
      isActive: json['is_active'] ?? true,
      salonId: json['salon_id'],
      username: json['username'],
      holidayDates: holidayList,
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    Map<String, dynamic> workingHoursJson = {};
    workingSchedule.forEach((key, value) {
      workingHoursJson[key] = value.toJson();
    });

    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'working_schedule': workingHoursJson,
      'service_ids': serviceIds,
      'is_active': isActive,
      'salon_id': salonId,
      'username': username,
      'holiday_dates':
          holidayDates?.map((date) => date.toIso8601String()).toList(),
    };
  }

  // Default çalışma programı oluşturma
  static Map<String, WorkingHours> createDefaultSchedule() {
    return {
      'monday': WorkingHours(
        isActive: true,
        openTime: "09:00",
        closeTime: "18:00",
      ),
      'tuesday': WorkingHours(
        isActive: true,
        openTime: "09:00",
        closeTime: "18:00",
      ),
      'wednesday': WorkingHours(
        isActive: true,
        openTime: "09:00",
        closeTime: "18:00",
      ),
      'thursday': WorkingHours(
        isActive: true,
        openTime: "09:00",
        closeTime: "18:00",
      ),
      'friday': WorkingHours(
        isActive: true,
        openTime: "09:00",
        closeTime: "18:00",
      ),
      'saturday': WorkingHours(
        isActive: true,
        openTime: "09:00",
        closeTime: "16:00",
      ),
      'sunday': WorkingHours(
        isActive: false,
        openTime: "09:00",
        closeTime: "18:00",
      ),
    };
  }

  // Kopyalama ile yeni nesne oluşturma
  Hairdresser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    Map<String, WorkingHours>? workingSchedule,
    List<String>? serviceIds,
    bool? isActive,
    String? salonId,
    String? username,
    List<DateTime>? holidayDates,
  }) {
    return Hairdresser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      workingSchedule: workingSchedule ?? this.workingSchedule,
      serviceIds: serviceIds ?? this.serviceIds,
      isActive: isActive ?? this.isActive,
      salonId: salonId ?? this.salonId,
      username: username ?? this.username,
      holidayDates: holidayDates ?? this.holidayDates,
    );
  }
}
