import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../presentation/screens/rent_car/rent_car_shared.dart';

class CarApiService {
  // Base URL resolution supporting Android emulator, Web, iOS, etc.
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api/v1';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:5000/api/v1';
  }

  // A tiny 1x1 transparent PNG file to use as a fallback placeholder
  static const List<int> _dummyPngBytes = [
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 
    0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 
    0, 0, 0, 11, 73, 68, 65, 84, 120, 156, 99, 96, 0, 0, 0, 
    2, 0, 1, 73, 175, 168, 5, 0, 0, 0, 0, 73, 69, 78, 68, 
    174, 66, 96, 130
  ];

  // Headers config
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-owner-id': '11111111-1111-1111-1111-111111111111',
      };

  /// Step 1: Create car draft in the backend
  Future<String> createCarDraft(RentCarDraft draft) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cars'),
      headers: _headers,
      body: jsonEncode({
        'brand': draft.brand,
        'model': draft.model,
        'variant': draft.variant.isEmpty ? 'Standard' : draft.variant,
        'year': int.tryParse(draft.manufacturingYear) ?? DateTime.now().year,
        'fuelType': draft.fuelType.isEmpty ? 'Petrol' : draft.fuelType,
        'transmission': draft.transmission.isEmpty ? 'Automatic' : draft.transmission,
        'mileage': double.tryParse(draft.mileage) ?? 15.0,
        'engineCapacity': int.tryParse(draft.engineCapacity) ?? 1500,
        'registrationNumber': draft.registrationNumber,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 201 && responseData['success'] == true) {
      return responseData['data']['id'].toString();
    } else {
      final msg = responseData['message'] ?? 'Failed to create car draft';
      throw Exception(msg);
    }
  }

  /// Step 2: Save pickup location details
  Future<void> saveLocation(String carId, RentCarDraft draft) async {
    // Map single location string to address, city, state, pincode
    final locStr = draft.pickupLocation;
    final parts = locStr.split(',');
    final address = parts.isNotEmpty ? parts[0].trim() : locStr;
    final city = parts.length > 1 ? parts[1].trim() : 'Bengaluru';
    final state = parts.length > 2 ? parts[2].trim() : 'Karnataka';
    final pincode = parts.length > 3 ? parts[3].trim() : '560038';

    final response = await http.post(
      Uri.parse('$baseUrl/cars/$carId/location'),
      headers: _headers,
      body: jsonEncode({
        'pickupAddress': address.isEmpty ? 'Main pickup hub' : address,
        'city': city.isEmpty ? 'Bengaluru' : city,
        'state': state.isEmpty ? 'Karnataka' : state,
        'pincode': pincode.isEmpty ? '560038' : pincode,
        'latitude': 12.9716, // Default coordinates if not set
        'longitude': 77.5946,
      }),
    );

    if (response.statusCode != 200) {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to save location');
    }
  }

  /// Step 3: Save pricing details
  Future<void> savePricing(String carId, RentCarDraft draft) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cars/$carId/pricing'),
      headers: _headers,
      body: jsonEncode({
        'pricePerDay': double.tryParse(draft.dailyPrice) ?? 50.0,
        'securityDeposit': double.tryParse(draft.securityDeposit) ?? 200.0,
        'minimumRentalDuration': int.tryParse(draft.minimumRentalDays) ?? 1,
        'instantBooking': true,
      }),
    );

    if (response.statusCode != 200) {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to save pricing');
    }
  }

  /// Step 4: Save availability details
  Future<void> saveAvailability(String carId, RentCarDraft draft) async {
    final availableDates = <String>[];
    if (draft.availabilityFrom.isNotEmpty) availableDates.add(draft.availabilityFrom);
    if (draft.availabilityTo.isNotEmpty) availableDates.add(draft.availabilityTo);

    final response = await http.post(
      Uri.parse('$baseUrl/cars/$carId/availability'),
      headers: _headers,
      body: jsonEncode({
        'availableDates': availableDates,
        'blockedDates': [],
      }),
    );

    if (response.statusCode != 200) {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to save availability');
    }
  }

  /// Step 5: Upload car images
  Future<void> uploadImages(String carId, RentCarDraft draft) async {
    final uri = Uri.parse('$baseUrl/cars/$carId/images');
    final request = http.MultipartRequest('POST', uri);
    
    // Set headers
    request.headers['x-owner-id'] = '11111111-1111-1111-1111-111111111111';

    // Map photo fields. The backend accepts multiple file fields dynamically (any).
    // Let's use front, back, interior, dashboard keys.
    final photoKeys = ['front', 'back', 'interior', 'dashboard'];
    for (int i = 0; i < photoKeys.length; i++) {
      final key = photoKeys[i];
      final path = draft.selectedPhotos.length > i ? draft.selectedPhotos[i] : '';
      
      if (path.isNotEmpty && await File(path).exists()) {
        request.files.add(await http.MultipartFile.fromPath(key, path));
      } else {
        // Fallback: Send valid transparent PNG bytes
        request.files.add(http.MultipartFile.fromBytes(
          key,
          _dummyPngBytes,
          filename: '${key}_placeholder.png',
        ));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to upload images');
    }
  }

  /// Step 6: Upload registration and insurance documents
  Future<void> uploadDocuments({
    required String carId,
    required String rcNumber,
    required String insuranceNumber,
    required String ownerIdRef,
    required String permitRef,
  }) async {
    final uri = Uri.parse('$baseUrl/cars/$carId/documents');
    final request = http.MultipartRequest('POST', uri);
    
    request.headers['x-owner-id'] = '11111111-1111-1111-1111-111111111111';

    // Helper to upload document files. Fallback to valid PNG placeholder
    final docFields = {
      'rc': rcNumber,
      'insurance': insuranceNumber,
      'fitness': permitRef,
      'puc': ownerIdRef,
    };

    for (final entry in docFields.entries) {
      final key = entry.key;
      final val = entry.value;
      
      if (val.isNotEmpty && await File(val).exists()) {
        request.files.add(await http.MultipartFile.fromPath(key, val));
      } else {
        request.files.add(http.MultipartFile.fromBytes(
          key,
          _dummyPngBytes,
          filename: '${key}_placeholder.png',
        ));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to upload documents');
    }
  }

  /// Step 7: Finalize submission for verification
  Future<void> submitCar(String carId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cars/$carId/submit'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to submit car for verification');
    }
  }
}
