const reviewService = require('./review.service');

class ReviewController {
  async submitReview(req, res, next) {
    try {
      const review = await reviewService.submitReview(req.user.id, req.body);
      res.status(201).json(review);
    } catch (error) {
      next(error);
    }
  }

  async getVehicleReviews(req, res, next) {
    try {
      const reviews = await reviewService.getVehicleReviews(req.params.vehicleId);
      res.json(reviews);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReviewController();
