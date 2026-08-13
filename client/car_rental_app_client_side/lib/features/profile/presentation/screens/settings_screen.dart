import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/services/auth_service.dart';
import '../../data/services/profile_api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileApiService _profileApiService = ProfileApiService();
  bool _isDeleting = false;

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF103B66))),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account?\n\nThis action CANNOT be undone and will permanently remove your user profile, listings, and database records.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await _profileApiService.deleteAccount();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been permanently deleted.'),
          backgroundColor: Colors.redAccent,
        ),
      );

      // Pop all routes and return to root screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAuthenticated = AuthService.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Color(0xFF103B66), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF103B66)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Information',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: AppColors.primary),
                    title: Text('App Version'),
                    trailing: Text('1.0.0', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.security, color: AppColors.primary),
                    title: Text('Data Privacy & Security'),
                    subtitle: Text('Encrypted database connection'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            if (isAuthenticated) ...[
              const Text(
                'Account Management',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  ),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  subtitle: const Text(
                    'Permanently delete your profile and all data from database',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                        )
                      : const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: _isDeleting ? null : _handleDeleteAccount,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_rounded, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You are currently using the app in Guest Mode. Log in to manage account settings.',
                        style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
