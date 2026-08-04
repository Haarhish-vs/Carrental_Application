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
    
    // Verify the JWT signed with the shared JWT secret
    let decoded;
    try {
      decoded = jwt.verify(token, env.JWT_SECRET);
    } catch (err) {
      return res.status(401).json({ success: false, message: 'Invalid or expired authentication token' });
    }

    // Retrieve user from the public.users database
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', decoded.sub)
      .single();

    if (error || !user) {
      return res.status(401).json({ success: false, message: 'User not registered or session invalid' });
    }

    // Attach user profile to req.user
    req.user = user;
    next();
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Authentication server error' });
  }
};

module.exports = {
  protect
};
