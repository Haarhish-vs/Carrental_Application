// vehicle.service.js
const { supabase } = require('../../config/supabase');
const bookingService = require('../bookings/booking.service');

class VehicleService {
  /**
   * Helper to map client payload (which can be camelCase from Flutter/React Native UI) to database columns.
   */
  _mapPayload(input) {
    const mapped = {};
    const fields = {
      brand: 'brand',
      model: 'model',
      variant: 'variant',
      manufacturingYear: 'manufacturing_year',
      manufacturing_year: 'manufacturing_year',
      registrationNumber: 'registration_number',
      registration_number: 'registration_number',
      fuelType: 'fuel_type',
      fuel_type: 'fuel_type',
      transmission: 'transmission',
      mileage: 'mileage',
      seatingCapacity: 'seats',
      seats: 'seats',
      color: 'color',
      engineCapacity: 'engine_capacity',
      engine_capacity: 'engine_capacity',
      odometerReading: 'odometer_reading',
      odometer_reading: 'odometer_reading',
      vehicleDescription: 'vehicle_description',
      vehicle_description: 'vehicle_description',
      dailyPrice: 'price_per_day',
      price_per_day: 'price_per_day',
      securityDeposit: 'deposit_amount',
      deposit_amount: 'deposit_amount',
      minimumRentalDays: 'minimum_rental_days',
      minimum_rental_days: 'minimum_rental_days',
      pickupLocation: 'pickup_location',
      pickup_location: 'pickup_location',
      availabilityFrom: 'availability_from',
      availability_from: 'availability_from',
      availabilityTo: 'availability_to',
      availability_to: 'availability_to',
      deliveryFee: 'delivery_fee',
      delivery_fee: 'delivery_fee',
      selectedPhotos: 'images',
      images: 'images',
      rc_number: 'rc_number',
      location_lat: 'location_lat',
      location_lng: 'location_lng',
      city: 'city',
      status: 'status',
      is_available: 'is_available',
      isAvailable: 'is_available',
      fc_expiry: 'fc_expiry',
      insurance_expiry: 'insurance_expiry'
    };

    for (const [key, value] of Object.entries(input)) {
      if (fields[key] !== undefined && value !== undefined) {
        mapped[fields[key]] = value;
      }
    }

    // Apply defaults and parsing if necessary
    if (mapped.seats !== undefined) mapped.seats = parseInt(mapped.seats);
    if (mapped.price_per_day !== undefined) mapped.price_per_day = parseFloat(mapped.price_per_day);
    if (mapped.deposit_amount !== undefined) mapped.deposit_amount = parseFloat(mapped.deposit_amount);
    if (mapped.minimum_rental_days !== undefined) mapped.minimum_rental_days = parseInt(mapped.minimum_rental_days);
    if (mapped.delivery_fee !== undefined) mapped.delivery_fee = parseFloat(mapped.delivery_fee);
    if (mapped.location_lat !== undefined) mapped.location_lat = parseFloat(mapped.location_lat);
    if (mapped.location_lng !== undefined) mapped.location_lng = parseFloat(mapped.location_lng);
    if (mapped.manufacturing_year !== undefined) mapped.manufacturing_year = parseInt(mapped.manufacturing_year);
    if (mapped.odometer_reading !== undefined) mapped.odometer_reading = parseFloat(mapped.odometer_reading);

    // Clean empty string timestamps & arrays
    if (mapped.availability_from === '' || mapped.availability_from === null) mapped.availability_from = null;
    if (mapped.availability_to === '' || mapped.availability_to === null) mapped.availability_to = null;
    if (mapped.images && !Array.isArray(mapped.images)) mapped.images = [mapped.images];
    if (!mapped.images) mapped.images = [];

    // Fallbacks
    if (!mapped.rc_number && mapped.registration_number) {
      mapped.rc_number = mapped.registration_number;
    }

    return mapped;
  }

