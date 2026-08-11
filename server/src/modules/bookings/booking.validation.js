// booking.validation.js
const { supabase } = require('../../config/supabase');

/**
 * Validates booking creation parameters and rules.
 * @param {string} vehicleId - Vehicle ID
 * @param {string} renterId - Renter user ID
 * @param {string} startDateStr - Start date ISO string
 * @param {string} endDateStr - End date ISO string
 * @returns {Promise<object>} Vehicle details if valid
 */
const validateBookingCreation = async (vehicleId, renterId, startDateStr, endDateStr) => {
  if (!vehicleId || !renterId || !startDateStr || !endDateStr) {
    const error = new Error('All booking parameters (vehicleId, startDate, endDate) are required');
    error.statusCode = 400;
    throw error;
  }

  const start = new Date(startDateStr);
  const end = new Date(endDateStr);

  if (isNaN(start.getTime()) || isNaN(end.getTime())) {
    const error = new Error('Invalid start_date or end_date format. Please use YYYY-MM-DD.');
    error.statusCode = 400;
    throw error;
  }

  // Convert to date-only representation at midnight to prevent local time errors
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const startMidnight = new Date(start);
  startMidnight.setHours(0, 0, 0, 0);
  
  const endMidnight = new Date(end);
  endMidnight.setHours(0, 0, 0, 0);

  if (startMidnight < today) {
    const error = new Error('Booking start date cannot be in the past');
    error.statusCode = 400;
    throw error;
  }

  if (startMidnight > endMidnight) {
    const error = new Error('Booking end date must be on or after start date');
    error.statusCode = 400;
    throw error;
  }

  // 1. Fetch vehicle verification status, availability status, owner, price, deposit
  const { data: vehicle, error: vehicleError } = await supabase
    .from('vehicles')
    .select('id, owner_id, status, is_available, price_per_day, deposit_amount')
    .eq('id', vehicleId)
    .maybeSingle();

  if (vehicleError || !vehicle) {
    const error = new Error('The requested vehicle was not found');
    error.statusCode = 404;
    throw error;
  }

  // 2. Validate booking policy rules
  if (vehicle.owner_id === renterId) {
    const error = new Error('You cannot book your own vehicle listing.');
    error.statusCode = 400;
    throw error;
  }

  if (vehicle.status !== 'active') {
    const error = new Error('This vehicle listing is not active and cannot be booked.');
    error.statusCode = 400;
    throw error;
  }

  if (!vehicle.is_available) {
    const error = new Error('This vehicle is temporarily marked unavailable by the owner.');
    error.statusCode = 400;
    throw error;
  }

  // 3. Check for overlapping bookings
  const { data: overlappingBookings, error: bookingsError } = await supabase
    .from('bookings')
    .select('id')
    .eq('vehicle_id', vehicleId)
    .in('status', ['pending', 'confirmed', 'active'])
    .lte('start_date', endDateStr)
    .gte('end_date', startDateStr);

  if (bookingsError) {
    throw new Error(`Failed to check booking availability: ${bookingsError.message}`);
  }

  if (overlappingBookings && overlappingBookings.length > 0) {
    const error = new Error('Double-booking conflict: This vehicle is already booked for the selected period.');
    error.statusCode = 409;
    throw error;
  }

  return vehicle;
};

module.exports = {
  validateBookingCreation
};
