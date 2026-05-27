import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../screens/home/home_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Management"),
        elevation: 0,
        backgroundColor: AppTheme.colorSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Header ─────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
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
                            fontSize: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Arjun Mehta",
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "arjun.mehta@example.com",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.colorPrimaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Primary Account Holder",
                        style: TextStyle(
                          color: AppTheme.colorPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Family Members Section ──────────────────────────────────
              Text("Family & Patients", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              _buildFamilyList(context),
              const SizedBox(height: 28),

              // ── Personal Information & Insurance ────────────────────────
              Text("Account Settings", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              _buildSettingItem(
                context: context,
                icon: Icons.person_outline,
                title: "Personal Information",
                subtitle: "Edit name, email, phone number, address",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Personal Information editing is under development")),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                context: context,
                icon: Icons.health_and_safety_outlined,
                title: "Insurance & Coverage",
                subtitle: "View or update policy details",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Insurance integration details is under development")),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                context: context,
                icon: Icons.contact_emergency_outlined,
                title: "Emergency Contacts",
                subtitle: "Set contacts for instant notifications",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Emergency contacts settings is under development")),
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── General Preferences ──────────────────────────────────────
              Text("Preferences", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              _buildSettingItem(
                context: context,
                icon: Icons.notifications_none_outlined,
                title: "Notification Settings",
                subtitle: "Manage reminders, alert sounds & SMS alerts",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notification preferences is under development")),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                context: context,
                icon: Icons.lock_outline,
                title: "Security & Privacy",
                subtitle: "Change password, biometric login settings",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Security settings is under development")),
                  );
                },
              ),
              const SizedBox(height: 32),

              // ── Sign Out Button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.colorError,
                  side: const BorderSide(color: AppTheme.colorError),
                ).buildElevated(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Sign-out process is under development")),
                    );
                  },
                  child: const Text("Sign Out"),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildFamilyList(BuildContext context) {
    final family = [
      {"name": "Meera Mehta", "relation": "Spouse", "initials": "MM"},
      {"name": "Ramesh Mehta", "relation": "Father (Physiotherapy patient)", "initials": "RM"},
      {"name": "Kavita Mehta", "relation": "Mother", "initials": "KM"},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Column(
        children: [
          ...family.map((member) => Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.colorDivider)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppTheme.colorPrimaryLight,
                foregroundColor: AppTheme.colorPrimary,
                child: Text(member["initials"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text(member["name"]!, style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(member["relation"]!, style: Theme.of(context).textTheme.bodyMedium),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.colorTextMuted),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${member["name"]}'s health records is under development")),
                );
              },
            ),
          )),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: AppTheme.colorSuccessLight,
              foregroundColor: AppTheme.colorSuccess,
              child: Icon(Icons.add),
            ),
            title: const Text("Add New Family Member", style: TextStyle(color: AppTheme.colorSuccess, fontWeight: FontWeight.bold)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Add family member feature is under development")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
                color: AppTheme.colorPrimaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppTheme.colorPrimary, size: 22),
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
            const Icon(Icons.chevron_right, color: AppTheme.colorTextMuted),
          ],
        ),
      ),
    );
  }
}

// Extension to simulate modern button styling if using standard classes
extension on ButtonStyle {
  Widget buildElevated({required VoidCallback onPressed, required Widget child}) {
    return OutlinedButton(
      style: this,
      onPressed: onPressed,
      child: child,
    );
  }
}
