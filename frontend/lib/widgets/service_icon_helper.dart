import 'package:flutter/material.dart';

/// Maps service names to icons and accent colors
class ServiceIconHelper {
  static IconData iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('physio'))             return Icons.accessibility_new_outlined;
    if (n.contains('wound'))              return Icons.healing_outlined;
    if (n.contains('medication'))         return Icons.medication_liquid_outlined;
    if (n.contains('elderly') || n.contains('companion')) return Icons.elderly_outlined;
    if (n.contains('occupational'))       return Icons.psychology_outlined;
    if (n.contains('surgical') || n.contains('nursing')) return Icons.local_hospital_outlined;
    if (n.contains('diet') || n.contains('nutrition')) return Icons.restaurant_menu_outlined;
    if (n.contains('vital') || n.contains('monitoring')) return Icons.monitor_heart_outlined;
    return Icons.medical_services_outlined;
  }

  static Color colorFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('physio'))             return const Color(0xFF2563EB); // cobalt
    if (n.contains('wound'))              return const Color(0xFFEF4444); // red
    if (n.contains('medication'))         return const Color(0xFF8B5CF6); // violet
    if (n.contains('elderly') || n.contains('companion')) return const Color(0xFFF59E0B); // amber
    if (n.contains('occupational'))       return const Color(0xFF0EA5E9); // sky
    if (n.contains('surgical'))           return const Color(0xFFEF4444); // red
    if (n.contains('diet') || n.contains('nutrition')) return const Color(0xFF10B981); // emerald
    if (n.contains('vital') || n.contains('monitoring')) return const Color(0xFF06B6D4); // cyan
    return const Color(0xFF6366F1); // indigo default
  }
}
