// auth.middleware.js
const jwt = require('jsonwebtoken');
const env = require('../../config/env');
const { supabase } = require('../../config/supabase');

const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'Authentication token is required' });
    }

    const token = authHeader.split(' ')[1];
    if (token && token.includes('.')) {
      try {
        const decoded = jwt.verify(token, env.JWT_SECRET);
        const { data: user } = await supabase
          .from('users')
          .select('*')
          .eq('id', decoded.sub)
          .single();

        if (user) {
          req.user = user;
          return next();
        }
      } catch (_) {}
    }

    return res.status(401).json({ success: false, message: 'Invalid or expired authentication token' });
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Authentication failed' });
  }
};

module.exports = {
  protect
};
