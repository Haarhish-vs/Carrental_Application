import 'package:car_rental_app_client_side/features/owner/data/services/car_api_service.dart';
import 'package:car_rental_app_client_side/features/owner/presentation/screens/rent_car/rent_car_shared.dart';

void main() async {
  print('--- Starting API Integration Client Test ---');
  final service = CarApiService();
  
  // Verify baseUrl resolves
  print('API Base URL: ${service.baseUrl}');

  final draft = RentCarDraft(
    brand: 'Toyota',
    model: 'Corolla',
    variant: 'Altis 1.8G',
    manufacturingYear: '2024',
    registrationNumber: 'KA-01-ME-TEST-${DateTime.now().millisecondsSinceEpoch}',
    fuelType: 'Petrol',
    transmission: 'Automatic',
    mileage: '15.5',
    engineCapacity: '1800',
    vehicleDescription: 'A smooth and reliable ride.',
    dailyPrice: '95.00',
    securityDeposit: '250.00',
    minimumRentalDays: '2',
    pickupLocation: '123 Indiranagar, Bengaluru, Karnataka, 560038',
    availabilityFrom: '2026-08-10',
    availabilityTo: '2026-08-20',
    selectedPhotos: ['front.jpg', 'back.jpg'],
    selectedDocuments: [],
  );

  try {
    print('1. Creating car draft...');
    final carId = await service.createCarDraft(draft);
    print('   Created Car ID: $carId');

    print('2. Saving location details...');
    await service.saveLocation(carId, draft);
    print('   Location saved successfully.');

    print('3. Saving pricing details...');
    await service.savePricing(carId, draft);
    print('   Pricing saved successfully.');

    print('4. Saving availability details...');
    await service.saveAvailability(carId, draft);
    print('   Availability saved successfully.');

    print('5. Uploading images (using dummy fallback file streams)...');
    await service.uploadImages(carId, draft);
    print('   Images uploaded successfully.');

    print('6. Uploading documents (using dummy fallback file streams)...');
    await service.uploadDocuments(
      carId: carId,
      rcNumber: 'RC-998877',
      insuranceNumber: 'INS-112233',
      ownerIdRef: 'OWN-5544',
      permitRef: 'PER-8877',
    );
    print('   Documents uploaded successfully.');

    print('7. Submitting car draft for verification...');
    await service.submitCar(carId);
    print('   Car registration successfully finalized!');
    
    print('\n--- ALL API INTEGRATION CHECKS PASSED SUCCESSFULLY! ---');
  } catch (e) {
    print('\n❌ API Test Failed: $e');
  }
}
