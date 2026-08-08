// pricing.service.js

class PricingService {
  /**
   * Safe calculation of the number of calendar days between two dates.
   * Treats dates as start-of-day inclusive (e.g., Aug 4 to Aug 4 is 1 day, Aug 4 to Aug 5 is 2 days).
   * @param {string|Date} startDate 
   * @param {string|Date} endDate 
   * @returns {number} Number of days
   */
  calculateDays(startDate, endDate) {
    const start = new Date(startDate);
    const end = new Date(endDate);

    const startUTC = Date.UTC(start.getFullYear(), start.getMonth(), start.getDate());
    const endUTC = Date.UTC(end.getFullYear(), end.getMonth(), end.getDate());

    const diffMs = endUTC - startUTC;
    if (diffMs < 0) {
      throw new Error('End date must be on or after start date');
    }

    const days = Math.floor(diffMs / (1000 * 60 * 60 * 24));
    return days < 1 ? 1 : days;
  }

  /**
   * Calculates total rental cost based on day thresholds.
   * @param {number} pricePerDay - Price per day
   * @param {number} depositAmount - Deposit amount (not discounted)
   * @param {string|Date} startDate - Start Date
   * @param {string|Date} endDate - End Date
   * @returns {object} Pricing breakdown: { days, basePrice, discountPercentage, discountedPrice, depositAmount, totalPrice }
   */
  calculatePricing(pricePerDay, depositAmount, startDate, endDate) {
    const days = this.calculateDays(startDate, endDate);
    const basePrice = pricePerDay * days;
    
    let discountPercentage = 0;
    if (days >= 30) {
      discountPercentage = 10;
    } else if (days >= 7) {
      discountPercentage = 5;
    }

    const discountAmount = (basePrice * discountPercentage) / 100;
    const discountedPrice = basePrice - discountAmount;
    
    // total_price refers to the rental fee after discounts
    // We keep total_price as the rental amount and track deposit separately, or sum them.
    // The database has fields total_price and deposit_amount.
    // The booking table has total_price as the rental amount (or final paid amount).
    // Let's store total_price = discountedPrice (rental amount) and deposit_amount = depositAmount separately,
    // so that total_price represents the primary cost of the car rent.
    return {
      days,
      basePrice: Math.round(basePrice * 100) / 100,
      discountPercentage,
      discountAmount: Math.round(discountAmount * 100) / 100,
      discountedPrice: Math.round(discountedPrice * 100) / 100,
      depositAmount: Math.round(depositAmount * 100) / 100,
      totalPrice: Math.round(discountedPrice * 100) / 100
    };
  }
}

module.exports = new PricingService();
