// booking.service.js
const { supabase } = require('../../config/supabase');
const bookingValidation = require('./booking.validation');
const pricingService = require('./pricing.service');
const cancellationService = require('./cancellation.service');
const stateMachine = require('./booking.state-machine');

class BookingService {
  /**
   * Create a new booking request.
   */
  async createBooking(renterId, { vehicleId, startDate, endDate, totalPrice }) {
    // 1. Run validation checks
    const vehicle = await bookingValidation.validateBookingCreation(vehicleId, renterId, startDate, endDate);

    // 2. Calculate pricing
    const pricing = pricingService.calculatePricing(vehicle.price_per_day, vehicle.deposit_amount, startDate, endDate);

    // 3. Insert the booking as confirmed and paid — no owner approval required.
    const { data: booking, error: insertError } = await supabase
      .from('bookings')
      .insert({
        vehicle_id: vehicleId,
        renter_id: renterId,
        start_date: startDate,
        end_date: endDate,
        status: 'confirmed',
        payment_status: 'paid',
        total_price: totalPrice !== undefined ? totalPrice : pricing.totalPrice,
        deposit_amount: pricing.depositAmount
      })
      .select()
      .single();

    if (insertError) {
      // Forward the error to let error middleware capture 23P01 (overlap)
      throw insertError;
    }

    // 4. Mark the vehicle as unavailable so it is hidden from the home listing
    await supabase
      .from('vehicles')
      .update({ is_available: false, updated_at: new Date().toISOString() })
      .eq('id', vehicleId);

    return booking;
  }

  /**
   * Restore vehicle availability if no other active/confirmed bookings exist.
   */
  async _restoreVehicleAvailability(vehicleId) {
    const { data: activeBookings } = await supabase
      .from('bookings')
      .select('id')
      .eq('vehicle_id', vehicleId)
      .in('status', ['confirmed', 'active'])
      .limit(1);

    if (!activeBookings || activeBookings.length === 0) {
      await supabase
        .from('vehicles')
        .update({ is_available: true, updated_at: new Date().toISOString() })
        .eq('id', vehicleId);
    }
  }

  /**
   * Check if a vehicle is available for a date range.
   */
  async checkAvailability(vehicleId, startDate, endDate) {
    if (!vehicleId || !startDate || !endDate) {
      const error = new Error('vehicleId, startDate, and endDate are required');
      error.statusCode = 400;
      throw error;
    }

    // Overlap query: (start_date <= input_end AND end_date >= input_start)
    // where status is in pending, confirmed, active
    const { data, error } = await supabase
      .from('bookings')
      .select('id')
      .eq('vehicle_id', vehicleId)
      .in('status', ['pending', 'confirmed', 'active'])
      .lte('start_date', endDate)
      .gte('end_date', startDate);

    if (error) {
      throw new Error(`Failed to check availability: ${error.message}`);
    }

    return {
      available: data.length === 0
    };
  }

  /**
   * Fetch renter bookings.
   */
  async getMyBookings(renterId) {
    const { data, error } = await supabase
      .from('bookings')
      .select(`
        *,
        vehicle:vehicles (*)
      `)
      .eq('renter_id', renterId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch bookings: ${error.message}`);
    }

    return data;
  }

  /**
   * Fetch owner bookings (bookings on vehicles owned by user).
   */
  async getMyVehicleBookings(ownerId) {
    // We join the vehicles table and perform an inner join filter
    const { data, error } = await supabase
      .from('bookings')
      .select(`
        *,
        vehicle:vehicles!inner (*)
      `)
      .eq('vehicle.owner_id', ownerId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch vehicle bookings: ${error.message}`);
    }

