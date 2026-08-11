/// Rating data returned by the protected profile API.
class RatingSummary {
  const RatingSummary({
    required this.average,
    required this.totalRatings,
    required this.distribution,
  });

  final double average;
  final int totalRatings;
  final Map<int, double> distribution;

  static const zero = RatingSummary(
    average: 0,
    totalRatings: 0,
    distribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
  );

  factory RatingSummary.fromApi(Map<String, dynamic>? data) {
    final rawDistribution = data?['distribution'] as Map? ?? const {};
    final total = (data?['total'] as num?)?.toInt() ?? 0;
    return RatingSummary(
      average: (data?['average'] as num?)?.toDouble() ?? 0,
      totalRatings: total,
      distribution: {
        for (var star = 1; star <= 5; star++)
          star: total == 0
              ? 0
              : ((rawDistribution[star] ?? rawDistribution['$star'] ?? 0) as num)
                      .toDouble() /
                  total,
      },
    );
  }
}
