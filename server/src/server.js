// server.js
const app = require('./app');
const env = require('./config/env');
const expirePendingBookingsCron = require('./modules/bookings/jobs/expire-pending-bookings.cron');
const { startTripReminderCron } = require('./services/trip-reminder.cron');

// Start background cron jobs
expirePendingBookingsCron.startCron();
startTripReminderCron();

const server = app.listen(env.PORT, () => {
  console.log(`===================================================`);
  console.log(`🚀 Rent-A-Car Server running in ${env.NODE_ENV} mode`);
  console.log(`📡 Listening at: http://localhost:${env.PORT}`);
  console.log(`===================================================`);
});

// Graceful shutdown handling
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});
