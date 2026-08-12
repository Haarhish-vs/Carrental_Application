// wishlist.routes.js
const express = require('express');
const router = express.Router();
const wishlistController = require('./wishlist.controller');
const { protect } = require('../../shared/middlewares/auth.middleware');

// All wishlist routes require authentication
router.use(protect);

// POST /api/wishlist/toggle -> Toggle vehicle in/out of wishlist
router.post('/toggle', wishlistController.toggleWishlist);

// GET /api/wishlist/ids -> Get list of wishlisted vehicle IDs
router.get('/ids', wishlistController.getWishlistIds);

// GET /api/wishlist -> Get all wishlisted vehicles with full details
router.get('/', wishlistController.getWishlist);

module.exports = router;
