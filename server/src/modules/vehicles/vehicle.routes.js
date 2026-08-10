// vehicle.routes.js
const express = require('express');
const router = express.Router();
const vehicleController = require('./vehicle.controller');
const { protect } = require('../../shared/middlewares/auth.middleware');

// Public endpoints (no token check, but controller checks optionally for detail view)
router.get('/', vehicleController.getVehicles);

// Dynamic search & filter endpoints
router.get('/filter-options', vehicleController.getFilterOptions);
router.post('/search', vehicleController.searchVehicles);
router.get('/search', vehicleController.searchVehicles);

const upload = require('../../shared/middlewares/upload.middleware');

// Static / collection endpoints - MUST be defined before /:id parameter routes to prevent routing collision
router.get('/my-listings', protect, vehicleController.getMyListings);
router.post('/upload', protect, upload.array('files'), vehicleController.uploadMedia);
router.post('/upload-document', protect, upload.single('file'), vehicleController.uploadDocumentFile);
router.post('/', protect, vehicleController.createVehicle);

// Specific vehicle detail & sub-resource endpoints (parameterized by :id)
router.get('/:id', vehicleController.getVehicleById);
router.post('/:id/documents', protect, vehicleController.uploadDocument);
router.patch('/:id/availability', protect, vehicleController.toggleAvailability);
router.patch('/:id', protect, vehicleController.updateVehicle);
router.delete('/:id', protect, vehicleController.deleteVehicle);

// Admin simulator route (used by verification service tests/mock flow)
router.patch('/admin/:id/verify-document', vehicleController.verifyDocumentAdmin);

module.exports = router;
