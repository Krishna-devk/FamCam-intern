import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checkout_result.dart';
import '../models/cart_item.dart';
import 'slots_provider.dart';

class CheckoutState {
  final bool isLoading;
  final CheckoutResult? result;
  final String? errorMessage;

  CheckoutState({
    required this.isLoading,
    this.result,
    this.errorMessage,
  });

  factory CheckoutState.initial() => CheckoutState(isLoading: false);
  factory CheckoutState.loading() => CheckoutState(isLoading: true);
  factory CheckoutState.success(CheckoutResult res) => CheckoutState(isLoading: false, result: res);
  factory CheckoutState.failure(String msg) => CheckoutState(isLoading: false, errorMessage: msg);
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref _ref;

  CheckoutNotifier(this._ref) : super(CheckoutState.initial());

  Future<CheckoutResult?> submit(int patientId, List<CartItem> items) async {
    state = CheckoutState.loading();
    try {
      final client = _ref.read(apiClientProvider);
      final res = await client.postCheckout(patientId, items);
      state = CheckoutState.success(res);
      return res;
    } catch (e) {
      state = CheckoutState.failure(e.toString());
      return null;
    }
  }
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(ref);
});
