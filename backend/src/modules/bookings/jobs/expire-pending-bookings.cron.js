const cron = require('node-cron');
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL || 'https://placeholder.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'placeholder-key';
const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * Logic to find and cancel stale, unpaid pending bookings older than 15 minutes.
 */
async function expirePendingBookings() {
  console.log('[Cron Job] Checking for stale pending bookings...');
  try {
    const cutOffTime = new Date(Date.now() - 15 * 60 * 1000).toISOString();
    
    // Fetch pending bookings that are unpaid and created more than 15 minutes ago
    const { data: staleBookings, error: fetchError } = await supabase
      .from('bookings')
      .select('id, total_price, deposit_amount')
      .eq('status', 'pending')
      .eq('payment_status', 'unpaid')
      .lt('created_at', cutOffTime);
      
    if (fetchError) {
      console.error('[Cron Job] Error fetching stale bookings:', fetchError.message);
      return;
    }
    
    if (!staleBookings || staleBookings.length === 0) {
      console.log('[Cron Job] No stale bookings found.');
      return;
    }
    
    console.log(`[Cron Job] Found ${staleBookings.length} stale booking(s). Expiring them...`);
    
    for (const booking of staleBookings) {
      const fullRefund = Number(booking.total_price) + Number(booking.deposit_amount);
      
      const { error: updateError } = await supabase
        .from('bookings')
        .update({
          status: 'cancelled',
          cancelled_by: 'system',
          cancelled_at: new Date().toISOString(),
          cancellation_reason: 'Payment not completed in time',
          cancellation_fee: 0,
          refund_amount: fullRefund,
          updated_at: new Date().toISOString()
        })
        .eq('id', booking.id);
        
      if (updateError) {
        console.error(`[Cron Job] Error expiring booking ${booking.id}:`, updateError.message);
      } else {
        console.log(`[Cron Job] Successfully expired booking ${booking.id}`);
      }
    }
  } catch (err) {
    console.error('[Cron Job] Unexpected error in expirePendingBookings task:', err);
  }
}

/**
 * Starts the cron job.
 */
function initExpireBookingsCron() {
  // Runs every 10 minutes: '*/10 * * * *'
  cron.schedule('*/10 * * * *', expirePendingBookings);
  console.log('[Cron Job] Scheduled: Stale pending bookings cleanup job initialized.');
}

module.exports = {
  expirePendingBookings,
  initExpireBookingsCron
};
