// booking.controller.js
const bookingService = require('./booking.service');

const createBooking = async (req, res, next) => {
  try {
    const { vehicleId, startDate, endDate, totalPrice } = req.body;
    const booking = await bookingService.createBooking(req.user.id, { vehicleId, startDate, endDate, totalPrice });
    return res.status(201).json({
      success: true,
      message: 'Booking request created successfully. Pending owner confirmation.',
      data: booking
    });
  } catch (error) {
    next(error);
  }
};

const checkAvailability = async (req, res, next) => {
  try {
    const { vehicleId, startDate, endDate } = req.query;
    const availability = await bookingService.checkAvailability(vehicleId, startDate, endDate);
    return res.status(200).json({
      success: true,
      data: availability
    });
  } catch (error) {
    next(error);
  }
};

const getMyBookings = async (req, res, next) => {
  try {
    const bookings = await bookingService.getMyBookings(req.user.id);
    return res.status(200).json({
      success: true,
      data: bookings
    });
  } catch (error) {
    next(error);
  }
};

const getMyVehicleBookings = async (req, res, next) => {
  try {
    const bookings = await bookingService.getMyVehicleBookings(req.user.id);
    return res.status(200).json({
      success: true,
      data: bookings
    });
  } catch (error) {
    next(error);
  }
};

const getBookingById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const booking = await bookingService.getBookingById(id, req.user.id);
    return res.status(200).json({
      success: true,
      data: booking
    });
  } catch (error) {
    next(error);
  }
};

const confirmBooking = async (req, res, next) => {
  try {
    const { id } = req.params;
    const booking = await bookingService.confirmBooking(id, req.user.id);
    return res.status(200).json({
      success: true,
      message: 'Booking confirmed successfully',
      data: booking
    });
  } catch (error) {
    next(error);
  }
};

const startBooking = async (req, res, next) => {
  try {
    const { id } = req.params;
    const booking = await bookingService.startBooking(id, req.user.id);
    return res.status(200).json({
      success: true,
      message: 'Trip started successfully. Booking is now active.',
      data: booking
    });
  } catch (error) {
    next(error);
  }
};

const completeBooking = async (req, res, next) => {
  try {
    const { id } = req.params;
    const booking = await bookingService.completeBooking(id, req.user.id);
    return res.status(200).json({
      success: true,
      message: 'Trip completed successfully',
      data: booking
    });
  } catch (error) {
    next(error);
  }
};

const cancelBooking = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const booking = await bookingService.cancelBooking(id, req.user.id, reason);
    return res.status(200).json({
      success: true,
      message: 'Booking cancelled successfully',
      data: booking
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createBooking,
  checkAvailability,
  getMyBookings,
  getMyVehicleBookings,
  getBookingById,
  confirmBooking,
  startBooking,
  completeBooking,
  cancelBooking
};
