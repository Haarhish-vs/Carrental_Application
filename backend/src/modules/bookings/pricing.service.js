/**
 * Calculates pricing details for a booking.
 * @param {number} pricePerDay - The vehicle's daily rental rate.
 * @param {number} depositAmount - The vehicle's deposit amount.
 * @param {string} startDateStr - YYYY-MM-DD start date.
 * @param {string} endDateStr - YYYY-MM-DD end date.
 * @returns {object} Pricing breakdown: { dailyRate, numberOfDays, subtotal, discount, total, deposit }
 */
function calculatePricing(pricePerDay, depositAmount, startDateStr, endDateStr) {
  const rate = Number(pricePerDay);
  const deposit = Number(depositAmount);
  
  const start = new Date(startDateStr);
  const end = new Date(endDateStr);
  
  const utcStart = Date.UTC(start.getFullYear(), start.getMonth(), start.getDate());
  const utcEnd = Date.UTC(end.getFullYear(), end.getMonth(), end.getDate());
  
  const diffTime = utcEnd - utcStart;
  const numberOfDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
  
  if (numberOfDays <= 0) {
    throw new Error('End date must be after start date');
  }
  
  const subtotal = rate * numberOfDays;
  
  let discountPercentage = 0;
  if (numberOfDays >= 30) {
    discountPercentage = 0.10; // 10% discount for 30+ days
  } else if (numberOfDays >= 7) {
    discountPercentage = 0.05; // 5% discount for 7+ days
  }
  
  const discount = Number((subtotal * discountPercentage).toFixed(2));
  const total = Number((subtotal - discount).toFixed(2));
  
  return {
    dailyRate: rate,
    numberOfDays,
    subtotal: Number(subtotal.toFixed(2)),
    discount,
    total,
    deposit
  };
}

module.exports = {
  calculatePricing
};
