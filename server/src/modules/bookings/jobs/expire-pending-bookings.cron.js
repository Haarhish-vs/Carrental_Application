// expire-pending-bookings.cron.js
const cron = require('node-cron');
const { supabase } = require('../../../config/supabase');

/**
 * Searches for bookings in 'pending' status that are 'unpaid'
 * and created more than 15 minutes ago, and cancels them.
 */
const expirePendingBookings = async () => {
  try {
    const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000).toISOString();

    const { data: staleBookings, error: fetchError } = await supabase
      .from('bookings')
      .select('id, total_price, deposit_amount')
      .eq('status', 'pending')
      .eq('payment_status', 'unpaid')
      .lt('created_at', fifteenMinutesAgo);

    if (fetchError) {
      console.error('[Cron Job Expiry Error] Fetching stale bookings failed:', fetchError.message);
      return;
    }

    if (!staleBookings || staleBookings.length === 0) {
      return;
    }

    if (process.env.NODE_ENV !== 'test') {
      console.log(`[Cron Job] Found ${staleBookings.length} stale pending bookings. Cancelling...`);
    }

    for (const booking of staleBookings) {
      const { error: updateError } = await supabase
        .from('bookings')
        .update({
          status: 'cancelled',
          cancelled_by: 'system',
          cancelled_at: new Date().toISOString(),
          cancellation_reason: 'Unpaid booking expired automatically after 15 minutes.',
          cancellation_fee: 0,
          refund_amount: 0,
          updated_at: new Date().toISOString()
        })
        .eq('id', booking.id);

      if (updateError) {
        console.error(`[Cron Job] Failed to expire booking ${booking.id}:`, updateError.message);
      } else {
        if (process.env.NODE_ENV !== 'test') {
          console.log(`[Cron Job] Expired unpaid booking: ${booking.id}`);
        }
      }
    }
  } catch (error) {
    console.error('[Cron Job Expiry Error] Stale check failed:', error);
  }
};

/**
 * Start the node-cron scheduler.
 */
const startCron = () => {
  // Run every 10 minutes: */10 * * * *
  cron.schedule('*/10 * * * *', expirePendingBookings);
  console.log('[Cron Scheduler] Expired bookings job successfully scheduled (Runs every 10 mins).');
};

module.exports = {
  startCron,
  expirePendingBookings
};
