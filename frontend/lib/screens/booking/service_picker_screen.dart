import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/service.dart';
import '../../providers/slots_provider.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/service_icon_helper.dart';
import '../home/home_screen.dart' show AppBottomNav;

class ServicePickerScreen extends ConsumerStatefulWidget {
  const ServicePickerScreen({super.key});

  @override
  ConsumerState<ServicePickerScreen> createState() => _ServicePickerScreenState();
}

class _ServicePickerScreenState extends ConsumerState<ServicePickerScreen> {
  int? _selectedServiceId;
  Service? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Book a Service"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.colorBorder),
        ),
      ),
      body: servicesAsync.when(
        loading: () => _buildShimmerList(),
        error: (err, stack) => _buildErrorState(),
        data: (servicesData) => _buildContent(servicesData.cast<Service>()),
      ),
      bottomNavigationBar: _selectedServiceId != null
          ? _buildBottomBar()
          : const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildShimmerList() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        ...List.generate(4, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: ShimmerCard(),
        )),
      ],
    );
  }

  Widget _buildContent(List<Service> services) {
    if (services.isEmpty) {
      return _buildNoServicesState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          // ── Services grid ───────────────────────────────────────────
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final isSelected = _selectedServiceId == service.id;
              final serviceColor = ServiceIconHelper.colorFor(service.name);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: AppTheme.colorSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? serviceColor : AppTheme.colorBorder,
                      width: isSelected ? 2 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: serviceColor.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            )
                          ]
                        : [],
                  ),
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedServiceId = service.id;
                      _selectedService = service;
                    }),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          // Icon box
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? serviceColor.withValues(alpha: 0.12)
                                  : AppTheme.colorBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              ServiceIconHelper.iconFor(service.name),
                              color: isSelected ? serviceColor : AppTheme.colorTextMuted,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        service.name,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppTheme.formatPrice(service.priceCents),
                                      style: TextStyle(
                                        color: isSelected ? serviceColor : AppTheme.colorPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _InfoChip(
                                      icon: Icons.timer_outlined,
                                      label: "${service.durationMinutes} min",
                                    ),
                                    const SizedBox(width: 8),
                                    const _InfoChip(
                                      icon: Icons.verified_outlined,
                                      label: "Certified",
                                      color: AppTheme.colorSuccess,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: serviceColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Date Picker section ─────────────────────────────────────
          if (_selectedServiceId != null) ...[
            const Divider(color: AppTheme.colorBorder, height: 40),
            Text("Select Date", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              "Available dates from tomorrow up to 30 days ahead",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Horizontal date strip
            SizedBox(
              height: 84,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 30,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index + 1));
                  final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
                      DateFormat('yyyy-MM-dd').format(date);

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.colorPrimary : AppTheme.colorSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.colorPrimary : AppTheme.colorBorder,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDate = date),
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(date).toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white.withValues(alpha: 0.7) : AppTheme.colorTextMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 100), // space for bottom bar
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.colorTextMuted),
            const SizedBox(height: 12),
            Text("Unable to load services", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              "Please check your backend connection and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.colorTextMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(servicesProvider),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoServicesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services_outlined, size: 48, color: AppTheme.colorTextMuted),
            const SizedBox(height: 12),
            Text("No services available", style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What service\ndo you need?", style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(
          "Select from our 8 specialized healthcare services",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final serviceColor = ServiceIconHelper.colorFor(_selectedService?.name ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            if (_selectedService != null)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: serviceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(ServiceIconHelper.iconFor(_selectedService!.name), color: serviceColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedService!.name, style: Theme.of(context).textTheme.labelLarge),
                        Text(
                          "${DateFormat('EEE, d MMM').format(_selectedDate)}  ·  ${AppTheme.formatPrice(_selectedService!.priceCents)}",
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedService != null) {
                    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                    context.push('/book/slots', extra: {
                      'serviceId': _selectedService!.id,
                      'serviceName': _selectedService!.name,
                      'durationMinutes': _selectedService!.durationMinutes,
                      'priceCents': _selectedService!.priceCents,
                      'dateStr': dateStr,
                      'dateTime': _selectedDate,
                    });
                  }
                },
                child: const Text("Find Available Slots"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.colorTextMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
