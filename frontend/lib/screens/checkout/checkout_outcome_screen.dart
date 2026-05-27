import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/checkout_result.dart';

class CheckoutOutcomeScreen extends StatefulWidget {
  final CheckoutResult result;
  const CheckoutOutcomeScreen({super.key, required this.result});

  @override
  State<CheckoutOutcomeScreen> createState() => _CheckoutOutcomeScreenState();
}

class _CheckoutOutcomeScreenState extends State<CheckoutOutcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _ringController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _ring1;
  late final Animation<double> _ring2;
  late final Animation<double> _ring3;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Staggered ripple rings
    _ring1 = CurvedAnimation(
      parent: _ringController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _ring2 = CurvedAnimation(
      parent: _ringController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    );
    _ring3 = CurvedAnimation(
      parent: _ringController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _ringController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.result is! CheckoutSuccess) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.colorError),
              const SizedBox(height: 16),
              Text("Booking failed", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/cart'),
                child: const Text("Back to Cart"),
              ),
            ],
          ),
        ),
      );
    }

    final success = widget.result as CheckoutSuccess;

    return Scaffold(
      backgroundColor: AppTheme.colorBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── Animated Ripple Success Icon ─────────────────────────
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer rings
                    _buildRing(_ring3, 196, AppTheme.colorSuccess.withValues(alpha: 0.07)),
                    _buildRing(_ring2, 160, AppTheme.colorSuccess.withValues(alpha: 0.10)),
                    _buildRing(_ring1, 124, AppTheme.colorSuccess.withValues(alpha: 0.13)),
                    // Check icon
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: AppTheme.colorSuccess,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 52),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Title ────────────────────────────────────────────────
              Text(
                "Booking Confirmed! 🎉",
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "${success.bookingIds.length} healthcare service${success.bookingIds.length == 1 ? '' : 's'} scheduled successfully.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Booking reference
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.colorSuccessLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Ref: #${success.bookingIds.join(', #')}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.colorSuccess,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Booking Receipt Card ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.colorSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.colorBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Booking Summary", style: Theme.of(context).textTheme.titleMedium),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.colorPrimaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${success.items.length} service${success.items.length == 1 ? '' : 's'}",
                            style: const TextStyle(
                              color: AppTheme.colorPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.colorBorder, height: 28),

                    // Items
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: success.items.length,
                      separatorBuilder: (_, __) => const Divider(color: AppTheme.colorDivider, height: 20),
                      itemBuilder: (context, index) {
                        final item = success.items[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.colorPrimaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.medical_services_outlined, color: AppTheme.colorPrimary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.serviceName, style: Theme.of(context).textTheme.labelLarge),
                                  const SizedBox(height: 2),
                                  Text(
                                    "with ${item.caregiverName}",
                                    style: const TextStyle(fontSize: 12, color: AppTheme.colorTextMuted),
                                  ),
                                  Text(
                                    "${DateFormat('d MMM yyyy').format(item.date)}  ·  ${item.startTime} – ${item.endTime}",
                                    style: const TextStyle(fontSize: 12, color: AppTheme.colorTextMuted),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppTheme.formatPrice(item.priceCents),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.colorTextPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const Divider(color: AppTheme.colorBorder, height: 28),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Paid", style: Theme.of(context).textTheme.titleMedium),
                            const Text("Platform fee: Free", style: TextStyle(fontSize: 12, color: AppTheme.colorTextMuted)),
                          ],
                        ),
                        Text(
                          AppTheme.formatPrice(success.totalPriceCents),
                          style: const TextStyle(
                            color: AppTheme.colorPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Tip Banner ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.colorWarningLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.colorWarning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.colorWarning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Your caregivers will call 30 min before arrival. Keep your phone nearby.",
                        style: TextStyle(fontSize: 13, color: AppTheme.colorWarning.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Actions ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home_outlined, size: 20),
                  label: const Text("Back to Home"),
                  onPressed: () => context.go('/home'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text("Book More Services"),
                  onPressed: () => context.go('/book/service'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRing(Animation<double> animation, double size, Color color) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: 1 - animation.value,
          child: Container(
            width: size * animation.value,
            height: size * animation.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        );
      },
    );
  }
}
