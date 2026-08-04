const { calculatePricing } = require('./pricing.service');
const { isValidTransition } = require('./booking.state-machine');

/**
 * Checks if a vehicle is available for a given date range.
 * A vehicle is unavailable if there are any overlapping bookings that are not cancelled.
 */
async function checkVehicleAvailability(supabase, vehicleId, startDate, endDate) {
  const { data, error } = await supabase
    .from('bookings')
    .select('id')
    .eq('vehicle_id', vehicleId)
    .in('status', ['pending', 'confirmed', 'active'])
    .lte('start_date', endDate)
    .gte('end_date', startDate);

  if (error) {
    throw error;
  }

  return data.length === 0;
}

/**
 * Creates a new booking after validating conditions and checking constraints.
 */
async function createBooking(supabase, renterId, { vehicle_id, start_date, end_date }) {
  // 1. Fetch vehicle details to validate existence, status, and owner
  const { data: vehicle, error: vehicleErr } = await supabase
    .from('vehicles')
    .select('id, owner_id, price_per_day, deposit_amount, status')
    .eq('id', vehicle_id)
    .single();

  if (vehicleErr || !vehicle) {
    const error = new Error('Vehicle not found');
    error.status = 404;
    throw error;
  }

  if (vehicle.status !== 'active') {
    const error = new Error('This vehicle is not active and cannot be booked');
    error.status = 400;
    throw error;
  }

  if (vehicle.owner_id === renterId) {
    const error = new Error('You cannot book your own vehicle');
    error.status = 400;
    throw error;
  }

  // 2. Calculate the pricing based on duration
  const pricing = calculatePricing(vehicle.price_per_day, vehicle.deposit_amount, start_date, end_date);

  // 3. Insert the booking into the database
  const { data: newBooking, error: insertErr } = await supabase
    .from('bookings')
    .insert({
      vehicle_id,
      renter_id: renterId,
      start_date,
      end_date,
      status: 'pending',
      payment_status: 'unpaid',
      total_price: pricing.total,
      deposit_amount: pricing.deposit,
      cancellation_fee: 0,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    })
    .select()
    .single();

  if (insertErr) {
    // Catch PostgreSQL code 23P01 (exclusion violation) for overlapping dates
    if (insertErr.code === '23P01') {
      const error = new Error('This vehicle is already booked for these dates');
      error.status = 409;
      throw error;
    }
    throw insertErr;
  }

  return newBooking;
}

/**
 * Gets all bookings where the current user is the renter.
 */
async function getMyBookings(supabase, renterId) {
  const { data, error } = await supabase
    .from('bookings')
    .select('*, vehicles(*)')
    .eq('renter_id', renterId)
    .order('created_at', { ascending: false });

  if (error) {
    throw error;
  }

  return data;
}

/**
 * Gets bookings for vehicles owned by the current user.
 */
async function getMyVehicleBookings(supabase, ownerId) {
  const { data, error } = await supabase
    .from('bookings')
    .select('*, vehicles!inner(*)')
    .eq('vehicles.owner_id', ownerId)
    .order('created_at', { ascending: false });

  if (error) {
    throw error;
  }

  return data;
}

/**
 * Retrieves a single booking detail if the user is authorized (renter or vehicle owner).
 */
async function getBookingDetails(supabase, bookingId, userId) {
  const { data: booking, error } = await supabase
    .from('bookings')
    .select('*, vehicles(owner_id)')
    .eq('id', bookingId)
    .single();

  if (error || !booking) {
    const err = new Error('Booking not found');
    err.status = 404;
    throw err;
  }

  const ownerId = booking.vehicles ? booking.vehicles.owner_id : null;
  const isRenter = booking.renter_id === userId;
  const isOwner = ownerId === userId;

  if (!isRenter && !isOwner) {
    const err = new Error('Forbidden: You are not authorized to view this booking');
    err.status = 403;
    throw err;
  }

  return booking;
}

