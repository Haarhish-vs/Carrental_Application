import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        icon: Icons.search_rounded,
        title: 'Search Car',
        subtitle: 'Browse available cars near you',
      ),
      (
        icon: Icons.calendar_month_rounded,
        title: 'Choose Date',
        subtitle: 'Select pickup & return schedule',
      ),
      (
        icon: Icons.verified_rounded,
        title: 'Book Instantly',
        subtitle: 'Confirm your booking securely',
      ),
      (
        icon: Icons.directions_car_filled_rounded,
        title: 'Enjoy Ride',
        subtitle: 'Pick up your car and drive',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'How It Works',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  children: List.generate(
                    steps.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _StepCard(
                        number: index + 1,
                        icon: steps[index].icon,
                        title: steps[index].title,
                        subtitle: steps[index].subtitle,
                      ),
                    ),
                  ),
                );
              }

              return Row(
                children: List.generate(
                  steps.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _StepCard(
                        number: index + 1,
                        icon: steps[index].icon,
                        title: steps[index].title,
                        subtitle: steps[index].subtitle,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String subtitle;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}