// vehicle.routes.js
const express = require('express');
const router = express.Router();
const vehicleController = require('./vehicle.controller');
const { protect } = require('../../shared/middlewares/auth.middleware');

// Public endpoints (no token check, but controller checks optionally for detail view)
router.get('/', vehicleController.getVehicles);

// Owner list (authenticated) - MUST be defined before /:id route to prevent collision
router.get('/my-listings', protect, vehicleController.getMyListings);

// Specific vehicle detail
router.get('/:id', vehicleController.getVehicleById);

// Owner/listing management
router.post('/', protect, vehicleController.createVehicle);
router.post('/:id/documents', protect, vehicleController.uploadDocument);
router.patch('/:id', protect, vehicleController.updateVehicle);
router.patch('/:id/availability', protect, vehicleController.toggleAvailability);
router.delete('/:id', protect, vehicleController.deleteVehicle);

// Admin simulator route (used by verification service tests/mock flow)
router.patch('/admin/:id/verify-document', vehicleController.verifyDocumentAdmin);

module.exports = router;
