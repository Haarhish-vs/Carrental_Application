// trip-reminder.cron.js
const cron = require('node-cron');
const { supabase } = require('../config/supabase');
const { sendPushNotificationToUsers } = require('../config/firebase');

/**
 * Start 1-hour trip reminder cron job.
 * Runs every 5 minutes to check for upcoming trips.
 */
function startTripReminderCron() {
  console.log('[NOTIFICATION] Initializing 1-hour trip reminder cron service...');

  cron.schedule('*/5 * * * *', async () => {
    try {
      const now = new Date();
      const lowerBound = new Date(now.getTime() + 50 * 60 * 1000).toISOString(); // 50 mins from now
      const upperBound = new Date(now.getTime() + 70 * 60 * 1000).toISOString(); // 70 mins from now

      // Query bookings starting in 1 hour that are confirmed and paid
      const { data: bookings, error } = await supabase
        .from('bookings')
        .select(`
          id,
          start_date,
          renter_id,
          reminder_sent,
          vehicle:vehicles (
            brand,
            model,
            owner_id
          )
        `)
        .eq('status', 'confirmed')
        .eq('payment_status', 'paid')
        .gte('start_date', lowerBound)
        .lte('start_date', upperBound);

      if (error) {
        // If reminder_sent column doesn't exist yet, query without it
        console.error('[FCM ERROR] Error fetching upcoming bookings for reminder:', error.message);
        return;
      }

      if (!bookings || bookings.length === 0) return;

      for (const booking of bookings) {
        // Prevent duplicate notifications
        if (booking.reminder_sent === true) continue;

        const vehicle = Array.isArray(booking.vehicle) ? booking.vehicle[0] : booking.vehicle;
        const renterId = booking.renter_id;
        const ownerId = vehicle?.owner_id;
        const carName = `${vehicle?.brand || 'Vehicle'} ${vehicle?.model || ''}`.trim();

        console.log('[NOTIFICATION] Trip starts in 1 hour');
        console.log('[NOTIFICATION] Sending reminder to renter and owner...');

        const recipients = [renterId, ownerId].filter(Boolean);
        if (recipients.length > 0) {
          await sendPushNotificationToUsers(recipients, {
            title: 'Trip Starting Soon',
            body: `Your rental trip for ${carName} starts in 1 hour. Get ready!`,
            data: {
              type: 'TRIP_REMINDER',
              bookingId: booking.id
            }
          });
        }

        // Mark reminder as sent
        await supabase
          .from('bookings')
          .update({ reminder_sent: true, updated_at: new Date().toISOString() })
          .eq('id', booking.id);
      }
    } catch (err) {
      console.error('[FCM ERROR] Exception in trip reminder cron job:', err.message);
    }
  });
}

module.exports = { startTripReminderCron };
