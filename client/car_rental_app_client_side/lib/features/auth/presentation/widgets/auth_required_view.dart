import 'package:flutter/material.dart';
import 'package:car_rental_app_client_side/core/theme/app_colors.dart';
import 'package:car_rental_app_client_side/features/auth/presentation/screens/auth_screen.dart';

class AuthRequiredView extends StatelessWidget {
  const AuthRequiredView({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Log In / Register',
    this.onAuthenticated,
  });

  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onAuthenticated;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            elevation: 0,
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Lock Badge Icon (Matching Profile & Home style)
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 34,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle / Description
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Login / Register CTA
                  FilledButton(
                    onPressed: () async {
                      final authSuccess = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const AuthScreen(),
                        ),
                      );

                      if (authSuccess == true && onAuthenticated != null) {
                        onAuthenticated!();
                      }
                    },
                    style: AppColors.primaryButtonStyle(),
                    child: Text(buttonText),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
