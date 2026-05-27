import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers/cart_provider.dart';

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
                        child: const Center(
                          child: Text(
                            "AM",
                            style: TextStyle(
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
                            "Arjun Mehta",
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
                      "3 services scheduled this week",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: CustomPaint(painter: ChartPainter()),
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
                  const Expanded(
                    child: _MetricCard(
                      title: "Scheduled",
                      value: "3 Services",
                      icon: Icons.calendar_today_outlined,
                      color: AppTheme.colorPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _MetricCard(
                      title: "Fill Rate",
                      value: "65%",
                      icon: Icons.speed_outlined,
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
                subtitle: "Browse our 8 care categories",
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
                    onPressed: () {},
                    child: const Text("See all", style: TextStyle(color: AppTheme.colorPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _UpcomingCard(
                service: "Physiotherapy",
                caregiver: "Priya Sharma",
                dateLabel: "Tomorrow, 9:00 AM",
                color: AppTheme.colorPrimary,
                icon: Icons.accessibility_new_outlined,
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
  final String service;
  final String caregiver;
  final String dateLabel;
  final Color color;
  final IconData icon;

  const _UpcomingCard({
    required this.service,
    required this.caregiver,
    required this.dateLabel,
    required this.color,
    required this.icon,
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

// ── Chart Painter ─────────────────────────────────────────────────────────────

class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final activePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    const double barCount = 7;
    const double barWidth = 14;
    final double totalSpace = size.width - (barWidth * barCount);
    final double space = totalSpace / (barCount - 1);
    final heights = [0.4, 0.65, 0.5, 0.75, 0.95, 0.6, 0.7];

    for (int i = 0; i < 7; i++) {
      final double x = i * (barWidth + space);
      final double barHeight = size.height * heights[i];
      final double y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(8),
      );

      canvas.drawRRect(rect, i == 4 ? activePaint : dimPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
