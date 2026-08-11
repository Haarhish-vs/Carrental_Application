import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/services/auth_service.dart';

/// Minimal, role-aware Edit Profile screen reached via the small edit
/// icon in [ProfileHeader]. Shared by both roles — Owner additionally
/// gets a "Business Name" field.
///
/// NOTE: only `AuthService.completeProfile(fullName)` is a real,
/// existing backend endpoint. Phone/email/location/business-name have
/// no update endpoint in this project yet, so saving those shows a
/// clear "will sync once backend support is added" message rather
/// than silently pretending to persist them.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.isOwner});

  final bool isOwner;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _businessController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    _nameController = TextEditingController(
      text: user?['full_name']?.toString() ?? user?['fullName']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: user?['phone_number']?.toString() ?? user?['phoneNumber']?.toString() ?? '',
    );
    _emailController = TextEditingController(text: user?['email']?.toString() ?? '');
    _businessController = TextEditingController(text: user?['business_name']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final newName = _nameController.text.trim();
      if (newName.isNotEmpty) {
        await AuthService().completeProfile(newName);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name updated. Other fields will sync once backend support is added.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Field(label: 'Full Name', controller: _nameController, icon: Icons.person_outline),
              const SizedBox(height: 14),
              _Field(label: 'Phone', controller: _phoneController, icon: Icons.phone_outlined, enabled: false),
              const SizedBox(height: 14),
              _Field(label: 'Email', controller: _emailController, icon: Icons.mail_outline_rounded),
              if (widget.isOwner) ...[
                const SizedBox(height: 14),
                _Field(label: 'Business Name', controller: _businessController, icon: Icons.storefront_outlined),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller, required this.icon, this.enabled = true});

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}
