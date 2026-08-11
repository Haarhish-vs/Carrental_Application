import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/rating_summary.dart';
import 'section_card.dart';

/// Compact rating visualization: average + stars + count, with an
/// optional distribution breakdown (5★ down to 1★). Used identically
/// by both Owner and Customer profiles — reviews/comments are
/// deliberately never shown here, only the rating itself.
class RatingCard extends StatelessWidget {
  const RatingCard({super.key, required this.summary, this.showDistribution = true});

  final RatingSummary summary;
  final bool showDistribution;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Ratings',
      icon: Icons.star_rounded,
      child: summary.totalRatings == 0
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No ratings yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.average.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          final filled = i < summary.average.round();
                          return Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: filled ? AppColors.rating : AppColors.divider,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary.totalRatings} ratings',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (showDistribution)
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        for (final star in [5, 4, 3, 2, 1])
                          _DistributionBar(star: star, fraction: summary.distribution[star] ?? 0),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.star, required this.fraction});

  final int star;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 20, child: Text('$star★', style: const TextStyle(fontSize: 11))),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.rating),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
