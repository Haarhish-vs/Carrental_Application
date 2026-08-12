// wishlist.controller.js
const wishlistService = require('./wishlist.service');

class WishlistController {
  /**
   * POST /api/wishlist/toggle
   * Body: { vehicleId: string } or { vehicle_id: string }
   */
  async toggleWishlist(req, res, next) {
    try {
      const userId = req.user.id;
      const vehicleId = req.body.vehicleId || req.body.vehicle_id;

      if (!vehicleId) {
        return res.status(400).json({
          success: false,
          message: 'Vehicle ID (vehicleId) is required in request body'
        });
      }

      const result = await wishlistService.toggleWishlist(userId, vehicleId);

      return res.status(200).json({
        success: true,
        message: result.isWishlisted
          ? 'Vehicle added to wishlist successfully'
          : 'Vehicle removed from wishlist successfully',
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/wishlist
   * Returns complete populated vehicle objects in user's wishlist
   */
  async getWishlist(req, res, next) {
    try {
      const userId = req.user.id;
      const vehicles = await wishlistService.getUserWishlist(userId);

      return res.status(200).json({
        success: true,
        count: vehicles.length,
        data: vehicles
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/wishlist/ids
   * Returns array of vehicle IDs in user's wishlist
   */
  async getWishlistIds(req, res, next) {
    try {
      const userId = req.user.id;
      const ids = await wishlistService.getWishlistIds(userId);

      return res.status(200).json({
        success: true,
        data: ids
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new WishlistController();
