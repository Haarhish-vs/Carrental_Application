/// Compact fleet statistics for the Owner Profile screen. Computed
/// directly from the real `getMyListings()` response — no mock data
/// involved.
class OwnerFleetStats {
  const OwnerFleetStats({
    required this.totalCars,
    required this.availableCars,
    required this.rentedCars,
  });

  final int totalCars;
  final int availableCars;
  final int rentedCars;

  static const empty = OwnerFleetStats(totalCars: 0, availableCars: 0, rentedCars: 0);

  factory OwnerFleetStats.fromListings(List<Map<String, dynamic>> listings) {
    var available = 0;
    var rented = 0;

    for (final v in listings) {
      final isAvailable = v['is_available'] == true || v['isAvailable'] == true;
      final status = v['status']?.toString().toLowerCase() ?? '';
      if (isAvailable && status != 'rented') {
        available++;
      } else {
        rented++;
      }
    }

    return OwnerFleetStats(
      totalCars: listings.length,
      availableCars: available,
      rentedCars: rented,
    );
  }
}

/// A single vehicle's document/verification status, read from the
/// vehicle's real `documents` array when the backend provides one
/// (see `CarApiService.uploadVehicleDocument`). Falls back to
/// `pending` when a vehicle has no documents on record yet.
enum DocumentStatus { verified, pending, expired, rejected }

class VehicleDocumentInfo {
  const VehicleDocumentInfo({
    required this.vehicleName,
    required this.status,
  });

  final String vehicleName;
  final DocumentStatus status;

  static DocumentStatus _parseStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'verified':
      case 'approved':
        return DocumentStatus.verified;
      case 'expired':
        return DocumentStatus.expired;
      case 'rejected':
        return DocumentStatus.rejected;
      default:
        return DocumentStatus.pending;
    }
  }

  static List<VehicleDocumentInfo> fromListings(List<Map<String, dynamic>> listings) {
    return listings.map((v) {
      final brand = v['brand']?.toString() ?? '';
      final model = v['model']?.toString() ?? '';
      final name = [brand, model].where((p) => p.isNotEmpty).join(' ').trim();

      final documents = v['documents'];
      String? rawStatus;
      if (documents is List && documents.isNotEmpty) {
        final first = documents.first;
        if (first is Map) rawStatus = first['status']?.toString();
      } else if (documents is Map) {
        rawStatus = documents['status']?.toString();
      }

      return VehicleDocumentInfo(
        vehicleName: name.isEmpty ? 'Vehicle' : name,
        status: _parseStatus(rawStatus),
      );
    }).toList();
  }
}
