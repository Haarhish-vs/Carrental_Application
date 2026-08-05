import '../../presentation/screens/rent_car/rent_car_shared.dart';

class VehicleModel {
  static Map<String, dynamic> fromDraft(RentCarDraft draft) {
    // Determine the city name. Use the last segment of the pickup location if available.
    String city = 'Default City';
    if (draft.pickupLocation.isNotEmpty) {
      final segments = draft.pickupLocation.split(',');
      if (segments.isNotEmpty) {
        city = segments.last.trim();
      }
    }

    return {
      'brand': draft.brand,
      'model': draft.model,
      'variant': draft.variant,
      'manufacturingYear': int.tryParse(draft.manufacturingYear) ?? DateTime.now().year,
      'registrationNumber': draft.registrationNumber,
      'rc_number': draft.registrationNumber,
      'fuelType': draft.fuelType,
      'transmission': draft.transmission,
      'mileage': double.tryParse(draft.mileage) ?? 0.0,
      'seatingCapacity': int.tryParse(draft.seatingCapacity) ?? 5,
      'color': draft.color,
      'engineCapacity': draft.engineCapacity,
      'odometerReading': double.tryParse(draft.odometerReading) ?? 0.0,
      'vehicleDescription': draft.vehicleDescription,
      'dailyPrice': double.tryParse(draft.dailyPrice) ?? 0.0,
      'securityDeposit': double.tryParse(draft.securityDeposit) ?? 0.0,
      'minimumRentalDays': int.tryParse(draft.minimumRentalDays) ?? 1,
      'pickupLocation': draft.pickupLocation,
      'availabilityFrom': draft.availabilityFrom,
      'availabilityTo': draft.availabilityTo,
      'deliveryFee': double.tryParse(draft.deliveryFee) ?? 0.0,
      'selectedPhotos': draft.selectedPhotos,
      'city': city.isNotEmpty ? city : 'Default City',
    };
  }
}
