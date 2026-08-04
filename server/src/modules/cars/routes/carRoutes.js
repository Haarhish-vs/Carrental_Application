const express = require('express');
const carController = require('../controllers/carController');
const { uploadImages, uploadDocuments } = require('../../../middleware/multer');
const {
  validateCarCreation,
  validateCarUpdate,
  validateLocation,
  validatePricing,
  validateAvailability
} = require('../validators/carValidator');

const router = express.Router();

// Basic car operations
router.post('/', validateCarCreation, carController.createCar);
router.get('/', carController.getCars);
router.get('/:id', carController.getCarById);
router.put('/:id', validateCarUpdate, carController.updateCar);
router.delete('/:id', carController.deleteCar);

// Car images operations
// Use uploadImages.any() to dynamically capture front, back, interior, etc. file fields
router.post('/:id/images', uploadImages.any(), carController.uploadImages);
router.get('/:id/images', carController.getImages);
router.delete('/:id/images/:imageId', carController.deleteImage);

// Pickup location operations
router.post('/:id/location', validateLocation, carController.saveLocation);
router.put('/:id/location', validateLocation, carController.saveLocation);
router.get('/:id/location', carController.getLocation);

// Pricing operations
router.post('/:id/pricing', validatePricing, carController.savePricing);
router.put('/:id/pricing', validatePricing, carController.savePricing);
router.get('/:id/pricing', carController.getPricing);

// Availability operations
router.post('/:id/availability', validateAvailability, carController.saveAvailability);
router.put('/:id/availability', validateAvailability, carController.saveAvailability);
router.get('/:id/availability', carController.getAvailability);

// Documents operations
router.post(
  '/:id/documents',
  uploadDocuments.fields([
    { name: 'rc', maxCount: 1 },
    { name: 'insurance', maxCount: 1 },
    { name: 'fitness', maxCount: 1 },
    { name: 'puc', maxCount: 1 }
  ]),
  carController.saveDocuments
);
router.get('/:id/documents', carController.getDocuments);

// Submission operation
router.post('/:id/submit', carController.submitCar);

module.exports = router;
