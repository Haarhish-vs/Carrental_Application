const express = require('express');
const router = express.Router();
const reviewController = require('./review.controller');
const { protect: authenticate } = require('../../shared/middlewares/auth.middleware');

// GET /api/reviews/vehicle/:vehicleId
router.get('/vehicle/:vehicleId', reviewController.getVehicleReviews);

// POST /api/reviews
router.post('/', authenticate, reviewController.submitReview);

module.exports = router;
