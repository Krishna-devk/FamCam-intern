import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/session_provider.dart';
import '../../providers/slots_provider.dart' show apiClientProvider;

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize fields with current session data
    final session = ref.read(sessionProvider).value;
    if (session != null) {
      _nameController.text = session.name;
      _emailController.text = session.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final session = ref.read(sessionProvider).value;
    if (session == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final client = ref.read(apiClientProvider);
      final updatedUser = await client.updateUser(
        session.id, 
        _nameController.text.trim(), 
        _emailController.text.trim(),
      );
      
      await ref.read(sessionProvider.notifier).updateSession(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.colorError),
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
    final session = ref.watch(sessionProvider).value;
    final userRole = session?.role ?? "User";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Information"),
        backgroundColor: AppTheme.colorSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text("Your Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              const Text("Full Name", style: TextStyle(fontSize: 14, color: AppTheme.colorTextMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.colorBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.colorBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.colorBorder),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty ? "Please enter a name" : null,
              ),
              const SizedBox(height: 16),
              
              const Text("Email Address", style: TextStyle(fontSize: 14, color: AppTheme.colorTextMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.colorBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.colorBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.colorBorder),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Please enter an email";
                  if (!val.contains('@')) return "Please enter a valid email";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildStaticField("Role", userRole),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Save Changes"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.colorTextMuted)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.colorBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.colorBorder),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16, color: AppTheme.colorTextMuted)),
        ),
      ],
    );
  }
}
