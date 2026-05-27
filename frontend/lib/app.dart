import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'models/checkout_result.dart';
import 'screens/home/home_screen.dart';
import 'screens/booking/service_picker_screen.dart';
import 'screens/booking/slot_picker_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_outcome_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/profile/profile_screen.dart';

class FamCareApp extends StatelessWidget {
  const FamCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) => const ExploreScreen(),
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
      ],
    );

    return MaterialApp.router(
      title: 'FamCare – Home Healthcare Scheduler',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
