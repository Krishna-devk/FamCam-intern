import 'package:flutter_riverpod/flutter_riverpod.dart';

// Demo session state: selected patient profile used for slot lookup and checkout.
final selectedPatientIdProvider = StateProvider<int>((ref) => 1);

