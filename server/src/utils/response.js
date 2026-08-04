/**
 * Standard utility for sending API responses
 */

/**
 * Sends a successful API response
 * @param {object} res Express response object
 * @param {number} statusCode HTTP status code (default: 200)
 * @param {string} message Description message
 * @param {object|array|null} data Response payload
 */
const sendSuccess = (res, statusCode = 200, message = 'Operation successful', data = {}) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data
  });
};

/**
 * Sends a failure API response
 * @param {object} res Express response object
 * @param {number} statusCode HTTP status code (default: 400)
 * @param {string} message Description message
 * @param {array} errors Detailed error information (e.g. validator fields)
 */
const sendError = (res, statusCode = 400, message = 'Operation failed', errors = []) => {
  return res.status(statusCode).json({
    success: false,
    message,
    errors
  });
};

module.exports = {
  sendSuccess,
  sendError
};
