const { body, param, validationResult } = require('express-validator');
const { sendError } = require('../../../utils/response');

/**
 * Common middleware to compile and send validation errors
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map(err => ({
      field: err.path || err.param,
      message: err.msg
    }));
    return sendError(res, 400, 'Validation failed', formattedErrors);
  }
  next();
};

/**
 * Validation rules for creating a car
 */
const validateCarCreation = [
  body('brand')
    .trim()
    .notEmpty().withMessage('Brand is required')
    .isString().withMessage('Brand must be a string'),
  
  body('model')
    .trim()
    .notEmpty().withMessage('Model is required')
    .isString().withMessage('Model must be a string'),
  
  body('variant')
    .optional()
    .trim()
    .isString().withMessage('Variant must be a string'),

  body('year')
    .notEmpty().withMessage('Year is required')
    .isInt({ min: 1886 }).withMessage('Year must be a valid integer')
    .custom((val) => {
      const currentYear = new Date().getFullYear();
      if (val > currentYear) {
        throw new Error(`Year must not exceed the current year (${currentYear})`);
      }
      return true;
    }),

  body('fuelType')
    .trim()
    .notEmpty().withMessage('Fuel Type is required')
    .isString().withMessage('Fuel Type must be a string'),

  body('transmission')
    .trim()
    .notEmpty().withMessage('Transmission is required')
    .isString().withMessage('Transmission must be a string'),

  body('mileage')
    .notEmpty().withMessage('Mileage is required')
    .isFloat({ min: 0 }).withMessage('Mileage cannot be negative'),

  body('engineCapacity')
    .notEmpty().withMessage('Engine Capacity is required')
    .isInt({ min: 1 }).withMessage('Engine Capacity must be greater than zero'),

  body('registrationNumber')
    .trim()
    .notEmpty().withMessage('Registration Number is required')
    .isString().withMessage('Registration Number must be a string'),

  validate
];

/**
 * Validation rules for updating a car
 */
const validateCarUpdate = [
  body('brand')
    .optional()
    .trim()
    .notEmpty().withMessage('Brand cannot be empty')
    .isString().withMessage('Brand must be a string'),
  
  body('model')
    .optional()
    .trim()
    .notEmpty().withMessage('Model cannot be empty')
    .isString().withMessage('Model must be a string'),
  
  body('variant')
    .optional()
    .trim()
    .isString().withMessage('Variant must be a string'),

  body('year')
    .optional()
    .isInt({ min: 1886 }).withMessage('Year must be a valid integer')
    .custom((val) => {
      const currentYear = new Date().getFullYear();
      if (val > currentYear) {
        throw new Error(`Year must not exceed the current year (${currentYear})`);
      }
      return true;
    }),

  body('fuelType')
    .optional()
    .trim()
    .notEmpty().withMessage('Fuel Type cannot be empty'),

  body('transmission')
    .optional()
    .trim()
    .notEmpty().withMessage('Transmission cannot be empty'),

  body('mileage')
    .optional()
    .isFloat({ min: 0 }).withMessage('Mileage cannot be negative'),

  body('engineCapacity')
    .optional()
    .isInt({ min: 1 }).withMessage('Engine Capacity must be greater than zero'),

  body('registrationNumber')
    .optional()
    .trim()
    .notEmpty().withMessage('Registration Number cannot be empty'),

  validate
];

/**
 * Validation rules for Location
 */
const validateLocation = [
  body('pickupAddress')
    .trim()
    .notEmpty().withMessage('Pickup Address is required'),

  body('city')
    .trim()
    .notEmpty().withMessage('City is required'),

  body('state')
    .trim()
    .notEmpty().withMessage('State is required'),

  body('pincode')
    .trim()
    .notEmpty().withMessage('Pincode is required')
    .isLength({ min: 3, max: 10 }).withMessage('Pincode must be between 3 and 10 characters'),

  body('latitude')
    .notEmpty().withMessage('Latitude is required')
    .isFloat({ min: -90, max: 90 }).withMessage('Latitude must be between -90 and 90'),

  body('longitude')
    .notEmpty().withMessage('Longitude is required')
    .isFloat({ min: -180, max: 180 }).withMessage('Longitude must be between -180 and 180'),

  validate
];

/**
 * Validation rules for Pricing
 */
const validatePricing = [
  body('pricePerDay')
    .notEmpty().withMessage('Price per day is required')
    .isFloat({ gt: 0 }).withMessage('Price must be greater than zero'),

  body('securityDeposit')
    .notEmpty().withMessage('Security deposit is required')
    .isFloat({ min: 0 }).withMessage('Security deposit cannot be negative'),

  body('minimumRentalDuration')
    .notEmpty().withMessage('Minimum rental duration is required')
    .isInt({ min: 1 }).withMessage('Minimum rental duration must be at least 1 day'),

  body('instantBooking')
    .optional()
    .isBoolean().withMessage('Instant booking must be a boolean value'),

  validate
];

/**
 * Validation rules for Availability
 */
const validateAvailability = [
  body('availableDates')
    .optional()
    .isArray().withMessage('Available dates must be an array of date strings'),

  body('blockedDates')
    .optional()
    .isArray().withMessage('Blocked dates must be an array of date strings'),

  validate
];

module.exports = {
  validateCarCreation,
  validateCarUpdate,
  validateLocation,
  validatePricing,
  validateAvailability
};
