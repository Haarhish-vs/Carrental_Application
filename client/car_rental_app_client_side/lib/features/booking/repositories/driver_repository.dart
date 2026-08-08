import 'dart:math';
import '../models/driver_model.dart';
import '../models/location_model.dart';

abstract class DriverRepository {
  Future<List<Driver>> getAvailableDrivers({
    required LocationModel pickupLocation,
    required DateTime pickupDateTime,
    DateTime? returnDateTime,
  });
}

class MockDriverRepository implements DriverRepository {
  // Hardcoded mock drivers with coordinates near Coimbatore Hubs
  // Gandhipuram Hub: 11.0168, 76.9558
  // RS Puram Hub: 11.0115, 76.9443
  // Airport Hub: 11.0298, 77.0434
  final List<Driver> _mockDrivers = const [
    Driver(
      id: "drv_david_kumar",
      name: "David Kumar",
      rating: 4.9,
      experienceYears: 8,
      languages: ["Tamil", "English", "Hindi"],
      isVerified: true,
      pricePerDay: 600.0,
      imageUrl:
          "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=200",
      serviceLocations: ["coimbatore_gandhipuram", "coimbatore_airport"],
      latitude: 11.0250, // ~1.8km from Gandhipuram, ~2.9km from Airport
      longitude: 76.9700,
      isAvailable: true,
      tripsCompleted: 1240,
    ),
    Driver(
      id: "drv_marcus_vance",
      name: "Marcus Vance",
      rating: 4.85,
      experienceYears: 10,
      languages: ["English", "Tamil"],
      isVerified: true,
      pricePerDay: 650.0,
      imageUrl:
          "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200",
      serviceLocations: ["coimbatore_gandhipuram", "coimbatore_rspuram"],
      latitude: 11.0180, // Close to Gandhipuram
      longitude: 76.9580,
      isAvailable: true,
      tripsCompleted: 1500,
    ),
    Driver(
      id: "drv_sarah_jenkins",
      name: "Sarah Jenkins",
      rating: 4.8,
      experienceYears: 5,
      languages: ["English", "French"],
      isVerified: true,
      pricePerDay: 500.0,
      imageUrl:
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200",
      serviceLocations: ["coimbatore_rspuram"],
      latitude: 11.0120, // Very close to RS Puram
      longitude: 76.9460,
      isAvailable: true,
      tripsCompleted: 800,
    ),
    Driver(
      id: "drv_rajesh_khanna",
      name: "Rajesh Khanna",
      rating: 4.7,
      experienceYears: 12,
      languages: ["Tamil", "Hindi", "English"],
      isVerified: true,
      pricePerDay: 580.0,
      imageUrl:
          "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200",
      serviceLocations: ["coimbatore_airport"],
      latitude: 11.0298, // Exactly at Airport Hub (0.0 km)
      longitude: 77.0434,
      isAvailable: true,
      tripsCompleted: 2100,
    ),
    Driver(
      id: "drv_busy_driver",
      name: "Busy Driver",
      rating: 4.95,
      experienceYears: 15,
      languages: ["English"],
      isVerified: true,
      pricePerDay: 800.0,
      imageUrl:
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200",
      serviceLocations: ["coimbatore_gandhipuram"],
      latitude: 11.0168,
      longitude: 76.9558,
      isAvailable: false,
      tripsCompleted: 3000,
    ),
  ];

  @override
  Future<List<Driver>> getAvailableDrivers({
    required LocationModel pickupLocation,
    required DateTime pickupDateTime,
    DateTime? returnDateTime,
  }) async {
    // Simulate standard network latency
    await Future.delayed(const Duration(milliseconds: 600));

    // Filter based on location, availability status, and timestamps
    final filtered = _mockDrivers.where((driver) {
      if (!driver.serviceLocations.contains(pickupLocation.id)) {
        return false;
      }
      if (!driver.isAvailable) {
        return false;
      }
      if (driver.availableFrom != null &&
          pickupDateTime.isBefore(driver.availableFrom!)) {
        return false;
      }
      if (driver.availableUntil != null &&
          pickupDateTime.isAfter(driver.availableUntil!)) {
        return false;
      }
      if (returnDateTime != null &&
          driver.availableUntil != null &&
          returnDateTime.isAfter(driver.availableUntil!)) {
        return false;
      }
      return true;
    }).toList();

    return filtered;
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
