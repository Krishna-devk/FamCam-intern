import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/available_slot.dart';

// Host setup for local FastAPI backend
final apiClientProvider = Provider<ApiClient>((ref) {
  // Read dynamically from dart-define environment variable or default to Android Emulator localhost
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  return ApiClient(baseUrl: baseUrl); 
});

class SlotSearchArgs {
  final int serviceId;
  final String dateStr;
  final int patientId;

  SlotSearchArgs({
    required this.serviceId,
    required this.dateStr,
    required this.patientId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotSearchArgs &&
          runtimeType == other.runtimeType &&
          serviceId == other.serviceId &&
          dateStr == other.dateStr &&
          patientId == other.patientId;

  @override
  int get hashCode => serviceId.hashCode ^ dateStr.hashCode ^ patientId.hashCode;
}

final availableSlotsProvider = FutureProvider.family<List<AvailableSlot>, SlotSearchArgs>((ref, args) async {
  final client = ref.watch(apiClientProvider);
  return await client.getAvailableSlots(args.serviceId, args.dateStr, args.patientId);
});

// A simple provider to fetch services
final servicesProvider = FutureProvider<List>((ref) async {
  final client = ref.watch(apiClientProvider);
  return await client.getServices();
});
