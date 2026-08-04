const carService = require('../services/carService');
const { sendSuccess } = require('../../../utils/response');

/**
 * Helper to wrap async controller methods and catch errors
 */
const catchAsync = (fn) => (req, res, next) => {
  fn(req, res, next).catch(next);
};

class CarController {
  /**
   * Helper to retrieve ownerId from headers
   */
  _getOwnerId(req) {
    // Falls back to a default static UUID if not provided in headers
    return req.headers['x-owner-id'] || '11111111-1111-1111-1111-111111111111';
  }

  /**
   * Create a new car in draft state
   */
  createCar = catchAsync(async (req, res) => {
    const ownerId = this._getOwnerId(req);
    const car = await carService.createCar(req.body, ownerId);
    return sendSuccess(res, 201, 'Car draft created successfully', car);
  });

  /**
   * Get all cars
   */
  getCars = catchAsync(async (req, res) => {
    const filters = {
      status: req.query.status,
      brand: req.query.brand,
      owner_id: req.query.ownerId
    };
    const cars = await carService.getCars(filters);
    return sendSuccess(res, 200, 'Cars retrieved successfully', cars);
  });

  /**
   * Get car details by ID
   */
  getCarById = catchAsync(async (req, res) => {
    const { id } = req.params;
    const car = await carService.getCarById(id);
    return sendSuccess(res, 200, 'Car details retrieved successfully', car);
  });

  /**
   * Update car details
   */
  updateCar = catchAsync(async (req, res) => {
    const { id } = req.params;
    const car = await carService.updateCar(id, req.body);
    return sendSuccess(res, 200, 'Car details updated successfully', car);
  });

  /**
   * Delete a draft car
   */
  deleteCar = catchAsync(async (req, res) => {
    const { id } = req.params;
    const result = await carService.deleteCar(id);
    return sendSuccess(res, 200, result.message, { id: result.id });
  });

  /**
   * Upload multiple images for a car
   */
  uploadImages = catchAsync(async (req, res) => {
    const { id } = req.params;
    // req.files is populated by multer
    const files = req.files || [];
    
    if (files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No image files uploaded',
        errors: []
      });
    }

    const images = await carService.addImages(id, files);
    return sendSuccess(res, 201, 'Images uploaded successfully', images);
  });

  /**
   * Get all images of a car
   */
  getImages = catchAsync(async (req, res) => {
    const { id } = req.params;
    const images = await carService.getImages(id);
    return sendSuccess(res, 200, 'Car images retrieved successfully', images);
  });

  /**
   * Delete a specific image of a car
   */
  deleteImage = catchAsync(async (req, res) => {
    const { id, imageId } = req.params;
    const result = await carService.deleteImage(id, imageId);
    return sendSuccess(res, 200, result.message, { id: result.id });
  });

  /**
   * Save pickup location details
   */
  saveLocation = catchAsync(async (req, res) => {
    const { id } = req.params;
    const location = await carService.saveLocation(id, req.body);
    return sendSuccess(res, 200, 'Pickup location saved successfully', location);
  });

  /**
   * Get pickup location details
   */
  getLocation = catchAsync(async (req, res) => {
    const { id } = req.params;
    const location = await carService.getLocation(id);
    return sendSuccess(res, 200, 'Pickup location retrieved successfully', location);
  });

  /**
   * Save pricing details
   */
  savePricing = catchAsync(async (req, res) => {
    const { id } = req.params;
    const pricing = await carService.savePricing(id, req.body);
    return sendSuccess(res, 200, 'Pricing details saved successfully', pricing);
  });

  /**
   * Get pricing details
   */
  getPricing = catchAsync(async (req, res) => {
    const { id } = req.params;
    const pricing = await carService.getPricing(id);
    return sendSuccess(res, 200, 'Pricing details retrieved successfully', pricing);
  });

  /**
   * Save availability dates
   */
  saveAvailability = catchAsync(async (req, res) => {
    const { id } = req.params;
    const availability = await carService.saveAvailability(id, req.body);
    return sendSuccess(res, 200, 'Availability saved successfully', availability);
  });

  /**
   * Get availability details
   */
  getAvailability = catchAsync(async (req, res) => {
    const { id } = req.params;
    const availability = await carService.getAvailability(id);
    return sendSuccess(res, 200, 'Availability details retrieved successfully', availability);
  });

  /**
   * Upload and save documents (RC, Insurance, Fitness, PUC)
   */
  saveDocuments = catchAsync(async (req, res) => {
    const { id } = req.params;
    const files = req.files || {};
    
    if (Object.keys(files).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No document files uploaded',
        errors: []
      });
    }

    const documents = await carService.saveDocuments(id, files);
    return sendSuccess(res, 200, 'Documents saved successfully', documents);
  });

  /**
   * Get document URLs
   */
  getDocuments = catchAsync(async (req, res) => {
    const { id } = req.params;
    const documents = await carService.getDocuments(id);
    return sendSuccess(res, 200, 'Documents retrieved successfully', documents);
  });

  /**
   * Submit car for verification
   */
  submitCar = catchAsync(async (req, res) => {
    const { id } = req.params;
    const car = await carService.submitCar(id);
    return sendSuccess(res, 200, 'Car submitted for verification successfully', car);
  });
}

module.exports = new CarController();
