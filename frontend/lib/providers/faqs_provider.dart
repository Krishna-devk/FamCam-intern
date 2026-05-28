import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'slots_provider.dart' show apiClientProvider;

class FAQsNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    List<Map<String, dynamic>>? cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_faqs');
      if (cachedJson != null) {
        final List decoded = jsonDecode(cachedJson);
        cached = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {
      // Ignore cache loading errors
    }

    if (cached != null && cached.isNotEmpty) {
      // Fetch fresh data in background
      _fetchFreshData();
      return cached;
    }

    return _fetchDirect();
  }

  Future<List<Map<String, dynamic>>> _fetchDirect() async {
    final client = ref.watch(apiClientProvider);
    final faqs = await client.getFAQs();
    _saveToCache(faqs);
    return faqs;
  }

  void _fetchFreshData() async {
    try {
      final fresh = await _fetchDirect();
      state = AsyncValue.data(fresh);
    } catch (_) {
      // Keep cached data silently if network fails
    }
  }

  void _saveToCache(List<Map<String, dynamic>> faqs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(faqs);
      await prefs.setString('cached_faqs', jsonStr);
    } catch (_) {}
  }
}

final faqsProvider = AsyncNotifierProvider.autoDispose<FAQsNotifier, List<Map<String, dynamic>>>(() {
  return FAQsNotifier();
});
