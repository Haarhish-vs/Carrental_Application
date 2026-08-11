import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SortOption {
  final String key;
  final String label;

  const SortOption({required this.key, required this.label});
}

class SortBottomSheet extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onSelectSort;

  const SortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSelectSort,
  });

  static const List<SortOption> options = [
    SortOption(key: 'recommended', label: 'Recommended'),
    SortOption(key: 'price_low_to_high', label: 'Price: Low to High'),
    SortOption(key: 'price_high_to_low', label: 'Price: High to Low'),
    SortOption(key: 'distance_near_to_far', label: 'Distance: Near to Far'),
    SortOption(key: 'distance_far_to_near', label: 'Distance: Far to Near'),
    SortOption(key: 'newest', label: 'Newest First'),
  ];

  static Future<void> show(
    BuildContext context, {
    required String currentSort,
    required ValueChanged<String> onSelectSort,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SortBottomSheet(
        currentSort: currentSort,
        onSelectSort: (selected) {
          Navigator.pop(ctx);
          onSelectSort(selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((option) {
              final isSelected = currentSort == option.key;
              return InkWell(
                onTap: () => onSelectSort(option.key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : Colors.grey.shade400,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
