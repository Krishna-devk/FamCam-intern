import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/session_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _name = '';
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;
  String _role = 'PATIENT'; // default to PATIENT for registration
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await ref.read(sessionProvider.notifier).login(_email.trim(), _password.trim());
        if (mounted) {
          context.go('/home');
        }
      } else {
        await ref.read(sessionProvider.notifier).register(
              _name.trim(),
              _email.trim(),
              _role,
              _password.trim(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration successful! Please log in."),
              backgroundColor: AppTheme.colorSuccess,
            ),
          );
          setState(() {
            _isLogin = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: AppTheme.colorError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF2563EB),
              Color(0xFF3B82F6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon / Logo Glow
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.health_and_safety,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "FamCare",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "Home Healthcare Scheduler",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Glassmorphic Auth Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tab selector
                          Row(
                            children: [
                              Expanded(
                                child: _buildTabButton(
                                  label: "Login",
                                  isSelected: _isLogin,
                                  onTap: () => setState(() => _isLogin = true),
                                ),
                              ),
                              Expanded(
                                child: _buildTabButton(
                                  label: "Register",
                                  isSelected: !_isLogin,
                                  onTap: () => setState(() => _isLogin = false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Form fields
                          if (!_isLogin) ...[
                            Text(
                              "Full Name",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              style: const TextStyle(color: AppTheme.colorTextPrimary),
                              decoration: AppTheme.inputDecoration(
                                hintText: "Enter your name",
                                prefixIcon: Icons.person_outline,
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? "Please enter your name"
                                  : null,
                              onSaved: (val) => _name = val ?? '',
                            ),
                            const SizedBox(height: 16),
                          ],

                          Text(
                            "Email Address",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: AppTheme.colorTextPrimary),
                            decoration: AppTheme.inputDecoration(
                              hintText: "Enter your email",
                              prefixIcon: Icons.email_outlined,
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return "Please enter your email";
                              }
                              final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!regex.hasMatch(val)) {
                                return "Please enter a valid email";
                              }
                              return null;
                            },
                            onSaved: (val) => _email = val ?? '',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Password",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: AppTheme.colorTextPrimary),
                            decoration: AppTheme.inputDecoration(
                              hintText: "Enter your password",
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.colorTextMuted,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (val) => val == null || val.length < 4
                                ? "Password must be at least 4 characters"
                                : null,
                            onSaved: (val) => _password = val ?? '',
                          ),

                          if (!_isLogin) ...[
                            const SizedBox(height: 18),
                            Text(
                              "Choose Your Role",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _RoleChip(
                                  label: "Patient",
                                  roleCode: "PATIENT",
                                  isSelected: _role == "PATIENT",
                                  icon: Icons.person_outline,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _role = "PATIENT");
                                  },
                                ),
                                const SizedBox(width: 12),
                                _RoleChip(
                                  label: "Caregiver",
                                  roleCode: "CAREGIVER",
                                  isSelected: _role == "CAREGIVER",
                                  icon: Icons.medical_services_outlined,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _role = "CAREGIVER");
                                  },
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 28),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.colorPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? "Sign In" : "Create Account",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.colorPrimary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isSelected ? AppTheme.colorPrimary : AppTheme.colorTextMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final String roleCode;
  final bool isSelected;
  final IconData icon;
  final ValueChanged<bool> onSelected;

  const _RoleChip({
    required this.label,
    required this.roleCode,
    required this.isSelected,
    required this.icon,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = roleCode == "PATIENT" ? AppTheme.colorPrimary : AppTheme.colorSuccess;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : AppTheme.colorTextMuted,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: activeColor,
      backgroundColor: AppTheme.colorBg,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.colorTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? activeColor : AppTheme.colorBorder,
        ),
      ),
    );
  }
}
