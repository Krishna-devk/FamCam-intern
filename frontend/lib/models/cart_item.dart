import 'package:flutter/material.dart';

class CartItem {
  final int serviceId;
  final String serviceName;
  final int caregiverId;
  final String caregiverName;
  final DateTime date;
  final TimeOfDay startTime;
  final int durationMinutes;
  final int priceCents;

  CartItem({
    required this.serviceId,
    required this.serviceName,
    required this.caregiverId,
    required this.caregiverName,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.priceCents,
  });

  String get startTimeFormatted {
    final hourStr = startTime.hour.toString().padLeft(2, '0');
    final minuteStr = startTime.minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'caregiver_id': caregiverId,
      'date': "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'start_time': startTimeFormatted,
    };
  }
}
