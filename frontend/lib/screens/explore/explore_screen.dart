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

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

    final List<Service> fallbackServices = [
      Service(id: 1, name: "Physiotherapy",           durationMinutes: 60,  priceCents: 8000,  description: "Physiological rehabilitation and movement therapy"),
      Service(id: 2, name: "Wound Dressing",          durationMinutes: 30,  priceCents: 4000,  description: "Cleaning and dressing of post-surgery wounds"),
      Service(id: 3, name: "Medication Review",       durationMinutes: 45,  priceCents: 5500,  description: "Clinical alignment of medication schedule"),
      Service(id: 4, name: "Elderly Companion Care",  durationMinutes: 90,  priceCents: 6000,  description: "Social and companion care for elderly patients"),
      Service(id: 5, name: "Occupational Therapy",    durationMinutes: 60,  priceCents: 8500,  description: "Daily activity coordination therapy"),
      Service(id: 6, name: "Post-Surgical Nursing",   durationMinutes: 120, priceCents: 12000, description: "High-care post-surgical support"),
      Service(id: 7, name: "Dietary & Nutrition Consult", durationMinutes: 45, priceCents: 5000, description: "Personalized meal and diet plans"),
      Service(id: 8, name: "Vital Signs Monitoring",  durationMinutes: 15,  priceCents: 2000,  description: "Regular blood pressure, sugar and pulse check"),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Explore Services"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.colorBorder),
        ),
      ),
      body: servicesAsync.when(
        loading: () => _buildShimmer(),
        error: (_, __) => _buildGrid(context, fallbackServices),
        data: (data) => _buildGrid(context, data.isNotEmpty ? data.cast<Service>() : fallbackServices),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppTheme.colorSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.colorBorder),
        ),
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: 48, height: 48, borderRadius: 14),
            SizedBox(height: 14),
            ShimmerBox.expand(height: 16, borderRadius: 8),
            SizedBox(height: 8),
            ShimmerBox(width: 80, height: 12, borderRadius: 6),
            Spacer(),
            ShimmerBox.expand(height: 36, borderRadius: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Service> services) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "All Services",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  "${services.length} healthcare services available",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ServiceCard(service: services[index]),
              childCount: services.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final color = ServiceIconHelper.colorFor(service.name);
    final icon = ServiceIconHelper.iconFor(service.name);
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));
    final dateDT = DateTime.now().add(const Duration(days: 1));

    return InkWell(
      onTap: () => context.push('/book/slots', extra: {
        'serviceId': service.id,
        'serviceName': service.name,
        'durationMinutes': service.durationMinutes,
        'priceCents': service.priceCents,
        'dateStr': dateStr,
        'dateTime': dateDT,
      }),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.colorSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.colorBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              service.name,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 14),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              "${service.durationMinutes} min",
              style: const TextStyle(fontSize: 12, color: AppTheme.colorTextMuted),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTheme.formatPrice(service.priceCents),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_forward, color: color, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
