// vehicle.service.js
const { supabase } = require('../../config/supabase');

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

    if (isAvailable) {
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
      .update({ is_available: !!isAvailable, updated_at: new Date().toISOString() })
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
    const { data, error } = await supabase
      .from('vehicles')
      .select('*')
      .eq('owner_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to retrieve listings: ${error.message}`);
    }

    return data;
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
}

module.exports = new VehicleService();
