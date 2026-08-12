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
        status: 'pending',
        payment_status: 'unpaid',
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
   * Automatically transition bookings whose start/end date has passed.
   */
  async _autoTransitionBookings() {
    try {
      const { data: bookings, error } = await supabase
        .from('bookings')
        .select('id, start_date, end_date, status, payment_status, vehicle_id')
        .not('status', 'in', '("completed","cancelled")');

      if (error || !bookings) return;

      const now = new Date();

      for (const booking of bookings) {
        let newStatus = null;
        let cancelledReason = null;

        const startDate = new Date(booking.start_date);
        const endDate = new Date(booking.end_date);

        if (booking.status === 'pending' || (booking.status === 'confirmed' && booking.payment_status === 'unpaid')) {
          if (now > startDate) {
            newStatus = 'cancelled';
            cancelledReason = 'Booking request expired (unpaid/unapproved before start time)';
          }
        } else if (booking.status === 'confirmed' && booking.payment_status === 'paid') {
          if (now >= startDate) {
            if (now >= endDate) {
              newStatus = 'completed';
            } else {
              newStatus = 'active';
            }
          }
        } else if (booking.status === 'active') {
          if (now >= endDate) {
            newStatus = 'completed';
          }
        }

        if (newStatus) {
          if (newStatus === 'cancelled') {
            await supabase
              .from('bookings')
              .update({
                status: 'cancelled',
                cancelled_by: 'system',
                cancelled_at: new Date().toISOString(),
                cancellation_reason: cancelledReason,
                updated_at: new Date().toISOString()
              })
              .eq('id', booking.id);

            await this._restoreVehicleAvailability(booking.vehicle_id);
          } else if (newStatus === 'active') {
            await supabase
              .from('bookings')
              .update({
                status: 'active',
                updated_at: new Date().toISOString()
              })
              .eq('id', booking.id);
          } else if (newStatus === 'completed') {
            await supabase
              .from('bookings')
              .update({
                status: 'completed',
                updated_at: new Date().toISOString()
              })
              .eq('id', booking.id);

            await this._restoreVehicleAvailability(booking.vehicle_id);
          }
        }
      }
    } catch (e) {
      console.error('Error auto transitioning bookings:', e);
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
    await this._autoTransitionBookings();
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
    await this._autoTransitionBookings();
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
    await this._autoTransitionBookings();
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
        payment_status: 'unpaid', // Keep unpaid until renter pays
        updated_at: new Date().toISOString()
      })
      .eq('id', bookingId)
      .select()
      .single();

    if (updateError) throw updateError;
    return data;
  }

  /**
   * Confirm booking payment (Renter only).
   */
  async confirmPayment(bookingId, userId) {
    const booking = await this.getBookingById(bookingId, userId);

    if (booking.renter_id !== userId) {
      const error = new Error('Only the renter can make payment for this booking');
      error.statusCode = 403;
      throw error;
    }

    if (booking.status !== 'confirmed') {
      const error = new Error('Booking must be confirmed by the owner before payment can be made');
      error.statusCode = 400;
      throw error;
    }

    const { data, error: updateError } = await supabase
      .from('bookings')
      .update({
        payment_status: 'paid',
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

  /**
   * Update real-time GPS location of a booking during an active trip.
   */
  async updateBookingLocation(bookingId, renterId, lat, lng) {
    if (!bookingId || lat == null || lng == null) {
      const error = new Error('Booking ID, latitude, and longitude are required');
      error.statusCode = 400;
      throw error;
    }

    const { data: booking, error: fetchError } = await supabase
      .from('bookings')
      .select('id, renter_id, status')
      .eq('id', bookingId)
      .single();

    if (fetchError || !booking) {
      const error = new Error('Booking not found');
      error.statusCode = 404;
      throw error;
    }

    if (booking.renter_id !== renterId) {
      const error = new Error('Unauthorized to update location for this booking');
      error.statusCode = 403;
      throw error;
    }

    const now = new Date().toISOString();
    const { data, error: updateError } = await supabase
      .from('bookings')
      .update({
        current_lat: parseFloat(lat),
        current_lng: parseFloat(lng),
        last_tracked_at: now,
        updated_at: now
      })
      .eq('id', bookingId)
      .select()
      .single();

    if (updateError) {
      console.log(`⚠️ Note: current_lat/current_lng column update warning: ${updateError.message}`);
      return { id: bookingId, current_lat: parseFloat(lat), current_lng: parseFloat(lng), last_tracked_at: now };
    }

    return data;
  }
}

module.exports = new BookingService();
