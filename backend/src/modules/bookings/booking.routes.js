const express = require('express');
const router = express.Router();
const bookingController = require('./booking.controller');
const authMiddleware = require('../../middleware/auth.middleware');

// Apply auth middleware to all booking routes
router.use(authMiddleware);

// POST /api/bookings - create a new booking
router.post('/', bookingController.createBooking);

// GET /api/bookings/availability - check date availability (query: vehicleId, startDate, endDate)
router.get('/availability', bookingController.checkAvailability);

// GET /api/bookings/my-bookings - bookings where current user is renter
router.get('/my-bookings', bookingController.getMyBookings);

// GET /api/bookings/my-vehicle-bookings - bookings for vehicles owned by current user
router.get('/my-vehicle-bookings', bookingController.getMyVehicleBookings);

// GET /api/bookings/:id - single booking detail (renter or owner view)
router.get('/:id', bookingController.getBookingDetails);

// PATCH /api/bookings/:id/confirm - owner confirms a pending booking
router.patch('/:id/confirm', bookingController.confirmBooking);

// PATCH /api/bookings/:id/start - mark trip active (on pickup/handover)
router.patch('/:id/start', bookingController.startTrip);

// PATCH /api/bookings/:id/complete - mark trip completed (on return)
router.patch('/:id/complete', bookingController.completeBooking);

// PATCH /api/bookings/:id/cancel - cancel booking (body: { reason })
router.patch('/:id/cancel', bookingController.cancelBooking);

module.exports = router;
