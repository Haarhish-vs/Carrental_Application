// booking.state-machine.js

const VALID_TRANSITIONS = {
  pending: ['confirmed', 'cancelled'],
  confirmed: ['active', 'cancelled'],
  active: ['completed'],
  completed: [],
  cancelled: []
};

/**
 * Validates if status transition is allowed.
 * @param {string} currentStatus - Current status
 * @param {string} targetStatus - Proposed status
 * @returns {boolean} True if transition is valid
 */
const isValidTransition = (currentStatus, targetStatus) => {
  const allowed = VALID_TRANSITIONS[currentStatus];
  return !!(allowed && allowed.includes(targetStatus));
};

module.exports = {
  isValidTransition,
  VALID_TRANSITIONS
};