    return data;
  }

  /**
   * Fetch a single booking. Must be owner of car or renter.
   */
  async getBookingById(bookingId, userId) {
    const { data: booking, error } = await supabase
      .from('bookings')
      .select(`
        *,
        vehicle:vehicles (*)
      `)
      .eq('id', bookingId)
      .maybeSingle();

    if (error || !booking) {
      const err = new Error('Booking not found');
      err.statusCode = 404;
      throw err;
    }

    if (booking.renter_id !== userId && booking.vehicle.owner_id !== userId) {
      const err = new Error('You are not authorized to view this booking');
      err.statusCode = 403;
      throw err;
    }

    return booking;
  }

  /**
   * Confirm booking request (Owner only).
   */
  async confirmBooking(bookingId, userId) {
    const booking = await this.getBookingById(bookingId, userId);

    // Verify requesting user is the vehicle owner
    if (booking.vehicle.owner_id !== userId) {
      const error = new Error('Only the vehicle owner can confirm this booking');
      error.statusCode = 403;
      throw error;
    }

    if (!stateMachine.isValidTransition(booking.status, 'confirmed')) {
      const error = new Error(`Cannot transition booking from ${booking.status} to confirmed`);
      error.statusCode = 400;
      throw error;
    }

    const { data, error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'confirmed',
        payment_status: 'paid', // Simulate successful payment upon owner confirmation
        updated_at: new Date().toISOString()
      })
      .eq('id', bookingId)
      .select()
      .single();

    if (updateError) throw updateError;
    return data;
  }

  /**
   * Start booking (Transition to Active).
   */
  async startBooking(bookingId, userId) {
    const booking = await this.getBookingById(bookingId, userId);

    // Can be started by owner or renter
    if (booking.renter_id !== userId && booking.vehicle.owner_id !== userId) {
      const error = new Error('Unauthorized to start this booking');
      error.statusCode = 403;
      throw error;
    }

    if (!stateMachine.isValidTransition(booking.status, 'active')) {
      const error = new Error(`Cannot transition booking from ${booking.status} to active`);
      error.statusCode = 400;
      throw error;
    }

    const { data, error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'active',
        updated_at: new Date().toISOString()
      })
      .eq('id', bookingId)
      .select()
      .single();

    if (updateError) throw updateError;
    return data;
  }

  /**
   * Complete booking (Owner only).
   */
  async completeBooking(bookingId, userId) {
    const booking = await this.getBookingById(bookingId, userId);

    if (booking.vehicle.owner_id !== userId) {
      const error = new Error('Only the vehicle owner can complete this booking');
      error.statusCode = 403;
      throw error;
    }

    if (!stateMachine.isValidTransition(booking.status, 'completed')) {
      const error = new Error(`Cannot transition booking from ${booking.status} to completed`);
      error.statusCode = 400;
      throw error;
    }

    const { data, error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'completed',
        updated_at: new Date().toISOString()
      })
      .eq('id', bookingId)
      .select()
      .single();

    if (updateError) throw updateError;

    // Restore availability if no other active bookings remain
    await this._restoreVehicleAvailability(booking.vehicle_id);

    return data;
  }

  /**
   * Cancel booking.
   */
  async cancelBooking(bookingId, userId, reason) {
    const booking = await this.getBookingById(bookingId, userId);

    if (!stateMachine.isValidTransition(booking.status, 'cancelled')) {
      const error = new Error(`Cannot cancel a booking in '${booking.status}' status.`);
      error.statusCode = 400;
      throw error;
    }

    // Determine who is cancelling
    let cancelledBy = 'system';
    if (booking.renter_id === userId) {
      cancelledBy = 'renter';
    } else if (booking.vehicle.owner_id === userId) {
      cancelledBy = 'owner';
    }

    // Calculate fees and refunds using the cancellation service
    const { cancellationFee, refundAmount } = cancellationService.calculateCancellation(booking, cancelledBy);

    // Apply side effects: if cancelled by owner, increment their cancellation count
    if (cancelledBy === 'owner') {
      await cancellationService.processOwnerCancellationSideEffects(booking.vehicle_id);
    }

    const { data, error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'cancelled',
        cancelled_by: cancelledBy,
        cancelled_at: new Date().toISOString(),
        cancellation_reason: reason || 'Cancelled by user',
        cancellation_fee: cancellationFee,
        refund_amount: refundAmount,
        payment_status: booking.payment_status === 'paid' ? 'refunded' : 'unpaid',
        updated_at: new Date().toISOString()
      })
      .eq('id', bookingId)
      .select()
      .single();

    if (updateError) throw updateError;

    // Restore vehicle availability once booking is cancelled
    await this._restoreVehicleAvailability(booking.vehicle_id);

    return data;
  }
}

module.exports = new BookingService();
