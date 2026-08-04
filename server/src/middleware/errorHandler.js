const { sendError } = require('../utils/response');
const { ApplicationError } = require('../utils/errors');

/**
 * Global Express Error Handling Middleware
 */
const errorHandler = (err, req, res, next) => {
  // Handle custom ApplicationErrors
  if (err instanceof ApplicationError) {
    return sendError(res, err.statusCode, err.message, err.errors);
  }

  // Handle Multer Errors
  if (err.name === 'MulterError') {
    return sendError(res, 400, `File upload error: ${err.message}`);
  }

  // Log other unexpected errors
  console.error('[Unhandled Error]:', err);

  const isProduction = process.env.NODE_ENV === 'production';
  return sendError(
    res,
    500,
    isProduction ? 'Internal Server Error' : err.message,
    isProduction ? [] : [err.stack]
  );
};

module.exports = errorHandler;
