class Caregiver {
  final int id;
  final String name;

  Caregiver({
    required this.id,
    required this.name,
  });

  factory Caregiver.fromJson(Map<String, dynamic> json) {
    return Caregiver(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class AvailableSlot {
  final String startTime;
  final String endTime;
  final List<Caregiver> availableCaregivers;

  AvailableSlot({
    required this.startTime,
    required this.endTime,
    required this.availableCaregivers,
  });

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    var list = json['available_caregivers'] as List;
    List<Caregiver> caregivers = list.map((i) => Caregiver.fromJson(i as Map<String, dynamic>)).toList();
    
    return AvailableSlot(
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      availableCaregivers: caregivers,
    );
  }
}
