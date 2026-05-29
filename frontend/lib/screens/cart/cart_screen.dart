import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/cart_item.dart';
import '../../models/checkout_result.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/service_icon_helper.dart';
import '../home/home_screen.dart' show AppBottomNav;

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with TickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<CartItem> _listItems;
  final Map<int, AnimationController> _shakeControllers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listItems = List.from(ref.read(cartProvider));
  }

  void _removeItem(int index) {
    if (index >= 0 && index < _listItems.length) {
      final removedItem = _listItems.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildItemTile(removedItem, index, animation),
        duration: const Duration(milliseconds: 280),
      );
      ref.read(cartProvider.notifier).removeItem(index);
    }
  }

  @override
  void dispose() {
    for (var controller in _shakeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final totalCents = ref.watch(cartTotalProvider);
    final checkoutState = ref.watch(checkoutProvider);

    ref.listen<CheckoutState>(checkoutProvider, (previous, next) {
      if (!next.isLoading && next.result is CheckoutFailure) {
        final failure = next.result as CheckoutFailure;
        final failedIndex = failure.failedItemIndex;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.colorError,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Booking failed: ${failure.reasonCode}. See highlighted item below.",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );

        if (_shakeControllers.containsKey(failedIndex)) {
          _shakeControllers[failedIndex]!.forward(from: 0.0);
        } else {
          final controller = AnimationController(
            duration: const Duration(milliseconds: 400),
            vsync: this,
          );
          _shakeControllers[failedIndex] = controller;
          controller.forward(from: 0.0);
        }
      } else if (!next.isLoading && next.result is CheckoutSuccess) {
        context.pushReplacement('/checkout/outcome', extra: next.result);
        ref.read(cartProvider.notifier).clear();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(cart.isEmpty ? 'My Cart' : 'My Cart (${cart.length})'),
        actions: [
          if (cart.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.colorError),
              label: const Text("Clear", style: TextStyle(color: AppTheme.colorError)),
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
                setState(() => _listItems.clear());
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.colorBorder),
        ),
      ),
      body: cart.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: AnimatedList(
                    key: _listKey,
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    initialItemCount: _listItems.length,
                    itemBuilder: (context, index, animation) {
                      if (index >= _listItems.length) return const SizedBox.shrink();
                      return _buildItemTile(_listItems[index], index, animation);
                    },
                  ),
                ),
                _buildPriceStickyBar(totalCents, checkoutState.isLoading),
              ],
            ),
      bottomNavigationBar: cart.isEmpty ? const AppBottomNav(currentIndex: 2) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.colorPrimary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 64, color: AppTheme.colorPrimary),
            ),
            const SizedBox(height: 24),
            Text("Your cart is empty", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              "Add healthcare services and pick your preferred slots to get started.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text("Browse Services"),
                onPressed: () => context.pushReplacement('/book/service'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(CartItem item, int index, Animation<double> animation) {
    final checkoutState = ref.read(checkoutProvider);
    final isFailed = checkoutState.result is CheckoutFailure;
    final failure = isFailed ? checkoutState.result as CheckoutFailure : null;
    final isHighlighted = isFailed && failure?.failedItemIndex == index;
    final serviceColor = ServiceIconHelper.colorFor(item.serviceName);

    final controller = _shakeControllers.putIfAbsent(
      index,
      () => AnimationController(duration: const Duration(milliseconds: 400), vsync: this),
    );

    final shakeAnim = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(controller);

    return SizeTransition(
      sizeFactor: animation,
      child: AnimatedBuilder(
        animation: shakeAnim,
        builder: (context, child) {
          final dx = sin(shakeAnim.value * pi) * 7;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: Dismissible(
          key: ValueKey('${item.serviceId}-${item.date}-${item.startTimeFormatted}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _removeItem(index),
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.colorError,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_forever, color: Colors.white, size: 28),
                SizedBox(height: 4),
                Text("Remove", style: TextStyle(color: Colors.white, fontSize: 11)),
              ],
            ),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.colorSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHighlighted ? AppTheme.colorError : AppTheme.colorBorder,
                width: isHighlighted ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Stack(
              children: [
                // Red left border for failed item
                if (isHighlighted)
                  Positioned(
                    top: 0, bottom: 0, left: 0,
                    child: Container(
                      width: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.colorError,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Service icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: serviceColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              ServiceIconHelper.iconFor(item.serviceName),
                              color: serviceColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.serviceName, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 2),
                                Text(
                                  "with ${item.caregiverName}",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, size: 20, color: AppTheme.colorTextMuted),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _removeItem(index),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppTheme.formatPrice(item.priceCents),
                                style: TextStyle(
                                  color: isHighlighted ? AppTheme.colorError : AppTheme.colorPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Date/time info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.colorBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.colorTextMuted),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEEE, d MMM').format(item.date),
                              style: const TextStyle(fontSize: 13, color: AppTheme.colorTextMuted, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time_outlined, size: 14, color: AppTheme.colorTextMuted),
                            const SizedBox(width: 6),
                            Text(
                              "${item.startTimeFormatted}  (${item.durationMinutes} min)",
                              style: const TextStyle(fontSize: 13, color: AppTheme.colorTextMuted, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),

                      // Conflict error badge
                      if (isHighlighted && failure != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.colorErrorLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppTheme.colorError, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.colorError,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        failure.reasonCode,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      failure.message,
                                      style: const TextStyle(
                                        color: AppTheme.colorError,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceStickyBar(int totalCents, bool isLoading) {
    final patientId = ref.watch(selectedPatientIdProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        border: const Border(top: BorderSide(color: AppTheme.colorBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_listItems.length} service${_listItems.length == 1 ? '' : 's'} selected",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  AppTheme.formatPrice(totalCents),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.colorTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Platform fee", style: TextStyle(fontSize: 12, color: AppTheme.colorTextMuted)),
                Text("Free", style: TextStyle(fontSize: 12, color: AppTheme.colorSuccess, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => ref.read(checkoutProvider.notifier).submit(patientId, _listItems),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text("Confirm Booking"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
