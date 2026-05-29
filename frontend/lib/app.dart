import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'models/checkout_result.dart';
import 'models/service.dart';
import 'screens/home/home_screen.dart';
import 'screens/booking/service_picker_screen.dart';
import 'screens/booking/slot_picker_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_outcome_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/personal_info_screen.dart';
import 'screens/profile/security_privacy_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'providers/session_provider.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen(sessionProvider, (_, __) {
      notifyListeners();
    });
  }
  final Ref ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/auth', // Start at auth so we don't flash home screen when logged out
    refreshListenable: notifier,
    redirect: (context, state) {
      final sessionAsync = ref.read(sessionProvider);
      
      if (sessionAsync.isLoading) return null;

      final isLoggedIn = sessionAsync.value != null;
      final isLoggingIn = state.matchedLocation == '/auth';

      if (!isLoggedIn && !isLoggingIn) {
        return '/auth';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/explore',
        builder: (context, state) {
          final searchQuery = state.extra as String?;
          return ExploreScreen(searchQuery: searchQuery);
        },
      ),
      GoRoute(
        path: '/book/service',
        builder: (context, state) => const ServicePickerScreen(),
      ),
      GoRoute(
        path: '/book/slots',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return SlotPickerScreen(
            serviceId: args['serviceId'] as int,
            serviceName: args['serviceName'] as String,
            durationMinutes: args['durationMinutes'] as int,
            priceCents: args['priceCents'] as int,
            dateStr: args['dateStr'] as String,
            dateTime: args['dateTime'] as DateTime,
            pendingServices: args['pendingServices'] as List<Service>?,
          );
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout/outcome',
        builder: (context, state) {
          final result = state.extra as CheckoutResult;
          return CheckoutOutcomeScreen(result: result);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/personal-info',
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/profile/security-privacy',
        builder: (context, state) => const SecurityPrivacyScreen(),
      ),
    ],
  );
});

class FamCareApp extends ConsumerWidget {
  const FamCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FamCare – Home Healthcare Scheduler',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
