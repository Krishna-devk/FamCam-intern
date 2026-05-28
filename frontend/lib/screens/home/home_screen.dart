import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../widgets/service_icon_helper.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.length;
    final patientId = ref.watch(selectedPatientIdProvider);
    final bookingsAsync = ref.watch(bookingsProvider(patientId));
    final session = ref.watch(sessionProvider).value;
    final userName = session?.name ?? "";
    final initials = userName.isNotEmpty ? userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join().toUpperCase() : "";
    final initialsSafe = initials.isNotEmpty ? (initials.length > 2 ? initials.substring(0, 2) : initials) : "U";

    final bookingsList = bookingsAsync.value ?? [];
    
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    
    final dailyCounts = List<int>.filled(7, 0);
    int currentWeekCount = 0;
    
    for (final b in bookingsList) {
      final bDate = DateTime(b.date.year, b.date.month, b.date.day);
      final diff = bDate.difference(startOfWeek).inDays;
      if (diff >= 0 && diff < 7) {
        dailyCounts[diff]++;
        currentWeekCount++;
      }
    }
    
    final maxCount = dailyCounts.reduce((a, b) => a > b ? a : b);
    final List<double> heights = List.generate(7, (index) {
      if (maxCount == 0) return 0.1; 
      return 0.1 + (0.85 * (dailyCounts[index] / maxCount)); 
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.colorPrimary, Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initialsSafe,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            userName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Notification bell
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.colorBorder),
                      color: AppTheme.colorSurface,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: AppTheme.colorTextPrimary),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Hero Gradient Card ───────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.colorPrimary.withValues(alpha: 0.25),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Your Weekly Activity",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Text(
                            "● Active",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$currentWeekCount services scheduled this week",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (index) {
                          final barHeight = 100 * heights[index];
                          final count = dailyCounts[index];
                          return Tooltip(
                            message: "$count ${count == 1 ? 'booking' : 'bookings'}",
                            preferBelow: false,
                            triggerMode: TooltipTriggerMode.tap,
                            decoration: BoxDecoration(
                              color: AppTheme.colorPrimary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            child: Container(
                              width: 14,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: count > 0 ? Colors.white : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Day labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) {
                        return Text(
                          d,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Metric Row ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: "This Week",
                      value: "$currentWeekCount Services",
                      icon: Icons.calendar_today_outlined,
                      color: AppTheme.colorPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: "Upcoming",
                      value: "${bookingsList.length} Services",
                      icon: Icons.event_available_outlined,
                      color: AppTheme.colorSuccess,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: "Cart",
                      value: "$cartCount items",
                      icon: Icons.shopping_bag_outlined,
                      color: cartCount > 0 ? AppTheme.colorWarning : AppTheme.colorTextMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Quick Actions ────────────────────────────────────────
              Text("Quick Actions", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),

              _ActionTile(
                title: "Book New Appointment",
                subtitle: "Choose a healthcare service & caregiver",
                icon: Icons.add_circle_outline,
                color: AppTheme.colorPrimary,
                onTap: () => context.push('/book/service'),
              ),
              const SizedBox(height: 12),
              _ActionTile(
                title: cartCount > 0
                    ? "Review Cart ($cartCount item${cartCount == 1 ? '' : 's'})"
                    : "Review Cart",
                subtitle: cartCount > 0
                    ? "Ready to confirm your bookings"
                    : "Your cart is empty",
                icon: Icons.shopping_cart_outlined,
                color: cartCount > 0 ? AppTheme.colorSuccess : AppTheme.colorTextMuted,
                badge: cartCount > 0 ? cartCount : null,
                onTap: () => context.push('/cart'),
              ),
              const SizedBox(height: 12),
              _ActionTile(
                title: "Explore All Services",
                subtitle: "Browse our services",
                icon: Icons.explore_outlined,
                color: AppTheme.colorWarning,
                onTap: () => context.push('/explore'),
              ),
              const SizedBox(height: 32),

              // ── Upcoming Section ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Coming Up", style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(bookingsProvider(patientId));
                    },
                    child: const Text("Refresh", style: TextStyle(color: AppTheme.colorPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              bookingsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.colorPrimary)),
                ),
                error: (err, stack) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.colorBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.colorBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_off, color: AppTheme.colorTextMuted),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Offline Mode. Enable network to sync schedules.",
                          style: TextStyle(color: AppTheme.colorTextMuted, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (bookingsList) {
                  if (bookingsList.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.colorBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.colorBorder),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: AppTheme.colorTextMuted, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            "No upcoming appointments scheduled.",
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Tap 'Book New Appointment' to schedule care.",
                            style: TextStyle(color: AppTheme.colorTextMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  // Take only the next 3 bookings for clean dashboard presentation
                  final displayList = bookingsList.take(3).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final booking = displayList[index];
                      final serviceColor = ServiceIconHelper.colorFor(booking.serviceName);
                      final serviceIcon = ServiceIconHelper.iconFor(booking.serviceName);
                      final formattedDate = DateFormat('EEEE, d MMMM').format(booking.date);
                      final dateLabel = "$formattedDate, ${booking.startTime}";

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _UpcomingCard(
                          bookingId: booking.bookingId,
                          service: booking.serviceName,
                          caregiver: booking.caregiverName,
                          dateLabel: dateLabel,
                          color: serviceColor,
                          icon: serviceIcon,
                          onCancel: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Cancel Booking?"),
                                content: Text("Are you sure you want to cancel your scheduled ${booking.serviceName}?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("No, Keep"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colorError),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await ref
                                    .read(bookingsProvider(patientId).notifier)
                                    .cancelBooking(booking.bookingId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Booking cancelled successfully."),
                                      backgroundColor: AppTheme.colorSuccess,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: ${e.toString()}"),
                                      backgroundColor: AppTheme.colorError,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 0),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.colorSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.colorBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (badge != null && badge! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.colorPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: AppTheme.colorTextMuted),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final int bookingId;
  final String service;
  final String caregiver;
  final String dateLabel;
  final Color color;
  final IconData icon;
  final VoidCallback? onCancel;

  const _UpcomingCard({
    required this.bookingId,
    required this.service,
    required this.caregiver,
    required this.dateLabel,
    required this.color,
    required this.icon,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text("with $caregiver", style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined, size: 13, color: AppTheme.colorTextMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: const TextStyle(fontSize: 12, color: AppTheme.colorTextMuted, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.colorSuccessLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Confirmed",
                  style: TextStyle(color: AppTheme.colorSuccess, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: AppTheme.colorError, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared Bottom Nav ─────────────────────────────────────────────────────────

class _BottomNav extends ConsumerWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).length;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.colorSurface,
        border: Border(top: BorderSide(color: AppTheme.colorBorder)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: AppTheme.colorSurface,
        indicatorColor: AppTheme.colorPrimaryLight,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/home'); break;
            case 1: context.go('/explore'); break;
            case 2: context.go('/cart'); break;
            case 3: context.go('/profile'); break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.colorPrimary),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppTheme.colorPrimary),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart, color: AppTheme.colorPrimary),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.colorPrimary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Export BottomNav for reuse ─────────────────────────────────────────────────
class AppBottomNav extends ConsumerWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BottomNav(currentIndex: currentIndex);
  }
}