/**
 * Transition status from pending to confirmed.
 * Only the vehicle owner can confirm.
 */
async function confirmBooking(supabase, bookingId, ownerId) {
  const { data: booking, error: fetchErr } = await supabase
    .from('bookings')
    .select('*, vehicles(owner_id)')
    .eq('id', bookingId)
    .single();

  if (fetchErr || !booking) {
    const error = new Error('Booking not found');
    error.status = 404;
    throw error;
  }

  const vOwnerId = booking.vehicles ? booking.vehicles.owner_id : null;
  if (vOwnerId !== ownerId) {
    const error = new Error('Forbidden: Only the vehicle owner can confirm this booking');
    error.status = 403;
    throw error;
  }

  if (!isValidTransition(booking.status, 'confirmed')) {
    const error = new Error(`Cannot transition booking from ${booking.status} to confirmed`);
    error.status = 400;
    throw error;
  }

  const { data: updatedBooking, error: updateErr } = await supabase
    .from('bookings')
    .update({
      status: 'confirmed',
      payment_status: 'paid', // Auto mark paid for simple confirmed flow
      updated_at: new Date().toISOString()
    })
    .eq('id', bookingId)
    .select()
    .single();

  if (updateErr) {
    throw updateErr;
  }

  return updatedBooking;
}

/**
 * Transition status from confirmed to active.
 * Renter or Owner can start the trip.
 */
async function startTrip(supabase, bookingId, userId) {
  const { data: booking, error: fetchErr } = await supabase
    .from('bookings')
    .select('*, vehicles(owner_id)')
    .eq('id', bookingId)
    .single();

  if (fetchErr || !booking) {
    const error = new Error('Booking not found');
    error.status = 404;
    throw error;
  }

  const ownerId = booking.vehicles ? booking.vehicles.owner_id : null;
  if (userId !== booking.renter_id && userId !== ownerId) {
    const error = new Error('Forbidden: You are not authorized to start this trip');
    error.status = 403;
    throw error;
  }

  if (!isValidTransition(booking.status, 'active')) {
    const error = new Error(`Cannot transition booking from ${booking.status} to active`);
    error.status = 400;
    throw error;
  }

  const { data: updatedBooking, error: updateErr } = await supabase
    .from('bookings')
    .update({
      status: 'active',
      updated_at: new Date().toISOString()
    })
    .eq('id', bookingId)
    .select()
    .single();

  if (updateErr) {
    throw updateErr;
  }

  return updatedBooking;
}

/**
 * Transition status from active to completed.
 * Renter or Owner can mark the trip as complete.
 */
async function completeBooking(supabase, bookingId, userId) {
  const { data: booking, error: fetchErr } = await supabase
    .from('bookings')
    .select('*, vehicles(owner_id)')
    .eq('id', bookingId)
    .single();

  if (fetchErr || !booking) {
    const error = new Error('Booking not found');
    error.status = 404;
    throw error;
  }

  const ownerId = booking.vehicles ? booking.vehicles.owner_id : null;
  if (userId !== booking.renter_id && userId !== ownerId) {
    const error = new Error('Forbidden: You are not authorized to complete this trip');
    error.status = 403;
    throw error;
  }

  if (!isValidTransition(booking.status, 'completed')) {
    const error = new Error(`Cannot transition booking from ${booking.status} to completed`);
    error.status = 400;
    throw error;
  }

  const { data: updatedBooking, error: updateErr } = await supabase
    .from('bookings')
    .update({
      status: 'completed',
      updated_at: new Date().toISOString()
    })
    .eq('id', bookingId)
    .select()
    .single();

  if (updateErr) {
    throw updateErr;
  }

  return updatedBooking;
}

module.exports = {
  checkVehicleAvailability,
  createBooking,
  getMyBookings,
  getMyVehicleBookings,
  getBookingDetails,
  confirmBooking,
  startTrip,
  completeBooking
};
