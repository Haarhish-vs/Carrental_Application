// car-compat.routes.js
const express = require('express');
const router = express.Router();
const vehicleController = require('./vehicle.controller');

// Compatibility routes for /api/cars endpoints
router.get('/search', vehicleController.getVehicles);
router.get('/filter-options', vehicleController.getFilterOptions);

module.exports = router;
