// location.routes.js
const express = require('express');
const router = express.Router();
const locationController = require('./location.controller');
const { protect } = require('../../shared/middlewares/auth.middleware');

// Public location endpoints
router.get('/search', locationController.searchLocations);
router.get('/reverse-geocode', locationController.reverseGeocode);
router.get('/popular', locationController.getPopularLocations);

// Authenticated recent location endpoints
router.get('/recent', protect, locationController.getRecentLocations);
router.post('/recent', protect, locationController.saveRecentLocation);
router.delete('/recent/:id', protect, locationController.deleteRecentLocation);

module.exports = router;