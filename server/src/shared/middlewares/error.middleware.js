// error.middleware.js

const errorHandler = (err, req, res, next) => {
  // Log the error locally for debugging - suppress expected client/DB validation errors during tests
  if (process.env.NODE_ENV !== 'test' || err.statusCode === 500) {
    console.error('[Error Handler]:', err);
  }

  // Catch Postgres Exclude Constraint overlap error (23P01)
  if (err.code === '23P01' || (err.message && err.message.includes('overlapping_bookings'))) {
    return res.status(409).json({
      success: false,
      message: 'Double-booking conflict: This vehicle is already booked or has a pending request overlapping with your selected dates.'
    });
  }

  // Handle Supabase/Postgrest errors generally
  if (err.code && typeof err.code === 'string' && err.code.startsWith('23')) {
    // Integrity constraint violation
    return res.status(400).json({
      success: false,
      message: 'Database integrity violation: Invalid data relations or inputs.'
    });
  }

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal server error';

  res.status(statusCode).json({
    success: false,
    message: statusCode === 500 ? 'An unexpected internal error occurred.' : message
  });
};

module.exports = errorHandler;
