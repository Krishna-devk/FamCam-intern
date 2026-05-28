import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/session_provider.dart';
import '../../providers/slots_provider.dart' show apiClientProvider;

class SecurityPrivacyScreen extends ConsumerStatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  ConsumerState<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends ConsumerState<SecurityPrivacyScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _obscureCurrentPassword = true;
    _obscureNewPassword = true;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.colorSurface,
            title: const Text("Change Password", style: TextStyle(color: AppTheme.colorTextPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
                TextField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: "Current Password",
                    filled: true,
                    fillColor: AppTheme.colorBg,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrentPassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.colorTextMuted),
                      onPressed: () {
                        setDialogState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    filled: true,
                    fillColor: AppTheme.colorBg,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.colorTextMuted),
                      onPressed: () {
                        setDialogState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final session = ref.read(sessionProvider).value;
                        if (session == null) return;
                        
                        setDialogState(() => _isLoading = true);
                        try {
                          final client = ref.read(apiClientProvider);
                          await client.changePassword(
                            session.id,
                            _currentPasswordController.text,
                            _newPasswordController.text,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Password updated successfully!")),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.colorError),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setDialogState(() => _isLoading = false);
                          }
                        }
                      },
                child: _isLoading 
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Save"),
              )
            ],
          );
        });
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.colorSurface,
            title: const Text("Delete Account", style: TextStyle(color: AppTheme.colorError)),
            content: const Text(
              "Are you sure you want to permanently delete your account? This action cannot be undone.",
              style: TextStyle(color: AppTheme.colorTextPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colorError),
                onPressed: _isLoading
                    ? null
                    : () async {
                        final session = ref.read(sessionProvider).value;
                        if (session == null) return;

                        setDialogState(() => _isLoading = true);
                        try {
                          final client = ref.read(apiClientProvider);
                          await client.deleteAccount(session.id);
                          await ref.read(sessionProvider.notifier).logout();
                          if (context.mounted) {
                            // We pop the dialog
                            Navigator.pop(context);
                            // Then we clear all routes and go to login
                            // Assuming there's a routing system handling the null session automatically
                            // or we just pop until first
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.colorError),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setDialogState(() => _isLoading = false);
                          }
                        }
                      },
                child: _isLoading 
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Delete"),
              )
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Security & Privacy"),
        backgroundColor: AppTheme.colorSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text("Login & Security", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildActionItem(
              icon: Icons.password,
              title: "Change Password",
              subtitle: "Update your account password",
              onTap: _showChangePasswordDialog,
            ),
            const SizedBox(height: 32),
            const Text("Privacy", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildActionItem(
              icon: Icons.delete_forever,
              title: "Delete Account",
              subtitle: "Permanently remove your account",
              isDestructive: true,
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.colorError : AppTheme.colorTextPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.colorSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDestructive ? AppTheme.colorError.withValues(alpha: 0.3) : AppTheme.colorBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
               child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.colorTextMuted)),
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
