class Service {
  final int id;
  final String name;
  final String description;
  final int durationMinutes;
  final int priceCents;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.priceCents,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] ?? '',
      durationMinutes: json['duration_minutes'] as int,
      priceCents: json['price_cents'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration_minutes': durationMinutes,
      'price_cents': priceCents,
    };
  }
}