  /**
   * Create a new vehicle listing in 'under_review' status.
   */
  async createVehicle(userId, vehicleData) {
    const mapped = this._mapPayload(vehicleData);
    
    // Validate required fields
    const required = ['brand', 'model', 'fuel_type', 'transmission', 'price_per_day', 'seats', 'rc_number', 'city'];
    for (const field of required) {
      if (mapped[field] === undefined || mapped[field] === null || mapped[field] === '') {
        const error = new Error(`Required vehicle field is missing: ${field}`);
        error.statusCode = 400;
        throw error;
      }
    }

    mapped.owner_id = userId;
    mapped.status = 'active'; // Directly set to active status on creation
    if (mapped.is_available === undefined) mapped.is_available = true;

    const { data, error } = await supabase
      .from('vehicles')
      .insert(mapped)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to list vehicle: ${error.message}`);
    }

    return data;
  }

  /**
   * Update own vehicle listing.
   */
  async updateVehicle(vehicleId, userId, vehicleData) {
    // 1. Check ownership
    const { data: vehicle, error: fetchError } = await supabase
      .from('vehicles')
      .select('*')
      .eq('id', vehicleId)
      .maybeSingle();

    if (fetchError || !vehicle) {
      const error = new Error('Vehicle not found');
      error.statusCode = 404;
      throw error;
    }

    if (vehicle.owner_id !== userId) {
      const error = new Error('You are not authorized to edit this vehicle listing');
      error.statusCode = 403;
      throw error;
    }

    const mapped = this._mapPayload(vehicleData);

    // 2. Enforce constraint: cannot change status to active unless RC book is verified
    if (mapped.status === 'active') {
      const { data: rcDoc, error: docError } = await supabase
        .from('vehicle_documents')
        .select('verification_status')
        .eq('vehicle_id', vehicleId)
        .eq('document_type', 'rc_book')
        .maybeSingle();

      if (docError || !rcDoc || rcDoc.verification_status !== 'verified') {
        const error = new Error('Vehicle cannot be set to active status until its RC book document is verified by admin.');
        error.statusCode = 400;
        throw error;
      }
    }

    mapped.updated_at = new Date().toISOString();

    const { data: updatedVehicle, error: updateError } = await supabase
      .from('vehicles')
      .update(mapped)
      .eq('id', vehicleId)
      .select()
      .single();

    if (updateError) {
      throw new Error(`Failed to update vehicle: ${updateError.message}`);
    }

    return updatedVehicle;
  }

  /**
   * Owner toggle for availability.
   */
  async toggleAvailability(vehicleId, userId, isAvailable) {
    if (isAvailable === undefined) {
      const error = new Error('isAvailable boolean is required');
      error.statusCode = 400;
      throw error;
    }

    const isAvailableBool = isAvailable === true || isAvailable === 'true';

    const { data: vehicle, error: fetchError } = await supabase
      .from('vehicles')
      .select('owner_id')
      .eq('id', vehicleId)
      .maybeSingle();

    if (fetchError || !vehicle) {
      const error = new Error('Vehicle not found');
      error.statusCode = 404;
      throw error;
    }

    if (vehicle.owner_id !== userId) {
      const error = new Error('You are not authorized to toggle availability for this vehicle');
      error.statusCode = 403;
      throw error;
    }

    if (isAvailableBool) {
      const { data: bookings, error: bookingError } = await supabase
        .from('bookings')
        .select('id')
        .eq('vehicle_id', vehicleId)
        .in('status', ['pending', 'confirmed', 'active']);

      if (bookingError) {
        throw new Error(`Failed to check active bookings: ${bookingError.message}`);
      }

      if (bookings && bookings.length > 0) {
        const error = new Error('Cannot mark vehicle as available while there is a pending, confirmed, or active booking.');
        error.statusCode = 400;
        throw error;
      }
    }

    const { data: updatedVehicle, error: updateError } = await supabase
      .from('vehicles')
      .update({ is_available: isAvailableBool, updated_at: new Date().toISOString() })
      .eq('id', vehicleId)
      .select()
      .single();

    if (updateError) {
      throw new Error(`Failed to update availability: ${updateError.message}`);
    }

    return updatedVehicle;
  }

  /**
   * Retrieve owner's listings.
   */
  async getMyListings(userId) {
    const { data: vehicles, error } = await supabase
      .from('vehicles')
      .select('*')
      .eq('owner_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to retrieve listings: ${error.message}`);
    }

    if (vehicles && vehicles.length > 0) {
      for (const vehicle of vehicles) {
        const { data: bookings, error: bookingError } = await supabase
          .from('bookings')
          .select('*')
          .eq('vehicle_id', vehicle.id)
          .in('status', ['pending', 'confirmed', 'active'])
          .order('end_date', { ascending: false })
          .limit(1);

        if (!bookingError && bookings && bookings.length > 0) {
          vehicle.activeBooking = bookings[0];
        } else {
          vehicle.activeBooking = null;
        }
      }
    }

    return vehicles;
  }

  /**
   * Delete vehicle listing.
   */
  async deleteVehicle(vehicleId, userId) {
    const { data: vehicle, error: fetchError } = await supabase
      .from('vehicles')
      .select('owner_id')
      .eq('id', vehicleId)
      .maybeSingle();

    if (fetchError || !vehicle) {
      const error = new Error('Vehicle not found');
      error.statusCode = 404;
      throw error;
    }

    if (vehicle.owner_id !== userId) {
      const error = new Error('You are not authorized to delete this vehicle listing');
      error.statusCode = 403;
      throw error;
    }

    const { error: deleteError } = await supabase
      .from('vehicles')
      .delete()
      .eq('id', vehicleId);

    if (deleteError) {
      throw new Error(`Failed to delete vehicle: ${deleteError.message}`);
    }

    return true;
  }

  /**
   * Public browsing for active/available vehicles.
   */
  async getVehicles(filters = {}) {
    await bookingService._autoTransitionBookings();
    // 1. Get dates to check for availability exclusion
    const startStr = filters.startDate || filters.start_date;
    const endStr = filters.endDate || filters.end_date;
    
    let targetStart, targetEnd;
    if (startStr && endStr) {
      targetStart = startStr;
      targetEnd = endStr;
    } else {
      // Manually format local today date as YYYY-MM-DD to avoid ICU locale dependencies
      const today = new Date();
      const year = today.getFullYear();
      const month = String(today.getMonth() + 1).padStart(2, '0');
      const day = String(today.getDate()).padStart(2, '0');
      targetStart = `${year}-${month}-${day}`;
      targetEnd = targetStart;
    }

    // 2. Query bookings that overlap with the target range and are active/confirmed/pending
    const { data: overlappingBookings, error: bookingsError } = await supabase
      .from('bookings')
      .select('vehicle_id')
      .in('status', ['pending', 'confirmed', 'active'])
      .lte('start_date', targetEnd)
      .gte('end_date', targetStart);

    let excludedVehicleIds = [];
    if (!bookingsError && overlappingBookings) {
      excludedVehicleIds = [...new Set(overlappingBookings.map(b => b.vehicle_id).filter(id => !!id))];
    }

    let query = supabase
      .from('vehicles')
      .select(`
        *,
        owner:users (
          trust_score
        )
      `)
      .eq('is_available', true)
      .eq('status', 'active'); // Only show active, available cars on home screen

    // Only override status filter if client explicitly passes one
    if (filters.status) {
      query = query.eq('status', filters.status);
    }

    // Apply Filters
    if (filters.city) {
      query = query.ilike('city', filters.city.trim());
    }
    if (filters.minPrice) {
      query = query.gte('price_per_day', parseFloat(filters.minPrice));
    }
    if (filters.maxPrice) {
      query = query.lte('price_per_day', parseFloat(filters.maxPrice));
    }
    if (filters.fuelType || filters.fuel_type) {
      query = query.eq('fuel_type', filters.fuelType || filters.fuel_type);
    }
    if (filters.transmission) {
      query = query.eq('transmission', filters.transmission);
    }
    if (filters.seats || filters.seatingCapacity) {
      query = query.eq('seats', parseInt(filters.seats || filters.seatingCapacity));
    }

    // Pagination
    const limit = filters.limit ? parseInt(filters.limit) : 20;
    const offset = filters.offset ? parseInt(filters.offset) : 0;
    query = query.range(offset, offset + limit - 1);

    // Sort by newest
    query = query.order('created_at', { ascending: false });

    const { data, error } = await query;
    if (error) {
      throw new Error(`Failed to retrieve vehicles: ${error.message}`);
    }

    let resultData = data || [];
    if (resultData && excludedVehicleIds.length > 0) {
      resultData = resultData.filter(vehicle => !excludedVehicleIds.includes(vehicle.id));
    }

    if (resultData && resultData.length > 0) {
      await Promise.all(resultData.map(async (vehicle) => {
        const { count } = await supabase
          .from('bookings')
          .select('id', { count: 'exact', head: true })
          .eq('vehicle_id', vehicle.id);
        
        vehicle.reviews_count = count || 0;
        vehicle.rating = vehicle.owner && vehicle.owner.trust_score ? parseFloat((vehicle.owner.trust_score / 20).toFixed(1)) : 4.5;
        
        const desc = (vehicle.vehicle_description || '').toLowerCase();
        vehicle.ac = !desc.includes('no ac') && !desc.includes('no air conditioning');
        vehicle.navigation = !desc.includes('no gps') && !desc.includes('no navigation');
      }));
    }

    return resultData;
  }

  async getFilterOptions() {
    const { data: vehicles, error } = await supabase
      .from('vehicles')
      .select('city, brand, transmission, fuel_type, seats, price_per_day');

    if (error) {
      throw new Error(`Failed to retrieve filter options: ${error.message}`);
    }

    const cities = [...new Set((vehicles || []).map(v => v.city).filter(Boolean))].sort();
    const brands = [...new Set((vehicles || []).map(v => v.brand).filter(Boolean))].sort();
    const transmissions = [...new Set((vehicles || []).map(v => v.transmission).filter(Boolean))].sort();
    const fuelTypes = [...new Set((vehicles || []).map(v => v.fuel_type).filter(Boolean))].sort();
    const seats = [...new Set((vehicles || []).map(v => v.seats).filter(v => v !== null))].sort((a, b) => a - b);
    
    const prices = (vehicles || []).map(v => parseFloat(v.price_per_day)).filter(p => !isNaN(p));
    const minPrice = prices.length ? Math.min(...prices) : 0;
    const maxPrice = prices.length ? Math.max(...prices) : 0;

    return {
      cities,
      brands,
      transmissions,
      fuelTypes,
      seats,
      priceRange: {
        min: minPrice,
        max: maxPrice
      }
    };
  }

  /**
  async getVehicleById(vehicleId, currentUserId = null) {
    const { data: vehicle, error: fetchError } = await supabase
      .from('vehicles')
      .select(`
        *,
        owner:users (
          id,
          full_name,
          phone_number,
          trust_score,
          cancellation_count,
          is_dl_verified,
          created_at
        )
      `)
      .eq('id', vehicleId)
      .maybeSingle();

    if (fetchError || !vehicle) {
      const error = new Error('Vehicle not found');
      error.statusCode = 404;
      throw error;
    }

    // Dynamic fields mapping
    const { count } = await supabase
      .from('bookings')
      .select('id', { count: 'exact', head: true })
      .eq('vehicle_id', vehicleId);
    
    vehicle.reviews_count = count || 0;
    vehicle.rating = vehicle.owner && vehicle.owner.trust_score ? parseFloat((vehicle.owner.trust_score / 20).toFixed(1)) : 4.5;
    
    const desc = (vehicle.vehicle_description || '').toLowerCase();
    vehicle.ac = !desc.includes('no ac') && !desc.includes('no air conditioning');
    vehicle.navigation = !desc.includes('no gps') && !desc.includes('no navigation');

    // Expose owner phone number only if:
    // 1. Current user is the owner themselves
    // 2. Or the current user has a confirmed/active booking for this vehicle
    let canViewPhone = false;

    if (currentUserId) {
      if (vehicle.owner_id === currentUserId) {
        canViewPhone = true;
      } else {
        const { data: booking, error: bookingError } = await supabase
          .from('bookings')
          .select('id')
          .eq('vehicle_id', vehicleId)
          .eq('renter_id', currentUserId)
          .in('status', ['confirmed', 'active'])
          .limit(1);

        if (!bookingError && booking && booking.length > 0) {
          canViewPhone = true;
        }
      }
    }

    // Strip owner phone number if unauthorized
    if (!canViewPhone && vehicle.owner) {
      // Create a shallow copy and delete phone
      vehicle.owner = { ...vehicle.owner };
      delete vehicle.owner.phone_number;
    }

    return vehicle;
  }
  /**
   * Toggle a vehicle's is_available flag (owner only).
   */
  async toggleAvailability(vehicleId, userId, isAvailable) {
    // 1. Verify the vehicle exists and the user owns it
    const { data: vehicle, error: fetchError } = await supabase
      .from('vehicles')
      .select('id, owner_id')
      .eq('id', vehicleId)
      .maybeSingle();

    if (fetchError || !vehicle) {
      const error = new Error('Vehicle not found');
      error.statusCode = 404;
      throw error;
    }

    if (vehicle.owner_id !== userId) {
      const error = new Error('You are not authorized to update this vehicle');
      error.statusCode = 403;
      throw error;
    }

    // 2. Update the flag
    const { data, error: updateError } = await supabase
      .from('vehicles')
      .update({ is_available: isAvailable, updated_at: new Date().toISOString() })
      .eq('id', vehicleId)
      .select()
      .single();

    if (updateError) {
      throw new Error(`Failed to update availability: ${updateError.message}`);
    }

    return data;
  }

  /**
   * Helper Haversine formula to compute great-circle distance between two points in km.
   */
  _calculateHaversineDistanceKm(lat1, lon1, lat2, lon2) {
    if (lat1 === null || lon1 === null || lat2 === null || lon2 === null) return null;
    if (isNaN(lat1) || isNaN(lon1) || isNaN(lat2) || isNaN(lon2)) return null;

    const R = 6371; // Earth's radius in kilometers
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return parseFloat((R * c).toFixed(1));
  }

  /**
   * Dynamically retrieve filter options based on real data stored in the database.
   */
  async getFilterOptions() {
    const { data: vehicles, error } = await supabase
      .from('vehicles')
      .select('*')
      .eq('status', 'active');

    if (error) {
      throw new Error(`Failed to fetch filter options: ${error.message}`);
    }

    const rawVehicles = vehicles || [];

    // 1. Car Types
    const carTypesSet = new Set();
    for (const v of rawVehicles) {
      if (v.car_type && typeof v.car_type === 'string' && v.car_type.trim().length > 0) {
        const val = v.car_type.trim();
        carTypesSet.add(val.charAt(0).toUpperCase() + val.slice(1));
      }
    }

    // 2. Transmissions
    const transmissionsSet = new Set();
    for (const v of rawVehicles) {
      if (v.transmission && typeof v.transmission === 'string' && v.transmission.trim().length > 0) {
        const val = v.transmission.trim();
        transmissionsSet.add(val.charAt(0).toUpperCase() + val.slice(1).toLowerCase());
      }
    }

    // 3. Fuel Types
    const fuelTypesSet = new Set();
    for (const v of rawVehicles) {
      if (v.fuel_type && typeof v.fuel_type === 'string' && v.fuel_type.trim().length > 0) {
        const val = v.fuel_type.trim();
        fuelTypesSet.add(val.charAt(0).toUpperCase() + val.slice(1).toLowerCase());
      }
    }

    // 4. Seat Options
    const seatOptionsSet = new Set();
    for (const v of rawVehicles) {
      const seats = parseInt(v.seats);
      if (!isNaN(seats) && seats > 0) {
        seatOptionsSet.add(seats);
      }
    }

    // 5. Price Range
    const prices = rawVehicles
      .map(v => parseFloat(v.price_per_day))
      .filter(p => !isNaN(p) && p > 0);

    const minPrice = prices.length > 0 ? Math.min(...prices) : 0;
    const maxPrice = prices.length > 0 ? Math.max(...prices) : 0;

    const defaultCarTypes = ['Sedan', 'SUV', 'Hatchback', 'Luxury'];
    const carTypes = carTypesSet.size > 0 ? Array.from(carTypesSet).sort() : defaultCarTypes;

    return {
      carTypes,
      transmissions: Array.from(transmissionsSet).sort(),
      fuelTypes: Array.from(fuelTypesSet).sort(),
      seatOptions: Array.from(seatOptionsSet).sort((a, b) => a - b),
      priceRange: {
        min: minPrice,
        max: maxPrice
      }
    };
  }

  /**
   * Search available cars based on location, dates, attributes, sorting, and pagination.
   */
  async searchVehicles(params = {}) {
    await bookingService._autoTransitionBookings();

    const {
      location,
      pickupDate,
      pickupTime,
      returnDate,
      returnTime,
      filters = {},
      sort = 'recommended',
      page = 1,
      limit = 10
    } = params;

    // 1. Mandatory Location Validation
    if (!location) {
      const error = new Error('Location is required.');
      error.statusCode = 400;
      throw error;
    }

    let searchCity = '';
    let searchLat = null;
    let searchLng = null;

    if (typeof location === 'string') {
      searchCity = location.trim();
    } else if (typeof location === 'object') {
      searchCity = (location.city || location.name || '').trim();
      if (location.latitude !== undefined && location.latitude !== null && location.latitude !== '') {
        searchLat = parseFloat(location.latitude);
      }
      if (location.longitude !== undefined && location.longitude !== null && location.longitude !== '') {
        searchLng = parseFloat(location.longitude);
      }
    }

    if (!searchCity && (searchLat === null || isNaN(searchLat) || searchLng === null || isNaN(searchLng))) {
      const error = new Error('Valid location (name, city, or coordinates) is required.');
      error.statusCode = 400;
      throw error;
    }

    // 2. Mandatory Date & Time Validation
    if (!pickupDate) {
      const error = new Error('Pickup date is required.');
      error.statusCode = 400;
      throw error;
    }
    if (!pickupTime) {
      const error = new Error('Pickup time is required.');
      error.statusCode = 400;
      throw error;
    }
    if (!returnDate) {
      const error = new Error('Return date is required.');
      error.statusCode = 400;
      throw error;
    }
    if (!returnTime) {
      const error = new Error('Return time is required.');
      error.statusCode = 400;
      throw error;
    }

    // Validate Date and Time Formats
    const formattedPickupTime = pickupTime.length === 5 ? `${pickupTime}:00` : pickupTime;
    const formattedReturnTime = returnTime.length === 5 ? `${returnTime}:00` : returnTime;

    const pickupDateTime = new Date(`${pickupDate}T${formattedPickupTime}`);
    const returnDateTime = new Date(`${returnDate}T${formattedReturnTime}`);

    if (isNaN(pickupDateTime.getTime())) {
      const error = new Error('Invalid pickup date or time format. Please use YYYY-MM-DD for date and HH:mm for time.');
      error.statusCode = 400;
      throw error;
    }

    if (isNaN(returnDateTime.getTime())) {
      const error = new Error('Invalid return date or time format. Please use YYYY-MM-DD for date and HH:mm for time.');
      error.statusCode = 400;
      throw error;
    }

    // Check if pickup date is in the past (allow current day)
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const pickupDay = new Date(pickupDateTime);
    pickupDay.setHours(0, 0, 0, 0);

    if (pickupDay < today) {
      const error = new Error('Pickup date cannot be in the past.');
      error.statusCode = 400;
      throw error;
    }

    if (returnDateTime <= pickupDateTime) {
      const error = new Error('Return date and time must be strictly after pickup date and time.');
      error.statusCode = 400;
      throw error;
    }

    // 3. Validate Sort Option
    const validSortOptions = [
      'recommended',
      'price_low_to_high',
      'price_high_to_low',
      'distance_near_to_far',
      'distance_far_to_near',
      'newest'
    ];

    if (sort && !validSortOptions.includes(sort)) {
      const error = new Error(`Invalid sort option: '${sort}'. Allowed options: ${validSortOptions.join(', ')}`);
      error.statusCode = 400;
      throw error;
    }

    const sortOption = sort || 'recommended';

    // 4. Validate Pagination Parameters
    const pageNumber = Math.max(1, parseInt(page) || 1);
    const limitNumber = Math.min(50, Math.max(1, parseInt(limit) || 10));

    // 5. Booking Conflict Exclude Check
    // Query active/confirmed/pending bookings that overlap with requested period
    const { data: overlappingBookings, error: bookingsError } = await supabase
      .from('bookings')
      .select('vehicle_id')
      .in('status', ['pending', 'confirmed', 'active'])
      .lte('start_date', returnDate)
      .gte('end_date', pickupDate);

    let excludedVehicleIds = [];
    if (!bookingsError && overlappingBookings) {
      excludedVehicleIds = [...new Set(overlappingBookings.map(b => b.vehicle_id).filter(Boolean))];
    }

    // 6. Query Active Vehicles from Supabase
    let query = supabase
      .from('vehicles')
      .select(`
        *,
        owner:users (
          id,
          full_name,
          trust_score
        )
      `)
      .eq('status', 'active')
      .eq('is_available', true);

    const { data: rawVehicles, error: vehiclesError } = await query;
    if (vehiclesError) {
      throw new Error(`Failed to query vehicles: ${vehiclesError.message}`);
    }

    let vehiclesList = rawVehicles || [];

    // 7. Exclude Overlapping Bookings & Inactive Availability Windows
    vehiclesList = vehiclesList.filter(vehicle => {
      // Exclude if vehicle has conflicting booking
      if (excludedVehicleIds.includes(vehicle.id)) {
        return false;
      }

      // Check general vehicle availability range if set
      if (vehicle.availability_from) {
        const availFrom = new Date(vehicle.availability_from);
        if (availFrom > pickupDateTime) return false;
      }
      if (vehicle.availability_to) {
        const availTo = new Date(vehicle.availability_to);
        if (availTo < returnDateTime) return false;
      }

      return true;
    });

    // 8. Location Matching & Haversine Distance Calculation
    const normalizedSearchCity = searchCity.toLowerCase();
    const hasCoordinates = searchLat !== null && !isNaN(searchLat) && searchLng !== null && !isNaN(searchLng);

    vehiclesList = vehiclesList.filter(vehicle => {
      const vLat = vehicle.location_lat !== null && vehicle.location_lat !== undefined ? parseFloat(vehicle.location_lat) : null;
      const vLng = vehicle.location_lng !== null && vehicle.location_lng !== undefined ? parseFloat(vehicle.location_lng) : null;

      let distance = null;
      if (hasCoordinates && vLat !== null && !isNaN(vLat) && vLng !== null && !isNaN(vLng)) {
        distance = this._calculateHaversineDistanceKm(searchLat, searchLng, vLat, vLng);
      }
      vehicle._distanceKm = distance;

      // Match condition:
      // If coordinates match within reasonable radius (<= 50km)
      if (distance !== null && distance <= 50) {
        return true;
      }

      // City/Location string matching fallback
      const vCity = (vehicle.city || '').toLowerCase().trim();
      const vPickup = (vehicle.pickup_location || '').toLowerCase().trim();

      if (normalizedSearchCity) {
        const cityMatches =
          vCity.includes(normalizedSearchCity) ||
          normalizedSearchCity.includes(vCity) ||
          vPickup.includes(normalizedSearchCity) ||
          normalizedSearchCity.includes(vPickup);

        if (cityMatches) return true;
      }

      // If user provided coordinates and no distance or city match, check if broad search
      if (hasCoordinates && distance !== null) {
        return distance <= 100; // Expanded vicinity
      }

      return false;
    });

    // 9. Apply Vehicle Attribute Filters
    const {
      carType,
      transmission,
      fuelType,
      fuel_type,
      seats,
      seatingCapacity,
      minPrice,
      maxPrice
    } = filters;

    const requestedFuel = (fuelType || fuel_type || '').toLowerCase().trim();
    const requestedTransmission = (transmission || '').toLowerCase().trim();
    const requestedCarType = (carType || '').toLowerCase().trim();
    const requestedSeats = parseInt(seats || seatingCapacity);
    const filterMinPrice = minPrice !== undefined && minPrice !== null && minPrice !== '' ? parseFloat(minPrice) : null;
    const filterMaxPrice = maxPrice !== undefined && maxPrice !== null && maxPrice !== '' ? parseFloat(maxPrice) : null;

    vehiclesList = vehiclesList.filter(vehicle => {
      // Car Type filter
      if (requestedCarType) {
        const vCarType = (vehicle.car_type || '').toLowerCase().trim();
        const vModel = (vehicle.model || '').toLowerCase().trim();
        const vBrand = (vehicle.brand || '').toLowerCase().trim();
        if (vCarType !== requestedCarType && !vModel.includes(requestedCarType) && !vBrand.includes(requestedCarType)) {
          return false;
        }
      }

      // Transmission filter
      if (requestedTransmission) {
        const vTransmission = (vehicle.transmission || '').toLowerCase().trim();
        if (vTransmission !== requestedTransmission) {
          return false;
        }
      }

      // Fuel Type filter
      if (requestedFuel) {
        const vFuel = (vehicle.fuel_type || '').toLowerCase().trim();
        if (vFuel !== requestedFuel) {
          return false;
        }
      }

      // Seats filter (minimum or exact)
      if (!isNaN(requestedSeats) && requestedSeats > 0) {
        const vSeats = parseInt(vehicle.seats);
        if (isNaN(vSeats) || vSeats < requestedSeats) {
          return false;
        }
      }

      // Price filters
      const vPrice = parseFloat(vehicle.price_per_day);
      if (filterMinPrice !== null && !isNaN(filterMinPrice)) {
        if (isNaN(vPrice) || vPrice < filterMinPrice) {
          return false;
        }
      }
      if (filterMaxPrice !== null && !isNaN(filterMaxPrice)) {
        if (isNaN(vPrice) || vPrice > filterMaxPrice) {
          return false;
        }
      }

      return true;
    });

    // 10. Enrich Vehicle Objects with Ratings, Specs & Clean Formatting
    const enrichedCars = await Promise.all(
      vehiclesList.map(async (vehicle) => {
        const { count } = await supabase
          .from('bookings')
          .select('id', { count: 'exact', head: true })
          .eq('vehicle_id', vehicle.id);

        const reviewsCount = count || 0;
        const rating = vehicle.owner && vehicle.owner.trust_score
          ? parseFloat((vehicle.owner.trust_score / 20).toFixed(1))
          : 4.5;

        const desc = (vehicle.vehicle_description || '').toLowerCase();
        const ac = !desc.includes('no ac') && !desc.includes('no air conditioning');
        const navigation = !desc.includes('no gps') && !desc.includes('no navigation');

        const brand = vehicle.brand || '';
        const model = vehicle.model || '';
        const name = [brand, model].filter(Boolean).join(' ').trim() || 'Car';

        const images = Array.isArray(vehicle.images) ? vehicle.images : [];
        const imageUrl = images.length > 0 ? images[0] : '';

        return {
          id: vehicle.id,
          brand: vehicle.brand,
          model: vehicle.model,
          variant: vehicle.variant,
          name: name,
          carType: vehicle.car_type || 'Sedan',
          car_type: vehicle.car_type || 'Sedan',
          manufacturingYear: vehicle.manufacturing_year,
          manufacturing_year: vehicle.manufacturing_year,
          transmission: vehicle.transmission,
          fuelType: vehicle.fuel_type,
          fuel_type: vehicle.fuel_type,
          seats: vehicle.seats,
          seatingCapacity: vehicle.seats,
          pricePerDay: parseFloat(vehicle.price_per_day) || 0,
          price_per_day: parseFloat(vehicle.price_per_day) || 0,
          depositAmount: parseFloat(vehicle.deposit_amount) || 0,
          deposit_amount: parseFloat(vehicle.deposit_amount) || 0,
          minimumRentalDays: vehicle.minimum_rental_days || 1,
          minimum_rental_days: vehicle.minimum_rental_days || 1,
          deliveryFee: parseFloat(vehicle.delivery_fee) || 0,
          delivery_fee: parseFloat(vehicle.delivery_fee) || 0,
          distanceKm: vehicle._distanceKm !== undefined ? vehicle._distanceKm : null,
          pickupLocation: vehicle.pickup_location,
          pickup_location: vehicle.pickup_location,
          city: vehicle.city,
          state: vehicle.state,
          locationLat: vehicle.location_lat,
          locationLng: vehicle.location_lng,
          location_lat: vehicle.location_lat,
          location_lng: vehicle.location_lng,
          images: images,
          imageUrl: imageUrl,
          image_url: imageUrl,
          rating: rating,
          reviewsCount: reviewsCount,
          reviews_count: reviewsCount,
          status: vehicle.status,
          isAvailable: vehicle.is_available,
          is_available: vehicle.is_available,
          ac: ac,
          navigation: navigation,
          ownerId: vehicle.owner_id,
          owner_id: vehicle.owner_id,
          availabilityFrom: vehicle.availability_from,
          availability_from: vehicle.availability_from,
          availabilityTo: vehicle.availability_to,
          availability_to: vehicle.availability_to,
          createdAt: vehicle.created_at,
          created_at: vehicle.created_at
        };
      })
    );

    // 11. Sorting
    enrichedCars.sort((a, b) => {
      switch (sortOption) {
        case 'price_low_to_high':
          return (a.pricePerDay || 0) - (b.pricePerDay || 0);

        case 'price_high_to_low':
          return (b.pricePerDay || 0) - (a.pricePerDay || 0);

        case 'distance_near_to_far': {
          const distA = a.distanceKm !== null ? a.distanceKm : 999999;
          const distB = b.distanceKm !== null ? b.distanceKm : 999999;
          return distA - distB;
        }

        case 'distance_far_to_near': {
          const distA = a.distanceKm !== null ? a.distanceKm : -1;
          const distB = b.distanceKm !== null ? b.distanceKm : -1;
          return distB - distA;
        }

        case 'newest':
          return new Date(b.createdAt || 0) - new Date(a.createdAt || 0);

        case 'recommended':
        default: {
          // Multi-factor recommended score:
          // 1. Rating (higher preferred)
          const ratingDiff = (b.rating || 4.5) - (a.rating || 4.5);
          if (Math.abs(ratingDiff) >= 0.4) return ratingDiff;

          // 2. Proximity (closer preferred if distances exist)
          if (a.distanceKm !== null && b.distanceKm !== null) {
            const distDiff = a.distanceKm - b.distanceKm;
            if (Math.abs(distDiff) >= 2.0) return distDiff;
          }

          // 3. Price (lower preferred)
          return (a.pricePerDay || 0) - (b.pricePerDay || 0);
        }
      }
    });

    // 12. Pagination
    const total = enrichedCars.length;
    const totalPages = total > 0 ? Math.ceil(total / limitNumber) : 0;
    const startIndex = (pageNumber - 1) * limitNumber;
    const paginatedCars = enrichedCars.slice(startIndex, startIndex + limitNumber);

    const response = {
      success: true,
      search: {
        location: location,
        pickupDate: pickupDate,
        pickupTime: pickupTime,
        returnDate: returnDate,
        returnTime: returnTime
      },
      count: paginatedCars.length,
      cars: paginatedCars,
      pagination: {
        page: pageNumber,
        limit: limitNumber,
        total: total,
        totalPages: totalPages
      }
    };

    if (total === 0) {
      response.message = 'No cars are available for the selected location and dates.';
    }

    return response;
  }
}

module.exports = new VehicleService();
