import 'package:car_rental_app_client_side/features/owner/data/models/vehicle_model.dart';
import 'package:car_rental_app_client_side/features/owner/data/services/car_api_service.dart';
import 'package:car_rental_app_client_side/features/owner/presentation/screens/rent_car/rent_car_shared.dart';

void main() {
  final service = CarApiService();
  assert(service.toString().isNotEmpty);
  
  final draft = RentCarDraft(
    brand: 'Toyota',
    model: 'Corolla',
    variant: 'Altis 1.8G',
    manufacturingYear: '2024',
    registrationNumber: 'KA-01-ME-TEST',
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
    selectedPhotos: ['https://carrental-application-z49a.onrender.com/uploads/sample.jpg'],
    selectedDocuments: [],
  );

  final payload = VehicleModel.fromDraft(draft);
  payload['rc_number'] = draft.registrationNumber;

  assert(payload['brand'] == 'Toyota');
  assert(payload['model'] == 'Corolla');
}
