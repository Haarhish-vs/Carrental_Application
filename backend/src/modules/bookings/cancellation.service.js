const { isValidTransition } = require('./booking.state-machine');

/**
 * Pure function to calculate cancellation fee and refund amount.
 * @param {object} booking - Booking details: { start_date, total_price, deposit_amount }
 * @param {string} cancelledBy - 'renter' | 'owner' | 'system'
 * @param {Date|string} [cancellationTime] - Optional cancellation timestamp (defaults to now)
 * @returns {object} { cancellationFee, refundAmount, hoursBeforeStart }
 */
function calculateCancellationFee(booking, cancelledBy, cancellationTime = new Date()) {
  const totalRental = Number(booking.total_price);
  const deposit = Number(booking.deposit_amount);
  
  // Calculate hours before start_date.
  // Parse start_date. Since start_date is a DATE, treat start of day as midnight UTC.
  const startStr = booking.start_date.includes('T') ? booking.start_date : `${booking.start_date}T00:00:00.000Z`;
  const startTime = new Date(startStr).getTime();
  const cancelTime = new Date(cancellationTime).getTime();
  
  const diffMs = startTime - cancelTime;
  const hoursBeforeStart = diffMs / (1000 * 60 * 60);
  
  if (cancelledBy === 'owner' || cancelledBy === 'system') {
    // Owner or system cancellation -> Renter gets full refund, no fee
    return {
      cancellationFee: 0,
      refundAmount: Number((totalRental + deposit).toFixed(2)),
      hoursBeforeStart
    };
  }
  
  // Renter cancellation
  let cancellationFee = 0;
  let refundAmount = 0;
  
  if (hoursBeforeStart > 48) {
    // More than 48 hours: full refund, no fee
    cancellationFee = 0;
    refundAmount = totalRental + deposit;
  } else if (hoursBeforeStart >= 24) {
    // 24 to 48 hours: 50% fee on rental, deposit fully refunded
    cancellationFee = totalRental * 0.5;
    refundAmount = (totalRental * 0.5) + deposit;
  } else {
    // Less than 24 hours: 100% fee on rental, deposit fully refunded
    cancellationFee = totalRental;
    refundAmount = deposit;
  }
  
  return {
    cancellationFee: Number(cancellationFee.toFixed(2)),
    refundAmount: Number(refundAmount.toFixed(2)),
    hoursBeforeStart
  };
}

/**
 * Handles the cancellation process.
 * @param {object} supabase - Supabase client
 * @param {string} bookingId - UUID of the booking
 * @param {string} userId - ID of the user requesting cancellation
 * @param {string} reason - Cancellation reason
 * @returns {object} Updated booking data
 */
async function cancelBookingWorkflow(supabase, bookingId, userId, reason) {
  // 1. Fetch booking with vehicle details to verify role (renter vs owner)
  const { data: booking, error: fetchError } = await supabase
    .from('bookings')
    .select(`
      *,
      vehicles (
        owner_id
      )
    `)
    .eq('id', bookingId)
    .single();

  if (fetchError || !booking) {
    const error = new Error('Booking not found');
    error.status = 404;
    throw error;
  }

  const ownerId = booking.vehicles ? booking.vehicles.owner_id : null;
  const renterId = booking.renter_id;

  // 2. Authorization check
  const isRenter = userId === renterId;
  const isOwner = userId === ownerId;

  if (!isRenter && !isOwner) {
    const error = new Error('Forbidden: You are not authorized to cancel this booking');
    error.status = 403;
    throw error;
  }

  // 3. Status check
  if (!isValidTransition(booking.status, 'cancelled')) {
    const error = new Error('This booking cannot be cancelled at its current stage');
    error.status = 400;
    throw error;
  }

  const cancelledBy = isOwner ? 'owner' : 'renter';

  // 4. Calculate fees
  const { cancellationFee, refundAmount } = calculateCancellationFee(booking, cancelledBy);

  // 5. Perform the booking update
  const { data: updatedBooking, error: updateError } = await supabase
    .from('bookings')
    .update({
      status: 'cancelled',
      payment_status: refundAmount > 0 ? 'refunded' : booking.payment_status,
      cancelled_by: cancelledBy,
      cancelled_at: new Date().toISOString(),
      cancellation_reason: reason || null,
      cancellation_fee: cancellationFee,
      refund_amount: refundAmount,
      updated_at: new Date().toISOString()
    })
    .eq('id', bookingId)
    .select()
    .single();

  if (updateError) {
    throw updateError;
  }

  // 6. If owner-cancelled, increment cancellation_count in owner's user record
  if (isOwner) {
    // Check if owner has a profile entry.
    const { data: profile } = await supabase
      .from('profiles')
      .select('cancellation_count')
      .eq('id', ownerId)
      .single();

    if (profile) {
      await supabase
        .from('profiles')
        .update({
          cancellation_count: (profile.cancellation_count || 0) + 1,
          updated_at: new Date().toISOString()
        })
        .eq('id', ownerId);
    } else {
      // Fallback: If no profiles table or profile row, try creating or updating auth metadata / users profiles
      // We will try updating profiles just in case. If it errors, we log it but don't fail the transaction.
      await supabase
        .from('profiles')
        .insert({
          id: ownerId,
          cancellation_count: 1,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .catch(() => {});
    }
  }

  return updatedBooking;
}

module.exports = {
  calculateCancellationFee,
  cancelBookingWorkflow
};
