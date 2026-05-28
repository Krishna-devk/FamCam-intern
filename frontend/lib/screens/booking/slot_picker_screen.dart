import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/available_slot.dart';
import '../../models/cart_item.dart';
import '../../models/service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/slots_provider.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/service_icon_helper.dart';

class SlotPickerScreen extends ConsumerStatefulWidget {
  final int serviceId;
  final String serviceName;
  final int durationMinutes;
  final int priceCents;
  final String dateStr;
  final DateTime dateTime;
  final List<Service>? pendingServices;

  const SlotPickerScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.durationMinutes,
    required this.priceCents,
    required this.dateStr,
    required this.dateTime,
    this.pendingServices,
  });

  @override
  ConsumerState<SlotPickerScreen> createState() => _SlotPickerScreenState();
}

class _SlotPickerScreenState extends ConsumerState<SlotPickerScreen>
    with TickerProviderStateMixin {
  DateTime? _selectedDate;
  String? _selectedSlotTime;
  Caregiver? _selectedCaregiver;

  late AnimationController _addController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.dateTime;

    _addController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  String _calcEnd(String start, int duration) {
    final parts = start.split(':');
    final minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]) + duration;
    return '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final patientId = ref.watch(selectedPatientIdProvider);
    final activeDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final searchArgs = SlotSearchArgs(
      serviceId: widget.serviceId,
      dateStr: activeDateStr,
      patientId: patientId,
    );
    final slotsAsync = ref.watch(availableSlotsProvider(searchArgs));
    final serviceColor = ServiceIconHelper.colorFor(widget.serviceName);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.colorError),
            tooltip: 'Drop Service',
            onPressed: _confirmDropItem,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.colorBorder),
        ),
      ),
      body: Column(
        children: [
          // ── Service Summary Banner ─────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: serviceColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: serviceColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: serviceColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(ServiceIconHelper.iconFor(widget.serviceName), color: serviceColor, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.serviceName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Row(
                      children: [
                        Text(
                          "${widget.durationMinutes} min  ·  ",
                          style: const TextStyle(color: AppTheme.colorTextMuted, fontSize: 13),
                        ),
                        Text(
                          AppTheme.formatPrice(widget.priceCents),
                          style: TextStyle(color: serviceColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 7-Day Date Rail ────────────────────────────────────────
          const SizedBox(height: 16),
          _buildDateRail(),

          // ── Slots Content ──────────────────────────────────────────
          Expanded(
            child: slotsAsync.when(
              loading: () => _buildShimmerSlots(),
              error: (e, st) {
                return _buildSlotsErrorState();
              },
              data: (data) => _buildSlotsContent(data),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedSlotTime != null
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildSlotsErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.colorTextMuted),
            const SizedBox(height: 12),
            Text("Unable to load slots", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              "Please retry after checking backend connectivity.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.colorTextMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final activeDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
                final patientId = ref.read(selectedPatientIdProvider);
                ref.invalidate(
                  availableSlotsProvider(
                    SlotSearchArgs(
                      serviceId: widget.serviceId,
                      dateStr: activeDateStr,
                      patientId: patientId,
                    ),
                  ),
                );
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRail() {
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: AppTheme.colorSurface,
        border: Border(
          bottom: BorderSide(color: AppTheme.colorBorder),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index + 1));
          final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDate!) ==
              DateFormat('yyyy-MM-dd').format(date);

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 54,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.colorPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.colorPrimary : AppTheme.colorBorder,
                ),
              ),
              child: InkWell(
                onTap: () => setState(() {
                  _selectedDate = date;
                  _selectedSlotTime = null;
                  _selectedCaregiver = null;
                }),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E').format(date).toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppTheme.colorTextMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d').format(date),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.colorTextPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerSlots() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 140, height: 22, borderRadius: 8),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(8, (_) => const ShimmerBox(width: 80, height: 44, borderRadius: 12)),
          ),
          const SizedBox(height: 32),
          const ShimmerBox(width: 160, height: 22, borderRadius: 8),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerCard(),
          )),
        ],
      ),
    );
  }

  Widget _buildSlotsContent(List<AvailableSlot> slots) {
    if (slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.colorBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.colorBorder),
                ),
                child: const Icon(Icons.event_busy_outlined, size: 48, color: AppTheme.colorTextMuted),
              ),
              const SizedBox(height: 20),
              Text("No slots available", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text(
                "Please select a different date to see available slots.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.colorTextMuted),
              ),
            ],
          ),
        ),
      );
    }

    final activeSlot = slots.firstWhere(
      (s) => s.startTime == _selectedSlotTime,
      orElse: () => slots.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Slot time chips ────────────────────────────────────────
          Text(
            "Available Times",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: slots.map((slot) {
              final isSelected = _selectedSlotTime == slot.startTime;
              return InkWell(
                onTap: () => setState(() {
                  _selectedSlotTime = slot.startTime;
                  _selectedCaregiver = null;
                }),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.colorPrimary : AppTheme.colorSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.colorPrimary : AppTheme.colorBorder,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppTheme.colorPrimary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(
                        slot.startTime,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.colorTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        slot.endTime,
                        style: TextStyle(
                          color: isSelected ? Colors.white.withValues(alpha: 0.7) : AppTheme.colorTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // ── Caregiver selection ────────────────────────────────────
          if (_selectedSlotTime != null) ...[
            const SizedBox(height: 28),
            Text("Select Your Caregiver", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              "${activeSlot.availableCaregivers.length} caregivers available at this time",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Auto-Assign Option
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _selectedCaregiver = null),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.colorSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedCaregiver == null ? AppTheme.colorSuccess : AppTheme.colorBorder,
                      width: _selectedCaregiver == null ? 2 : 1.0,
                    ),
                    boxShadow: _selectedCaregiver == null
                        ? [BoxShadow(color: AppTheme.colorSuccess.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.colorSuccess.withValues(alpha: 0.12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.bolt,
                            color: AppTheme.colorSuccess,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Auto-Assign Caregiver",
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                    color: _selectedCaregiver == null ? AppTheme.colorSuccess : AppTheme.colorTextPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "System will assign the best matching verified nurse",
                              style: TextStyle(fontSize: 12, color: AppTheme.colorTextMuted),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedCaregiver == null)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.colorSuccess,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.colorBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.colorBorder),
                          ),
                          child: const Text(
                            "Select",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.colorSuccess),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeSlot.availableCaregivers.length,
              itemBuilder: (context, index) {
                final cg = activeSlot.availableCaregivers[index];
                final isSelected = _selectedCaregiver?.id == cg.id;
                final initials = cg.name.split(' ').map((n) => n[0]).join().toUpperCase();
                // Give each caregiver a deterministic color based on id
                final colors = [
                  AppTheme.colorPrimary, AppTheme.colorSuccess, AppTheme.colorWarning,
                  const Color(0xFF8B5CF6), const Color(0xFF06B6D4), const Color(0xFFEF4444),
                ];
                final cgColor = colors[cg.id % colors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => setState(() {
                      if (_selectedCaregiver?.id == cg.id) {
                        _selectedCaregiver = null;
                      } else {
                        _selectedCaregiver = cg;
                      }
                    }),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.colorSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.colorPrimary : AppTheme.colorBorder,
                          width: isSelected ? 2 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppTheme.colorPrimary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cgColor.withValues(alpha: 0.12),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  color: cgColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cg.name, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 2),
                                const Row(
                                  children: [
                                    Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                                    SizedBox(width: 3),
                                    Text(
                                      "4.8  ·  Certified Nurse",
                                      style: TextStyle(fontSize: 12, color: AppTheme.colorTextMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.colorPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 14),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.colorBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.colorBorder),
                              ),
                              child: const Text(
                                "Select",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.colorPrimary),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 90), // space for bottom bar
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.colorSurface,
        border: Border(top: BorderSide(color: AppTheme.colorBorder)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.colorBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.colorBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppTheme.colorPrimary),
                  const SizedBox(width: 8),
                  Text(
                    "$_selectedSlotTime – ${_calcEnd(_selectedSlotTime!, widget.durationMinutes)}",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Spacer(),
                  const Icon(Icons.person_outline, size: 16, color: AppTheme.colorTextMuted),
                  const SizedBox(width: 6),
                  Text(
                    _selectedCaregiver != null 
                        ? _selectedCaregiver!.name.split(' ').first 
                        : 'Auto-Assign',
                    style: TextStyle(
                      fontSize: 13, 
                      fontWeight: _selectedCaregiver == null ? FontWeight.w600 : FontWeight.normal,
                      color: _selectedCaregiver == null ? AppTheme.colorSuccess : AppTheme.colorTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppTheme.formatPrice(widget.priceCents),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.colorPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                label: const Text("Add to Cart"),
                onPressed: _addToCart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart() {
    if (_selectedSlotTime == null) return;

    final patientId = ref.read(selectedPatientIdProvider);
    final activeDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final searchArgs = SlotSearchArgs(
      serviceId: widget.serviceId,
      dateStr: activeDateStr,
      patientId: patientId,
    );
    final slotsAsync = ref.read(availableSlotsProvider(searchArgs));
    final slots = slotsAsync.value ?? [];
    if (slots.isEmpty) return;

    final activeSlot = slots.firstWhere(
      (s) => s.startTime == _selectedSlotTime,
      orElse: () => slots.first,
    );

    final finalCaregiver = _selectedCaregiver ?? 
        (activeSlot.availableCaregivers.isNotEmpty ? activeSlot.availableCaregivers.first : null);
    
    if (finalCaregiver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No caregiver is available for this slot."),
          backgroundColor: AppTheme.colorWarning,
        ),
      );
      return;
    }

    final parts = _selectedSlotTime!.split(':');
    final startTOD = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final cartItem = CartItem(
      serviceId: widget.serviceId,
      serviceName: widget.serviceName,
      caregiverId: finalCaregiver.id,
      caregiverName: finalCaregiver.name,
      date: _selectedDate!,
      startTime: startTOD,
      durationMinutes: widget.durationMinutes,
      priceCents: widget.priceCents,
    );

    ref.read(cartProvider.notifier).addItem(cartItem);

    _addController.forward(from: 0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.colorSuccess,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "${widget.serviceName} added to cart!",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                context.push('/cart');
              },
              child: const Text("View Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (widget.pendingServices != null && widget.pendingServices!.isNotEmpty) {
      final nextService = widget.pendingServices!.first;
      final remaining = widget.pendingServices!.sublist(1);
      
      context.pushReplacement('/book/slots', extra: {
        'serviceId': nextService.id,
        'serviceName': nextService.name,
        'durationMinutes': nextService.durationMinutes,
        'priceCents': nextService.priceCents,
        'dateStr': widget.dateStr,
        'dateTime': widget.dateTime,
        'pendingServices': remaining,
      });
    } else {
      context.go('/home');
    }
  }

  void _confirmDropItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Drop Service"),
        content: Text("Are you sure you want to cancel adding ${widget.serviceName}?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close dialog
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _dropItem();
            },
            child: const Text("Drop", style: TextStyle(color: AppTheme.colorError, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _dropItem() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Cancelled ${widget.serviceName}."),
        backgroundColor: AppTheme.colorTextMuted,
        duration: const Duration(seconds: 2),
      ),
    );

    if (widget.pendingServices != null && widget.pendingServices!.isNotEmpty) {
      final nextService = widget.pendingServices!.first;
      final remaining = widget.pendingServices!.sublist(1);
      
      context.pushReplacement('/book/slots', extra: {
        'serviceId': nextService.id,
        'serviceName': nextService.name,
        'durationMinutes': nextService.durationMinutes,
        'priceCents': nextService.priceCents,
        'dateStr': widget.dateStr,
        'dateTime': widget.dateTime,
        'pendingServices': remaining,
      });
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }
}
