class Service {
  final String id;
  final String name;
  final double price;
  final int durationMinutes; // Dakika cinsinden süre
  final String? description;
  final bool isActive;
  final String? salonId;

  Service({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
    required this.isActive,
    this.salonId,
  });

  // JSON'dan model oluşturma
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'],
      price: json['price']?.toDouble() ?? 0.0,
      durationMinutes: json['duration_minutes'] ?? 30,
      description: json['description'],
      isActive: json['is_active'] ?? true,
      salonId: json['salon_id'],
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'duration_minutes': durationMinutes,
      'description': description,
      'is_active': isActive,
      'salon_id': salonId,
    };
  }

  // Formatlanmış fiyat
  String get formattedPrice => '₺${price.toStringAsFixed(2)}';

  // Formatlanmış süre
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours > 0) {
      return '$hours saat ${minutes > 0 ? '$minutes dk' : ''}';
    } else {
      return '$minutes dk';
    }
  }

  // Kopyalama ile yeni nesne oluşturma
  Service copyWith({
    String? id,
    String? name,
    double? price,
    int? durationMinutes,
    String? description,
    bool? isActive,
    String? salonId,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      salonId: salonId ?? this.salonId,
    );
  }
}
