const express = require('express');
const cors = require('cors');
require('dotenv').config();

const bookingRoutes = require('./modules/bookings/booking.routes');
const { initExpireBookingsCron } = require('./modules/bookings/jobs/expire-pending-bookings.cron');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/bookings', bookingRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ success: true, message: 'Booking service is healthy' });
});

// Global 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Endpoint not found' });
});

// Start Cron Jobs (unless in test mode)
if (process.env.NODE_ENV !== 'test') {
  initExpireBookingsCron();
}

module.exports = app;
