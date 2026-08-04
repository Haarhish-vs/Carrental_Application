const VALID_TRANSITIONS = {
  pending: ['confirmed', 'cancelled'],
  confirmed: ['active', 'cancelled'],
  active: ['completed'],
  completed: [],
  cancelled: []
};

/**
 * Validates whether a state transition is allowed.
 * @param {string} currentStatus - Current status of the booking.
 * @param {string} nextStatus - Proposed status for the booking.
 * @returns {boolean} True if allowed, false otherwise.
 */
function isValidTransition(currentStatus, nextStatus) {
  const allowed = VALID_TRANSITIONS[currentStatus];
  if (!allowed) return false;
  return allowed.includes(nextStatus);
}

module.exports = {
  VALID_TRANSITIONS,
  isValidTransition
};
