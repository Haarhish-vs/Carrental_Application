// booking.routes.js
const express = require('express');
const router = express.Router();
const bookingController = require('./booking.controller');
const { protect } = require('../../shared/middlewares/auth.middleware');

// Public route for checking availability before starting a booking
router.get('/availability', bookingController.checkAvailability);

// Protected user-booking lists (MUST be defined before /:id)
router.get('/my-bookings', protect, bookingController.getMyBookings);
router.get('/my-vehicle-bookings', protect, bookingController.getMyVehicleBookings);

// Individual booking management (Protected)
router.post('/', protect, bookingController.createBooking);
router.get('/:id', protect, bookingController.getBookingById);
router.patch('/:id/confirm', protect, bookingController.confirmBooking);
router.patch('/:id/pay', protect, bookingController.confirmPayment);
router.patch('/:id/start', protect, bookingController.startBooking);
router.patch('/:id/complete', protect, bookingController.completeBooking);
router.patch('/:id/cancel', protect, bookingController.cancelBooking);
router.patch('/:id/location', protect, bookingController.updateBookingLocation);

module.exports = router;
