// rateLimiter.js
const rateLimits = new Map();

/**
 * Basic in-memory rate limiter middleware.
 * @param {object} options - Configuration options
 * @param {number} options.windowMs - Time window in milliseconds
 * @param {number} options.max - Max number of requests allowed in the window
 * @param {string} options.message - Error message to return when limit exceeded
 */
const rateLimiter = (options) => {
  const windowMs = options.windowMs || 15 * 60 * 1000; // 15 mins default
  const max = options.max || 100;
  const message = options.message || 'Too many requests, please try again later.';

  return (req, res, next) => {
    const ip = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const now = Date.now();

    if (!rateLimits.has(ip)) {
      rateLimits.set(ip, []);
    }

    const requests = rateLimits.get(ip);
    
    // Filter out requests outside the time window
    const activeRequests = requests.filter(timestamp => now - timestamp < windowMs);
    
    if (activeRequests.length >= max) {
      return res.status(429).json({
        success: false,
        message
      });
    }

    // Record the current request timestamp
    activeRequests.push(now);
    rateLimits.set(ip, activeRequests);

    next();
  };
};

module.exports = rateLimiter;
