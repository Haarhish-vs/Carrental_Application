import 'package:flutter/material.dart';

import 'common/owner_colors.dart';
import 'common/owner_date_format.dart';
import 'common/owner_layout.dart';
import 'common/owner_section_header.dart';
import 'common/owner_spacing.dart';
import '../../models/owner_dummy_data.dart';
import '../../models/review_model.dart';

/// SECTION 8 — Ratings & Reviews.
class RatingsReviewsSection extends StatelessWidget {
  const RatingsReviewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerSectionHeader(
          title: 'Ratings & Reviews',
          subtitle: 'What customers are saying about your fleet',
          icon: Icons.star_rounded,
          actionLabel: 'View all reviews',
        ),
        OwnerSurfaceCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 520;

              final scoreBox = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    OwnerDummyData.overallRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: OwnerColors.ink),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => const Icon(Icons.star_rounded, size: 18, color: OwnerColors.star),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${OwnerDummyData.totalReviewCount} reviews',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              );

              final ratingBars = Column(
                children: [
                  for (final entry in OwnerDummyData.ratingBreakdown.entries)
                    _RatingBar(stars: entry.key, fraction: entry.value),
                ],
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    scoreBox,
                    const Divider(height: OwnerSpacing.lg),
                    ratingBars,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: scoreBox),
                  const SizedBox(width: OwnerSpacing.lg),
                  Expanded(flex: 3, child: ratingBars),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: OwnerSpacing.lg),
        OwnerSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recent Reviews', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Divider(height: OwnerSpacing.lg),
              for (final r in OwnerDummyData.recentReviews) _ReviewCard(review: r),
            ],
          ),
        ),
      ],
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.stars, required this.fraction});

  final int stars;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$stars★', style: const TextStyle(fontSize: 13))),
          const SizedBox(width: OwnerSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: OwnerColors.surfaceMuted,
                valueColor: const AlwaysStoppedAnimation(OwnerColors.star),
              ),
            ),
          ),
          const SizedBox(width: OwnerSpacing.sm),
          SizedBox(
            width: 36,
            child: Text(
              '${(fraction * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11.5, color: Colors.black54),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OwnerSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: OwnerColors.primaryLight,
            child: Icon(Icons.person_rounded, color: OwnerColors.primary),
          ),
          const SizedBox(width: OwnerSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      OwnerDateFormat.dayMonth(review.date),
                      style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                    ),
                  ],
                ),
                Text(review.carName, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (i) {
                    final filled = i < review.rating.floor();
                    final half = !filled && i < review.rating;
                    return Icon(
                      half ? Icons.star_half_rounded : Icons.star_rounded,
                      size: 16,
                      color: (filled || half) ? OwnerColors.star : OwnerColors.surfaceMuted,
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(review.comment, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
