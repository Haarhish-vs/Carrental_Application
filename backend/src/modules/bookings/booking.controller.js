const { createClient } = require('@supabase/supabase-js');
const bookingService = require('./booking.service');
const cancellationService = require('./cancellation.service');
const { createBookingSchema, availabilitySchema, cancelBookingSchema } = require('./booking.validation');

// Initialize the Supabase client
const supabaseUrl = process.env.SUPABASE_URL || 'https://placeholder.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'placeholder-key';
const supabase = createClient(supabaseUrl, supabaseKey);

// Helper function to handle controller errors cleanly
function handleError(res, error) {
  const status = error.status || 500;
  const message = error.message || 'An unexpected error occurred';
  
  return res.status(status).json({
    success: false,
    message
  });
}

const checkAvailability = async (req, res) => {
  try {
    const validated = availabilitySchema.parse({
      vehicleId: req.query.vehicleId,
      startDate: req.query.startDate,
      endDate: req.query.endDate
    });
    
    const isAvailable = await bookingService.checkVehicleAvailability(
      supabase,
      validated.vehicleId,
      validated.startDate,
      validated.endDate
    );
    
    return res.status(200).json({
      success: true,
      data: {
        vehicleId: validated.vehicleId,
        startDate: validated.startDate,
        endDate: validated.endDate,
        available: isAvailable
      }
    });
  } catch (err) {
    if (err.name === 'ZodError') {
      return res.status(400).json({
        success: false,
        message: err.errors[0].message
      });
    }
    return handleError(res, err);
  }
};

const createBooking = async (req, res) => {
  try {
    const validated = createBookingSchema.parse(req.body);
    const renterId = req.user.id;
    
    const booking = await bookingService.createBooking(supabase, renterId, validated);
    
    return res.status(201).json({
      success: true,
      data: booking
    });
  } catch (err) {
    if (err.name === 'ZodError') {
      return res.status(400).json({
        success: false,
        message: err.errors[0].message
      });
    }
    return handleError(res, err);
  }
};

const getMyBookings = async (req, res) => {
  try {
    const renterId = req.user.id;
    const bookings = await bookingService.getMyBookings(supabase, renterId);
    
    return res.status(200).json({
      success: true,
      data: bookings
    });
  } catch (err) {
    return handleError(res, err);
  }
};

const getMyVehicleBookings = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const bookings = await bookingService.getMyVehicleBookings(supabase, ownerId);
    
    return res.status(200).json({
      success: true,
      data: bookings
    });
  } catch (err) {
    return handleError(res, err);
  }
};

const getBookingDetails = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const userId = req.user.id;
    
    const booking = await bookingService.getBookingDetails(supabase, bookingId, userId);
    
    return res.status(200).json({
      success: true,
      data: booking
    });
  } catch (err) {
    return handleError(res, err);
  }
};

const confirmBooking = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const ownerId = req.user.id;
    
    const booking = await bookingService.confirmBooking(supabase, bookingId, ownerId);
    
    return res.status(200).json({
      success: true,
      data: booking
    });
  } catch (err) {
    return handleError(res, err);
  }
};

const startTrip = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const userId = req.user.id;
    
    const booking = await bookingService.startTrip(supabase, bookingId, userId);
    
    return res.status(200).json({
      success: true,
      data: booking
    });
  } catch (err) {
    return handleError(res, err);
  }
};

const completeBooking = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const userId = req.user.id;
    
    const booking = await bookingService.completeBooking(supabase, bookingId, userId);
    
    return res.status(200).json({
      success: true,
      data: booking
    });
  } catch (err) {
    return handleError(res, err);
  }
};

const cancelBooking = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const userId = req.user.id;
    const validated = cancelBookingSchema.parse(req.body);
    
    const booking = await cancellationService.cancelBookingWorkflow(
      supabase,
      bookingId,
      userId,
      validated.reason
    );
    
    return res.status(200).json({
      success: true,
      data: {
        booking,
        refund_amount: booking.refund_amount
      }
    });
  } catch (err) {
    if (err.name === 'ZodError') {
      return res.status(400).json({
        success: false,
        message: err.errors[0].message
      });
    }
    return handleError(res, err);
  }
};

module.exports = {
  checkAvailability,
  createBooking,
  getMyBookings,
  getMyVehicleBookings,
  getBookingDetails,
  confirmBooking,
  startTrip,
  completeBooking,
  cancelBooking
};
