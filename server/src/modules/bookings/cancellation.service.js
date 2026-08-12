// cancellation.service.js
const { supabase } = require('../../config/supabase');

class CancellationService {
  /**
   * Calculates cancellation fees and refunds.
   * @param {object} booking - Booking data from DB
   * @param {string} cancelledBy - 'renter' | 'owner' | 'system'
   * @returns {object} { cancellationFee, refundAmount }
   */
  calculateCancellation(booking, cancelledBy) {
    const totalPrice = parseFloat(booking.total_price);
    const depositAmount = parseFloat(booking.deposit_amount);

    // If cancelled by owner or system, the renter always receives a 100% refund (0 fee)
    if (cancelledBy === 'owner' || cancelledBy === 'system') {
      return {
        cancellationFee: 0,
        refundAmount: totalPrice + depositAmount
      };
    }

    // Cancelled by renter: time-based tiers
    const now = new Date();
    // Parse start_date. Assuming start of day local/UTC for calculations
    const startDate = new Date(booking.start_date);

    const timeDiffMs = startDate.getTime() - now.getTime();
    const hoursBeforeStart = timeDiffMs / (1000 * 60 * 60);

    let feePercentage = 0;
    if (hoursBeforeStart >= 48) {
      // > 48 hours: 0% fee
      feePercentage = 0;
    } else if (hoursBeforeStart >= 24) {
      // 24 to 48 hours: 50% fee on rental amount
      feePercentage = 50;
    } else {
      // < 24 hours: 100% fee on rental amount
      feePercentage = 100;
    }

    const cancellationFee = (totalPrice * feePercentage) / 100;
    // Deposit is ALWAYS fully refunded
    const refundAmount = depositAmount + (totalPrice - cancellationFee);

    return {
      cancellationFee: Math.round(cancellationFee * 100) / 100,
      refundAmount: Math.round(refundAmount * 100) / 100
    };
  }

  /**
   * Handles user model side effects for owner cancellation.
   * Increments the cancellation_count of the car owner in the users table.
   * @param {string} vehicleId - Vehicle ID
   */
  async processOwnerCancellationSideEffects(vehicleId) {
    // 1. Find the vehicle owner
    const { data: vehicle, error: vehicleError } = await supabase
      .from('vehicles')
      .select('owner_id')
      .eq('id', vehicleId)
      .maybeSingle();

    if (vehicleError || !vehicle) {
      throw new Error(`Failed to find vehicle for side effects: ${vehicleError?.message}`);
    }

    const ownerId = vehicle.owner_id;

    // 2. Fetch current user data
    const { data: owner, error: ownerError } = await supabase
      .from('users')
      .select('cancellation_count')
      .eq('id', ownerId)
      .maybeSingle();

    if (ownerError || !owner) {
      throw new Error(`Failed to find owner for side effects: ${ownerError?.message}`);
    }

    // 3. Increment cancellation count
    const newCount = (owner.cancellation_count || 0) + 1;
    const { error: updateError } = await supabase
      .from('users')
      .update({ cancellation_count: newCount })
      .eq('id', ownerId);

    if (updateError) {
      throw new Error(`Failed to update owner cancellation count: ${updateError.message}`);
    }
  }
}

module.exports = new CancellationService();
