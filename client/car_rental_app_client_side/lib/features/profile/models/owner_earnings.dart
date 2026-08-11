/// Owner earnings summary.
///
/// NOTE — MOCK DATA: there is no earnings/payouts endpoint anywhere in
/// `CarApiService` yet (only vehicle listings and bookings). Per the
/// "backend-ready, frontend-only" requirement, [OwnerEarnings.demo] is
/// a placeholder so the UI can be reviewed today. Swap in a real API
/// call as soon as a `/api/owner/earnings`-style endpoint exists —
/// the widget only depends on this model shape.
class OwnerEarnings {
  const OwnerEarnings({
    required this.total,
    required this.thisMonth,
    required this.today,
  });

  final double total;
  final double thisMonth;
  final double today;

  static const zero = OwnerEarnings(total: 0, thisMonth: 0, today: 0);

  /// MOCK — demo values only, see class doc comment above.
  factory OwnerEarnings.demo() => const OwnerEarnings(
        total: 245680,
        thisMonth: 48750,
        today: 3250,
      );
}

/// Renter relationship stats for the Owner Profile's "Renters" section.
///
/// NOTE — MOCK DATA: there is no endpoint returning bookings made
/// against an owner's fleet (only the owner's own bookings-as-renter
/// via `getMyBookings`, and their own listings via `getMyListings`).
/// [OwnerRenterStats.demo] is a placeholder — see [OwnerEarnings] doc
/// comment for the replacement plan.
class OwnerRenterStats {
  const OwnerRenterStats({required this.repeatRenters, required this.totalRenters});

  final int repeatRenters;
  final int totalRenters;

  static const zero = OwnerRenterStats(repeatRenters: 0, totalRenters: 0);

  /// MOCK — demo values only, see class doc comment above.
  factory OwnerRenterStats.demo() => const OwnerRenterStats(repeatRenters: 14, totalRenters: 37);
}
